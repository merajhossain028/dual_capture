import 'overlay_border.dart';
import 'overlay_position.dart';

/// Configuration for a dual-capture session.
///
/// Pass a customised instance to [DualCapture.capture] or
/// [DualCaptureController] to control overlay placement, sizing, and
/// compositing quality.
class DualCaptureOptions {
  /// Creates a [DualCaptureOptions]. All parameters are optional.
  const DualCaptureOptions({
    this.overlayPosition = OverlayPosition.bottomRight,
    this.overlayScale = 0.30,
    this.jpegQuality = 85,
    this.overlayMargin = 16,
    this.flipFrontCamera = true,
    this.overlayBorder,
    this.frontCameraWarmupDelay = const Duration(milliseconds: 500),
  })  : assert(
          overlayScale > 0 && overlayScale <= 1,
          'overlayScale must be in the range (0, 1]',
        ),
        assert(
          jpegQuality >= 1 && jpegQuality <= 100,
          'jpegQuality must be in the range [1, 100]',
        ),
        assert(overlayMargin >= 0, 'overlayMargin must be non-negative');

  /// A ready-to-use instance with all default values.
  static const DualCaptureOptions defaults = DualCaptureOptions();

  /// Corner of the back-camera image where the PiP overlay is placed.
  ///
  /// Defaults to [OverlayPosition.bottomRight].
  final OverlayPosition overlayPosition;

  /// Fraction of the back-camera image width used as the overlay width.
  ///
  /// Must be in the range `(0, 1]`. Defaults to `0.30` (30 %).
  final double overlayScale;

  /// JPEG quality for the composited output image. Must be in `[1, 100]`.
  ///
  /// Defaults to `85`.
  final int jpegQuality;

  /// Margin (in pixels of the back-camera image) between the overlay and the
  /// nearest edges. Must be non-negative. Defaults to `16`.
  final int overlayMargin;

  /// Whether to mirror the front-camera image horizontally before compositing.
  ///
  /// Mirroring produces a "selfie" look that matches the camera preview.
  /// Defaults to `true`.
  final bool flipFrontCamera;

  /// Optional border drawn around the overlay. When `null`, no border is drawn.
  final OverlayBorder? overlayBorder;

  /// How long to wait after initialising the front camera before capturing.
  ///
  /// Some devices need a brief warm-up period to expose correctly.
  /// Defaults to 500 ms.
  final Duration frontCameraWarmupDelay;

  /// Returns a copy with the given fields replaced.
  DualCaptureOptions copyWith({
    OverlayPosition? overlayPosition,
    double? overlayScale,
    int? jpegQuality,
    int? overlayMargin,
    bool? flipFrontCamera,
    OverlayBorder? overlayBorder,
    Duration? frontCameraWarmupDelay,
  }) {
    return DualCaptureOptions(
      overlayPosition: overlayPosition ?? this.overlayPosition,
      overlayScale: overlayScale ?? this.overlayScale,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      overlayMargin: overlayMargin ?? this.overlayMargin,
      flipFrontCamera: flipFrontCamera ?? this.flipFrontCamera,
      overlayBorder: overlayBorder ?? this.overlayBorder,
      frontCameraWarmupDelay:
          frontCameraWarmupDelay ?? this.frontCameraWarmupDelay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DualCaptureOptions &&
          runtimeType == other.runtimeType &&
          overlayPosition == other.overlayPosition &&
          overlayScale == other.overlayScale &&
          jpegQuality == other.jpegQuality &&
          overlayMargin == other.overlayMargin &&
          flipFrontCamera == other.flipFrontCamera &&
          overlayBorder == other.overlayBorder &&
          frontCameraWarmupDelay == other.frontCameraWarmupDelay;

  @override
  int get hashCode => Object.hash(
        overlayPosition,
        overlayScale,
        jpegQuality,
        overlayMargin,
        flipFrontCamera,
        overlayBorder,
        frontCameraWarmupDelay,
      );

  @override
  String toString() => 'DualCaptureOptions('
      'overlayPosition: $overlayPosition, '
      'overlayScale: $overlayScale, '
      'jpegQuality: $jpegQuality, '
      'overlayMargin: $overlayMargin, '
      'flipFrontCamera: $flipFrontCamera, '
      'overlayBorder: $overlayBorder, '
      'frontCameraWarmupDelay: $frontCameraWarmupDelay)';
}
