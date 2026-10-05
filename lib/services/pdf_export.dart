import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n.dart';
import '../models.dart';
import '../widgets/common.dart';

class PdfExport {
  static Future<pw.Font> _asset(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));

  static Future<pw.ThemeData> _theme() async {
    final fallback = <pw.Font>[
      await _asset('NotoSansDevanagari-Regular.ttf'),
      await _asset('NotoSansThai-Regular.ttf'),
    ];
    try {
      switch (L10n.code) {
        case 'zh':
          fallback.insert(0, await PdfGoogleFonts.notoSansSCRegular());
          break;
        case 'ja':
          fallback.insert(0, await PdfGoogleFonts.notoSansJPRegular());
          break;
        case 'ko':
          fallback.insert(0, await PdfGoogleFonts.notoSansKRRegular());
          break;
      }
    } catch (_) {}
    return pw.ThemeData.withFont(
      base: await _asset('NotoSans-Regular.ttf'),
      bold: await _asset('NotoSans-Bold.ttf'),
      fontFallback: fallback,
    );
  }

  static PdfColor _color(int argb) => PdfColor.fromInt(argb);

  static Future<pw.ImageProvider?> _image(Vehicle v) async {
    final bytes = v.photoBytes;
    if (bytes != null) return pw.MemoryImage(bytes);
    try {
      final data = await rootBundle.load('assets/vehicles/${v.type.name}.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _fileName(String title) {
    final safe = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final day = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'MyFleetManager${safe.isEmpty ? '' : '-$safe'}-$day.pdf';
  }

  static Future<void> share({required String title, required List<Vehicle> vehicles}) async {
    final bytes = await build(title: title, vehicles: vehicles);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(title));
  }

  static const double _pageHeight = 842 - 32 - 32 - 24;

  static int _lines(String text, int perLine) => text.isEmpty ? 1 : (text.length / perLine).ceil();

  static double _estimate(Vehicle v) {
    final deadlines = v.activeDeadlines.length;
    final top = 24 + (deadlines * 15.0 > 92 ? deadlines * 15.0 : 92);
    var table = 24.0;
    final records = v.maintenance;
    if (records.isEmpty) {
      table += 14;
    } else {
      table += 16;
      for (final r in records) {
        final itemsText = r.items.map(maintenanceItemLabel).join(', ');
        final l = [_lines(itemsText, 34), _lines(r.notes, 34)].reduce((a, b) => a > b ? a : b);
        table += 5 + 11.5 * l;
      }
    }
    return top + table + 20;
  }

  static Future<Uint8List> build({required String title, required List<Vehicle> vehicles}) async {
    try {
      return await _build(title, vehicles, flowAll: false);
    } catch (_) {
      return _build(title, vehicles, flowAll: true);
    }
  }

  static Future<Uint8List> _build(String title, List<Vehicle> vehicles, {required bool flowAll}) async {
    final theme = await _theme();
    final images = <String, pw.ImageProvider?>{};
    for (final v in vehicles) {
      images[v.id] = await _image(v);
    }
    final doc = pw.Document(title: title, creator: 'MyFleetManager', theme: theme);
    const accent = PdfColor.fromInt(0xFF1E4F8C);
    final grey = PdfColors.grey700;

    final body = <pw.Widget>[
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('MyFleetManager', style: pw.TextStyle(fontSize: 10, color: grey)),
            pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
          ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(tr('pdf.generated', {'date': fmtDate(DateTime.now())}), style: const pw.TextStyle(fontSize: 10)),
          pw.Text(trn('family.vehicles', vehicles.length), style: const pw.TextStyle(fontSize: 10)),
        ]),
      ]),
      pw.Container(height: 2, color: accent, margin: const pw.EdgeInsets.only(top: 6, bottom: 4)),
    ];

    for (final v in vehicles) {
      final parts = _vehicle(v, images[v.id], accent, grey);
      if (flowAll) {
        body.addAll(parts);
      } else if (_estimate(v) > _pageHeight - 40) {
        body.add(pw.NewPage());
        body.addAll(parts);
      } else {
        body.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: parts)),
        ]));
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text('$title · ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: grey)),
      ),
      build: (ctx) => body,
    ));
    return doc.save();
  }

  static List<pw.Widget> _vehicle(Vehicle v, pw.ImageProvider? image, PdfColor accent, PdfColor grey) {
    final name = v.name.isEmpty ? (v.plate.isEmpty ? tr('vehicle.generic') : v.plate) : v.name;
    pw.Widget info(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(color: grey, fontSize: 8.5)),
              pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9.5)),
            ]),
          ),
        );

    final left = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        width: 104,
        height: 66,
        padding: v.photoBytes == null ? const pw.EdgeInsets.all(8) : null,
        decoration: pw.BoxDecoration(
          color: v.photoBytes == null ? PdfColors.blueGrey400 : PdfColors.grey200,
        ),
        child: image == null
            ? null
            : pw.Image(image, fit: v.photoBytes != null ? pw.BoxFit.cover : pw.BoxFit.contain),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(name,
              maxLines: 2,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent)),
          info(tr('edit.type'), vehicleTypeLabel(v.type)),
          info(tr('edit.plate'), v.plate.isEmpty ? '—' : v.plate),
          info(tr('vehicle.regDate'), fmtDate(v.registrationDate)),
        ]),
      ),
    ]);

    final deadlines = v.activeDeadlines;
    final right = pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(tr('tab.deadlines'), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      if (deadlines.isEmpty) pw.Text(tr('vehicle.noTracked'), style: pw.TextStyle(fontSize: 9, color: grey)),
      ...deadlines.map((d) {
        final s = dueStatus(d.dueDate!);
        final c = _color(s.color.toARGB32());
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(children: [
            pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: c, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 5),
            pw.Expanded(child: pw.Text(d.dueLabel, maxLines: 1, style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(width: 48, child: pw.Text(fmtDate(d.dueDate), style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(
              width: 92,
              child: pw.Text(s.text, textAlign: pw.TextAlign.right, maxLines: 1, style: pw.TextStyle(fontSize: 8.5, color: c)),
            ),
          ]),
        );
      }),
    ]);

    final top = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(flex: 9, child: left),
        pw.Container(
          width: 2,
          height: deadlines.length * 15.0 + 20 > 66 ? deadlines.length * 15.0 + 20 : 66,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
        ),
        pw.Expanded(flex: 12, child: right),
      ]),
    );

    final records = v.maintenanceSorted;
    final out = <pw.Widget>[
      top,
      pw.SizedBox(height: 6),
      pw.Text(tr('maint.title'), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
    ];
    if (records.isEmpty) {
      out.add(pw.Text(tr('pdf.noMaint'), style: pw.TextStyle(fontSize: 9, color: grey)));
    } else {
      final head = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
      const cell = pw.TextStyle(fontSize: 8.5);
      pw.Widget c(String t, pw.TextStyle st) =>
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(t, style: st));
      out.add(pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(56),
          1: pw.FixedColumnWidth(58),
          2: pw.FlexColumnWidth(3),
          3: pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: accent),
            children: [
              c(tr('maint.date'), head),
              c(tr('maint.km'), head),
              c(tr('maint.items'), head),
              c(tr('pdf.notes'), head),
            ],
          ),
          for (var i = 0; i < records.length; i++)
            pw.TableRow(
              decoration: i.isOdd ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
              children: [
                c(fmtDate(records[i].date), cell),
                c(records[i].km == null ? '—' : fmtKm(records[i].km!), cell),
                c(records[i].items.map(maintenanceItemLabel).join(', '), cell),
                c(records[i].notes, cell),
              ],
            ),
        ],
      ));
    }
    out.add(pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Divider(color: PdfColors.grey400, thickness: 0.6, height: 1),
    ));
    return out;
  }
}
