import 'package:flutter/painting.dart';

/// Defines the decorative border drawn around the front-camera overlay.
class OverlayBorder {
  /// Creates an [OverlayBorder].
  ///
  /// [width] and [cornerRadius] must be non-negative.
  const OverlayBorder({
    this.color = const Color(0xFFFFFFFF),
    this.width = 2.0,
    this.cornerRadius = 12.0,
  })  : assert(width >= 0, 'width must be non-negative'),
        assert(cornerRadius >= 0, 'cornerRadius must be non-negative');

  /// The border colour. Defaults to opaque white.
  final Color color;

  /// Stroke width in logical pixels. Defaults to 2.0.
  final double width;

  /// Corner radius applied to both the border and the inner clip. Defaults to 12.0.
  final double cornerRadius;

  /// Returns a copy with the given fields replaced.
  OverlayBorder copyWith({
    Color? color,
    double? width,
    double? cornerRadius,
  }) {
    return OverlayBorder(
      color: color ?? this.color,
      width: width ?? this.width,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayBorder &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode => Object.hash(color, width, cornerRadius);

  @override
  String toString() =>
      'OverlayBorder(color: $color, width: $width, cornerRadius: $cornerRadius)';
}
