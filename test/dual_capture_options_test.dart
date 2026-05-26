import 'package:dual_capture/dual_capture.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DualCaptureOptions', () {
    test('default values', () {
      const opts = DualCaptureOptions();
      expect(opts.overlayPosition, OverlayPosition.bottomRight);
      expect(opts.overlayScale, 0.30);
      expect(opts.jpegQuality, 85);
      expect(opts.overlayMargin, 16);
      expect(opts.flipFrontCamera, true);
      expect(opts.overlayBorder, isNull);
      expect(opts.frontCameraWarmupDelay, const Duration(milliseconds: 500));
    });

    test('.defaults constant matches default constructor', () {
      expect(DualCaptureOptions.defaults, equals(const DualCaptureOptions()));
    });

    test('copyWith replaces fields', () {
      const original = DualCaptureOptions();
      final copy = original.copyWith(
        overlayPosition: OverlayPosition.topLeft,
        overlayScale: 0.5,
        jpegQuality: 70,
        overlayMargin: 8,
        flipFrontCamera: false,
        frontCameraWarmupDelay: const Duration(milliseconds: 200),
      );
      expect(copy.overlayPosition, OverlayPosition.topLeft);
      expect(copy.overlayScale, 0.5);
      expect(copy.jpegQuality, 70);
      expect(copy.overlayMargin, 8);
      expect(copy.flipFrontCamera, false);
      expect(copy.frontCameraWarmupDelay, const Duration(milliseconds: 200));
    });

    test('equality and hashCode', () {
      const a = DualCaptureOptions(jpegQuality: 70);
      const b = DualCaptureOptions(jpegQuality: 70);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('overlayScale assert: 0 throws', () {
      expect(
        () => DualCaptureOptions(overlayScale: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('overlayScale assert: 1.1 throws', () {
      expect(
        () => DualCaptureOptions(overlayScale: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('jpegQuality assert: 0 throws', () {
      expect(
        () => DualCaptureOptions(jpegQuality: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('jpegQuality assert: 101 throws', () {
      expect(
        () => DualCaptureOptions(jpegQuality: 101),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative overlayMargin throws', () {
      expect(
        () => DualCaptureOptions(overlayMargin: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toString contains key fields', () {
      const opts = DualCaptureOptions(jpegQuality: 42, overlayMargin: 8);
      final s = opts.toString();
      expect(s, contains('jpegQuality: 42'));
      expect(s, contains('overlayMargin: 8'));
    });
  });

  group('OverlayBorder', () {
    test('default values', () {
      const b = OverlayBorder();
      expect(b.color, const Color(0xFFFFFFFF));
      expect(b.width, 2.0);
      expect(b.cornerRadius, 12.0);
    });

    test('copyWith replaces fields', () {
      const original = OverlayBorder();
      final copy = original.copyWith(width: 4.0, cornerRadius: 8.0);
      expect(copy.width, 4.0);
      expect(copy.cornerRadius, 8.0);
      expect(copy.color, original.color);
    });

    test('equality', () {
      const a = OverlayBorder(width: 3.0);
      const b = OverlayBorder(width: 3.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('negative width throws', () {
      expect(
        () => OverlayBorder(width: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative cornerRadius throws', () {
      expect(
        () => OverlayBorder(cornerRadius: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DualCaptureException', () {
    test('toString without cause', () {
      const e = DualCaptureException('something went wrong');
      expect(e.toString(), contains('something went wrong'));
      expect(e.toString(), isNot(contains('cause')));
    });

    test('toString with cause', () {
      final cause = Exception('root cause');
      final e = DualCaptureException('outer message', cause);
      expect(e.toString(), contains('outer message'));
      expect(e.toString(), contains('cause'));
    });
  });

  group('OverlayPosition', () {
    test('all four values are present', () {
      expect(OverlayPosition.values, contains(OverlayPosition.bottomRight));
      expect(OverlayPosition.values, contains(OverlayPosition.bottomLeft));
      expect(OverlayPosition.values, contains(OverlayPosition.topRight));
      expect(OverlayPosition.values, contains(OverlayPosition.topLeft));
      expect(OverlayPosition.values.length, 4);
    });
  });
}
