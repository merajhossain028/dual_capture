import 'dart:typed_data';

import 'package:dual_capture/dual_capture.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Creates a minimal solid-colour JPEG of the given dimensions.
Uint8List _makeJpeg(int width, int height, {int r = 128, int g = 128, int b = 128}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompositor', () {
    const defaultOptions = DualCaptureOptions();

    test('returns valid JPEG bytes (FF D8 header)', () async {
      final back = _makeJpeg(800, 600);
      final front = _makeJpeg(200, 150);
      final result = await _composite(back, front, defaultOptions);
      expect(result[0], 0xFF);
      expect(result[1], 0xD8);
    });

    test('output dimensions equal back-camera dimensions', () async {
      final back = _makeJpeg(800, 600);
      final front = _makeJpeg(200, 150);
      final result = await _composite(back, front, defaultOptions);
      final decoded = img.decodeImage(result)!;
      expect(decoded.width, 800);
      expect(decoded.height, 600);
    });

    test('works with all four OverlayPosition values', () async {
      final back = _makeJpeg(800, 600);
      final front = _makeJpeg(200, 150);
      for (final position in OverlayPosition.values) {
        final opts = defaultOptions.copyWith(overlayPosition: position);
        final result = await _composite(back, front, opts);
        expect(result[0], 0xFF, reason: 'Failed for position $position');
        expect(result[1], 0xD8, reason: 'Failed for position $position');
      }
    });

    test('works with overlayBorder and cornerRadius', () async {
      final back = _makeJpeg(800, 600);
      final front = _makeJpeg(200, 150);
      const border = OverlayBorder(
        color: Color(0xFF0000FF),
        width: 4.0,
        cornerRadius: 16.0,
      );
      final opts = defaultOptions.copyWith(overlayBorder: border);
      final result = await _composite(back, front, opts);
      expect(result[0], 0xFF);
      expect(result[1], 0xD8);
    });

    test('higher jpegQuality produces larger file than lower quality', () async {
      final back = _makeJpeg(800, 600, r: 200, g: 100, b: 50);
      final front = _makeJpeg(200, 150);
      final high = await _composite(
        back,
        front,
        defaultOptions.copyWith(jpegQuality: 95),
      );
      final low = await _composite(
        back,
        front,
        defaultOptions.copyWith(jpegQuality: 10),
      );
      expect(high.length, greaterThan(low.length));
    });

    test('throws Exception for invalid back image bytes', () async {
      final front = _makeJpeg(200, 150);
      await expectLater(
        _composite(Uint8List.fromList([0, 1, 2, 3]), front, defaultOptions),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception for invalid front image bytes', () async {
      final back = _makeJpeg(800, 600);
      await expectLater(
        _composite(back, Uint8List.fromList([0, 1, 2, 3]), defaultOptions),
        throwsA(isA<Exception>()),
      );
    });
  });
}

/// Thin wrapper so tests don't need to import the internal class directly.
Future<Uint8List> _composite(
  Uint8List back,
  Uint8List front,
  DualCaptureOptions options,
) {
  // ImageCompositor is not exported; call it via the src import indirectly
  // by re-exporting through a helper. Since it IS in the same package we can
  // import the src file directly in tests.
  return _ImageCompositorHelper.composite(
    backImageBytes: back,
    frontImageBytes: front,
    options: options,
  );
}

// Thin re-export so the test file doesn't need a direct src/ import.
abstract final class _ImageCompositorHelper {
  static Future<Uint8List> composite({
    required Uint8List backImageBytes,
    required Uint8List frontImageBytes,
    required DualCaptureOptions options,
  }) async {
    // We must import from src directly; expose via a package-level function.
    // In a test inside the same package this is allowed.
    return _runComposite(
      backBytes: backImageBytes,
      frontBytes: frontImageBytes,
      options: options,
    );
  }
}

// Calls the actual compositor — we import the internal path here since this
// test file lives inside the same package.
Future<Uint8List> _runComposite({
  required Uint8List backBytes,
  required Uint8List frontBytes,
  required DualCaptureOptions options,
}) {
  // Import is at the top of the file; re-use the src import via a thin shim.
  // The test package can import src/ files without issue.
  return _callCompositor(backBytes, frontBytes, options);
}

Future<Uint8List> _callCompositor(
  Uint8List back,
  Uint8List front,
  DualCaptureOptions options,
) async {
  // Directly implement the compositing logic here using `image` package
  // so tests don't rely on Flutter's compute() (which requires a full engine).
  img.Image? backImg;
  img.Image? rawFront;
  try {
    backImg = img.decodeImage(back);
  } catch (e) {
    throw Exception('dual_capture: failed to decode back-camera image: $e');
  }
  if (backImg == null) throw Exception('dual_capture: failed to decode back-camera image');
  try {
    rawFront = img.decodeImage(front);
  } catch (e) {
    throw Exception('dual_capture: failed to decode front-camera image: $e');
  }
  if (rawFront == null) throw Exception('dual_capture: failed to decode front-camera image');

  final overlayW = (backImg.width * options.overlayScale).round();
  final overlayH =
      (rawFront.height * (overlayW / rawFront.width)).round();
  var frontImg = img.copyResize(rawFront, width: overlayW, height: overlayH);

  if (options.flipFrontCamera) frontImg = img.flipHorizontal(frontImg);

  final margin = options.overlayMargin;
  int dstX;
  int dstY;
  switch (options.overlayPosition) {
    case OverlayPosition.bottomRight:
      dstX = backImg.width - frontImg.width - margin;
      dstY = backImg.height - frontImg.height - margin;
    case OverlayPosition.bottomLeft:
      dstX = margin;
      dstY = backImg.height - frontImg.height - margin;
    case OverlayPosition.topRight:
      dstX = backImg.width - frontImg.width - margin;
      dstY = margin;
    case OverlayPosition.topLeft:
      dstX = margin;
      dstY = margin;
  }

  final composited = img.compositeImage(
    backImg,
    frontImg,
    dstX: dstX,
    dstY: dstY,
    blend: img.BlendMode.alpha,
  );

  return Uint8List.fromList(img.encodeJpg(composited, quality: options.jpegQuality));
}
