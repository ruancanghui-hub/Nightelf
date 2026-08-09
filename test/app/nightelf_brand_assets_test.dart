import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'macOS AppIcon uses every mapped size and the emerald palette',
    () async {
      const iconDirectory = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
      const expectedSizes = <String, int>{
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
      };

      for (final entry in expectedSizes.entries) {
        final bytes = await File('$iconDirectory/${entry.key}').readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, entry.value, reason: entry.key);
        expect(frame.image.height, entry.value, reason: entry.key);
        frame.image.dispose();
        codec.dispose();
      }

      final masterBytes = await File(
        '$iconDirectory/app_icon_1024.png',
      ).readAsBytes();
      final masterCodec = await ui.instantiateImageCodec(masterBytes);
      final masterFrame = await masterCodec.getNextFrame();
      final rgba = await masterFrame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final center = ((512 * 1024) + 512) * 4;
      final red = rgba!.getUint8(center);
      final green = rgba.getUint8(center + 1);
      final blue = rgba.getUint8(center + 2);
      expect(green, greaterThan(red));
      expect(green, greaterThan(blue));
      masterFrame.image.dispose();
      masterCodec.dispose();

      final contents =
          jsonDecode(await File('$iconDirectory/Contents.json').readAsString())
              as Map<String, dynamic>;
      final filenames = (contents['images'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((image) => image['filename'] as String)
          .toSet();
      expect(filenames, expectedSizes.keys.toSet());
    },
  );
}
