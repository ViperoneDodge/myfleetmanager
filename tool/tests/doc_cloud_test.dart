import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myfleetmanager/services/doc_cloud.dart';

void main() {
  test('foto grande compressa sotto il limite, sfondo trasparente reso bianco', () async {
    final src = img.Image(width: 4000, height: 3000, numChannels: 4);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        src.setPixelRgba(x, y, (x * 7) % 256, (y * 13) % 256, (x + y) % 256, x < 200 ? 0 : 255);
      }
    }
    final dir = await Directory.systemTemp.createTemp('doc_cloud');
    final f = File('${dir.path}/big.png')..writeAsBytesSync(img.encodePng(src));
    final jpg = await DocCloud.compress(f, pdf: false);
    expect(jpg, isNotNull);
    expect(jpg!.length, lessThanOrEqualTo(DocCloud.maxEncodedBytes));
    final out = img.decodeJpg(jpg)!;
    expect(out.width, lessThanOrEqualTo(1600));
    expect(out.height, lessThanOrEqualTo(1600));
    final corner = out.getPixel(5, 5);
    expect(corner.r, greaterThan(230));
    expect(DocCloud.toB64(jpg).length, lessThan(1000000));
    await dir.delete(recursive: true);
  });

  test('file non immagine: nessun caricamento', () async {
    final dir = await Directory.systemTemp.createTemp('doc_cloud');
    final f = File('${dir.path}/x.jpg')..writeAsStringSync('not an image');
    expect(await DocCloud.compress(f, pdf: false), isNull);
    await dir.delete(recursive: true);
  });
}
