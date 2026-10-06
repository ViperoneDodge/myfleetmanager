import 'dart:io';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

class RegistrationData {
  String? plate;
  DateTime? registrationDate;
  String? vin;
  String? powerKw;
  String? engineCc;

  bool get isEmpty =>
      plate == null &&
      registrationDate == null &&
      vin == null &&
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

  static String _num(String s) =>
      s.replaceAll(',', '.').replaceAll(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'^0+(?=\d)'), '');

  static final RegExp _label = RegExp(r'\(\s*([A-Z0-9])\s*(?:[.,]\s*(\d+)\s*)*\)');

  static String? _code(RegExpMatch m) {
    final letter = m.group(1)! == '8' ? 'B' : m.group(1)!;
    final full = m.group(0)!.replaceAll(RegExp(r'[\s()]'), '').replaceAll(',', '.');
    if (letter == 'P' && (full == 'P.1' || full == 'P1')) return 'P.1';
    if (letter == 'P' && (full == 'P.2' || full == 'P2')) return 'P.2';
    if (full == letter || (letter == 'B' && full == '8')) return letter;
    return null;
  }

  static Map<String, List<String>> labelValues(String text) {
    final out = <String, List<String>>{};
    for (final line in text.toUpperCase().split('\n')) {
      final labels = _label.allMatches(line).toList();
      for (var i = 0; i < labels.length; i++) {
        final code = _code(labels[i]);
        if (code == null) continue;
        final stop = i + 1 < labels.length ? labels[i + 1].start : line.length;
        final value = line.substring(labels[i].end, stop).trim().split(RegExp(r'\s{2,}')).first.trim();
        if (value.isNotEmpty) out.putIfAbsent(code, () => []).add(value);
      }
    }
    return out;
  }

  static RegistrationData parse(String raw) {
    final values = labelValues(raw.replaceAll('\r', ''));
    final data = RegistrationData();

    for (final v in values['A'] ?? const <String>[]) {
      final p = v.replaceAll(RegExp(r'[\s\-.]'), '');
      if (RegExp(r'^[A-Z0-9]{4,10}$').hasMatch(p) && RegExp(r'\d').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) {
        data.plate = p;
        break;
      }
    }

    for (final v in values['B'] ?? const <String>[]) {
      final m = _date.firstMatch(v);
      final d = m == null ? null : _toDate(m);
      if (d != null) {
        data.registrationDate = d;
        break;
      }
    }

    for (final v in values['E'] ?? const <String>[]) {
      final c = _vinFix(v.replaceAll(RegExp(r'[^A-Z0-9]'), ''));
      if (c.length >= 17 && RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(c.substring(0, 17)) && RegExp(r'\d').hasMatch(c.substring(0, 17))) {
        data.vin = c.substring(0, 17);
        break;
      }
    }

    for (final v in values['P.1'] ?? const <String>[]) {
      final m = RegExp(r'^(\d{2,5})(?:[.,]\d+)?').firstMatch(v);
      if (m != null) {
        data.engineCc = _num(m.group(1)!);
        break;
      }
    }

    for (final v in values['P.2'] ?? const <String>[]) {
      final m = RegExp(r'^(\d{1,4}(?:[.,]\d+)?)').firstMatch(v);
      if (m != null) {
        data.powerKw = _num(m.group(1)!);
        break;
      }
    }

    return data;
  }
}
