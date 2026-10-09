import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

class DocCloud {
  static const int maxSourceBytes = 5 * 1024 * 1024;
  static const int quotaBytes = 25 * 1024 * 1024;
  static const int maxEncodedBytes = 700 * 1024;

  static Future<Uint8List?> compress(File file, {required bool pdf}) async {
    Uint8List source;
    if (pdf) {
      final bytes = await file.readAsBytes();
      Uint8List? png;
      await for (final page in Printing.raster(bytes, pages: const [0], dpi: 150)) {
        png = await page.toPng();
        break;
      }
      if (png == null) return null;
      source = png;
    } else {
      source = await file.readAsBytes();
    }
    return compute(_encode, source);
  }

  static Uint8List? _encode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    var image = img.bakeOrientation(decoded);
    if (image.hasAlpha) {
      final bg = img.Image(width: image.width, height: image.height);
      img.fill(bg, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(bg, image);
      image = bg;
    }
    for (final side in const [1600, 1280, 1024]) {
      if (image.width > side || image.height > side) {
        image = image.width >= image.height
            ? img.copyResize(image, width: side, interpolation: img.Interpolation.average)
            : img.copyResize(image, height: side, interpolation: img.Interpolation.average);
      }
      for (final q in const [72, 60, 48]) {
        final jpg = Uint8List.fromList(img.encodeJpg(image, quality: q));
        if (jpg.length <= maxEncodedBytes) return jpg;
      }
    }
    return null;
  }

  static String toB64(Uint8List bytes) => base64Encode(bytes);

  static Uint8List fromB64(String b64) => base64Decode(b64);
}
