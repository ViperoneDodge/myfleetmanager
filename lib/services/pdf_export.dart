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
  static const int _longHistory = 4;

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

  static Future<Uint8List> build({required String title, required List<Vehicle> vehicles}) async {
    final theme = await _theme();
    final images = <String, pw.ImageProvider?>{};
    for (final v in vehicles) {
      images[v.id] = await _image(v);
    }
    final doc = pw.Document(title: title, creator: 'MyFleetManager', theme: theme);
    const accent = PdfColor.fromInt(0xFF1E4F8C);
    final grey = PdfColors.grey700;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (ctx) => pw.Center(
        child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Text('MyFleetManager', style: pw.TextStyle(fontSize: 16, color: grey)),
          pw.SizedBox(height: 18),
          pw.Text(title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 14),
          pw.Container(width: 120, height: 2, color: accent),
          pw.SizedBox(height: 14),
          pw.Text(tr('pdf.generated', {'date': fmtDate(DateTime.now())}),
              style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.Text(trn('family.vehicles', vehicles.length), style: const pw.TextStyle(fontSize: 14)),
        ]),
      ),
    ));

    if (vehicles.isEmpty) return doc.save();

    final body = <pw.Widget>[];
    var onPage = 0;
    for (final v in vehicles) {
      final long = v.maintenance.length > _longHistory;
      if (onPage >= 2 || (long && onPage > 0)) {
        body.add(pw.NewPage());
        onPage = 0;
      } else if (onPage == 1) {
        body.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          child: pw.Divider(color: PdfColors.grey400, thickness: 0.8),
        ));
      }
      body.addAll(_vehicle(v, images[v.id], accent, grey));
      onPage = long ? 2 : onPage + 1;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('$title · ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: grey)),
      ),
      build: (ctx) => body,
    ));
    return doc.save();
  }

  static List<pw.Widget> _vehicle(Vehicle v, pw.ImageProvider? image, PdfColor accent, PdfColor grey) {
    final name = v.name.isEmpty ? (v.plate.isEmpty ? tr('vehicle.generic') : v.plate) : v.name;
    pw.Widget info(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(color: grey, fontSize: 10)),
              pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 11)),
            ]),
          ),
        );

    final header = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        width: 130,
        height: 83,
        padding: v.photoBytes == null ? const pw.EdgeInsets.all(10) : null,
        decoration: pw.BoxDecoration(
          color: v.photoBytes == null ? PdfColors.blueGrey400 : PdfColors.grey200,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: image == null
            ? null
            : pw.Image(image, fit: v.photoBytes != null ? pw.BoxFit.cover : pw.BoxFit.contain),
      ),
      pw.SizedBox(width: 14),
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 6),
          info(tr('edit.type'), vehicleTypeLabel(v.type)),
          info(tr('edit.plate'), v.plate.isEmpty ? '—' : v.plate),
          info(tr('vehicle.regDate'), fmtDate(v.registrationDate)),
        ]),
      ),
    ]);

    final deadlines = v.activeDeadlines;
    final dl = <pw.Widget>[
      pw.SizedBox(height: 10),
      pw.Text(tr('tab.deadlines'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      if (deadlines.isEmpty) pw.Text(tr('vehicle.noTracked'), style: pw.TextStyle(fontSize: 10, color: grey)),
      ...deadlines.map((d) {
        final s = dueStatus(d.dueDate!);
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(children: [
            pw.Container(
              width: 7,
              height: 7,
              decoration: pw.BoxDecoration(color: _color(s.color.toARGB32()), shape: pw.BoxShape.circle),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(child: pw.Text(d.dueLabel, style: const pw.TextStyle(fontSize: 10.5))),
            pw.SizedBox(width: 70, child: pw.Text(fmtDate(d.dueDate), style: const pw.TextStyle(fontSize: 10.5))),
            pw.SizedBox(
              width: 150,
              child: pw.Text(s.text,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 10, color: _color(s.color.toARGB32()))),
            ),
          ]),
        );
      }),
    ];

    final records = v.maintenanceSorted;
    final mt = <pw.Widget>[
      pw.SizedBox(height: 10),
      pw.Text(tr('maint.title'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
    ];
    if (records.isEmpty) {
      mt.add(pw.Text(tr('pdf.noMaint'), style: pw.TextStyle(fontSize: 10, color: grey)));
    } else {
      final head = pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
      const cell = pw.TextStyle(fontSize: 9.5);
      pw.Widget c(String t, pw.TextStyle st) =>
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3), child: pw.Text(t, style: st));
      mt.add(pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(62),
          1: pw.FixedColumnWidth(62),
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
    return [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [header, ...dl]),
      ...mt,
    ];
  }
}
