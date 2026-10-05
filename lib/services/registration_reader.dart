import 'dart:io';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

class RegistrationData {
  String? plate;
  DateTime? registrationDate;
  String? vin;
  String? tyres;
  String? powerKw;
  String? engineCc;

  bool get isEmpty =>
      plate == null &&
      registrationDate == null &&
      vin == null &&
      tyres == null &&
      powerKw == null &&
      engineCc == null;
}

class RegistrationReader {
  static Future<String> readText(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final temp = <File>[];
    try {
      final images = <String>[];
      if (path.toLowerCase().endsWith('.pdf')) {
        final bytes = await File(path).readAsBytes();
        var i = 0;
        await for (final page in Printing.raster(bytes, pages: const [0, 1], dpi: 220)) {
          final f = File('${Directory.systemTemp.path}/ocr_${DateTime.now().millisecondsSinceEpoch}_$i.png');
          await f.writeAsBytes(await page.toPng());
          temp.add(f);
          images.add(f.path);
          i++;
        }
      } else {
        images.add(path);
      }
      final out = StringBuffer();
      for (final p in images) {
        final r = await recognizer.processImage(InputImage.fromFilePath(p));
        out.writeln(layoutLines([
          for (final b in r.blocks)
            for (final l in b.lines) (text: l.text, box: l.boundingBox),
        ]));
      }
      return out.toString();
    } finally {
      await recognizer.close();
      for (final f in temp) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  static String layoutLines(List<({String text, Rect box})> lines) {
    final sorted = lines.where((l) => l.text.trim().isNotEmpty).toList()
      ..sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));
    final rows = <List<({String text, Rect box})>>[];
    var rowCy = 0.0;
    var rowH = 0.0;
    for (final l in sorted) {
      final h = l.box.height;
      if (rows.isNotEmpty && (l.box.center.dy - rowCy).abs() <= 0.5 * (h > rowH ? h : rowH)) {
        final row = rows.last..add(l);
        rowCy = row.map((e) => e.box.center.dy).reduce((a, b) => a + b) / row.length;
        rowH = row.map((e) => e.box.height).reduce((a, b) => a > b ? a : b);
      } else {
        rows.add([l]);
        rowCy = l.box.center.dy;
        rowH = h;
      }
    }
    return rows
        .map((r) => (r..sort((a, b) => a.box.left.compareTo(b.box.left))).map((e) => e.text.trim()).join('   '))
        .join('\n');
  }

  static final RegExp _date = RegExp(r'(\d{1,2})\s?[/.\-]\s?(\d{1,2})\s?[/.\-]\s?(\d{4}|\d{2})\b');

  static DateTime? _toDate(RegExpMatch m) {
    final d = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    var y = int.tryParse(m.group(3)!);
    if (d == null || mo == null || y == null) return null;
    if (y < 100) y += y > (DateTime.now().year % 100) ? 1900 : 2000;
    if (d < 1 || d > 31 || mo < 1 || mo > 12 || y < 1900) return null;
    final dt = DateTime(y, mo, d);
    if (dt.month != mo || dt.isAfter(DateTime.now())) return null;
    return dt;
  }

  static String _vinFix(String s) => s.replaceAll('O', '0').replaceAll('Q', '0').replaceAll('I', '1');

  static bool _vinOk(String s) =>
      s.length == 17 &&
      RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(s) &&
      RegExp(r'\d').allMatches(s).length >= 4 &&
      RegExp(r'[A-Z]').allMatches(s).length >= 2 &&
      RegExp(r'\d{4}$').hasMatch(s);

  static String? _vinFrom(String raw) {
    if (raw.length != 17 || RegExp(r'\d').allMatches(raw).length < 3) return null;
    final v = _vinFix(raw);
    return _vinOk(v) ? v : null;
  }

  static String _num(String s) =>
      s.replaceAll(',', '.').replaceAll(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'^0+(?=\d)'), '');

  static RegistrationData parse(String raw) {
    final text = raw.toUpperCase().replaceAll('\r', '');
    final flat = text.replaceAll('\n', ' ');
    final data = RegistrationData();

    final plateRe = RegExp(r'\b([A-HJ-NPR-TV-Z]{2})\s?(\d{3})\s?([A-HJ-NPR-TV-Z]{2})\b');
    final motoRe = RegExp(r'\b([A-HJ-NPR-TV-Z]{2})\s?(\d{5})\b');
    String? plateFrom(String s) {
      final m = plateRe.firstMatch(s);
      final mm = motoRe.firstMatch(s);
      if (m != null && (mm == null || m.start <= mm.start)) return '${m.group(1)}${m.group(2)}${m.group(3)}';
      if (mm != null) return '${mm.group(1)}${mm.group(2)}';
      return null;
    }

    for (final a in RegExp(r'(?:^|[\s(])A\s?[.)]\s*[:\-]?\s*([A-Z0-9 ]{5,10})').allMatches(flat)) {
      data.plate = plateFrom(a.group(1)!);
      if (data.plate != null) break;
    }
    data.plate ??= plateFrom(flat);

    final bLabel = RegExp(r'(?:^|[\s(])B\s?[.)]?\s*[:\-]?\s*' + _date.pattern).firstMatch(flat);
    if (bLabel != null) {
      final m = _date.firstMatch(flat.substring(bLabel.start));
      if (m != null) data.registrationDate = _toDate(m);
    }
    if (data.registrationDate == null) {
      DateTime? best;
      for (final m in _date.allMatches(flat)) {
        final before = flat.substring(m.start < 20 ? 0 : m.start - 20, m.start);
        if (RegExp(r'NAT[OA]|NASC').hasMatch(before)) continue;
        final d = _toDate(m);
        if (d != null && d.year >= 1950 && (best == null || d.isBefore(best))) best = d;
      }
      data.registrationDate = best;
    }

    final eLabel = RegExp(r'(?:^|[\s(])E\s?[.)]?\s*[:\-]?\s*([A-Z0-9][A-Z0-9 ]{16,22})').firstMatch(flat);
    final eVin = eLabel == null ? '' : eLabel.group(1)!.replaceAll(' ', '');
    if (eVin.length >= 17) data.vin = _vinFrom(eVin.substring(0, 17));
    if (data.vin == null) {
      final tokens = RegExp(r'[A-Z0-9]+').allMatches(flat).map((m) => m.group(0)!).toList();
      for (var i = 0; i < tokens.length && data.vin == null; i++) {
        var joined = '';
        for (var k = i; k < tokens.length && k < i + 3; k++) {
          joined += tokens[k];
          if (joined.length > 17) break;
          if (joined.length == 17) {
            data.vin = _vinFrom(joined);
            break;
          }
        }
      }
    }

    final tyreRe = RegExp(
        r'\b(\d{3})\s?/\s?(\d{2})\s?(Z?R)\s?F?\s?(\d{2})(C)?(?:\s?M\s?/\s?C)?(?:\s*(\d{2,3}(?:/\d{2,3})?)\s?([A-Z]))?');
    final tyres = <String>[];
    for (final m in tyreRe.allMatches(flat)) {
      var t = '${m.group(1)}/${m.group(2)} ${m.group(3)}${m.group(4)}${m.group(5) ?? ''}';
      if (m.group(6) != null) t += ' ${m.group(6)}${m.group(7)}';
      if (!tyres.contains(t)) tyres.add(t);
    }
    if (tyres.isNotEmpty) data.tyres = tyres.join('; ');

    final p2 = RegExp(r'P\s?\.?\s?2\s?\)?\s*[:\-]?\s*(\d{2,3}(?:[.,]\d{1,2})?)').firstMatch(flat) ??
        RegExp(r'\b(\d{2,3}(?:[.,]\d{1,2})?)\s?KW\b').firstMatch(flat) ??
        RegExp(r'\bKW\s*[:\-]?\s*(\d{2,3}(?:[.,]\d{1,2})?)').firstMatch(flat);
    if (p2 != null) data.powerKw = _num(p2.group(1)!);

    final p1 = RegExp(r'P\s?\.?\s?1\s?\)?\s*[:\-]?\s*(\d{2,4})\b').firstMatch(flat) ??
        RegExp(r'\b(\d{3,4})\s?(?:CM3|CM³|CC)\b').firstMatch(flat);
    if (p1 != null) data.engineCc = p1.group(1);

    return data;
  }
}
