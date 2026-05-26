import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'dual_capture_options.dart';
import 'overlay_position.dart';

/// Composites the back and front camera images in a background isolate.
abstract final class ImageCompositor {
  /// Composites [frontImageBytes] over [backImageBytes] as a picture-in-picture
  /// overlay, using the settings from [options].
  ///
  /// Returns the composited image encoded as a JPEG byte array.
  static Future<Uint8List> composite({
    required Uint8List backImageBytes,
    required Uint8List frontImageBytes,
    required DualCaptureOptions options,
  }) {
    final border = options.overlayBorder;
    final params = _CompositeParams(
      backBytes: backImageBytes,
      frontBytes: frontImageBytes,
      overlayScale: options.overlayScale,
      jpegQuality: options.jpegQuality,
      overlayMargin: options.overlayMargin,
      flipFrontCamera: options.flipFrontCamera,
      overlayPositionIndex: options.overlayPosition.index,
      borderColorR: border == null ? null : (border.color.r * 255.0).round().clamp(0, 255),
      borderColorG: border == null ? null : (border.color.g * 255.0).round().clamp(0, 255),
      borderColorB: border == null ? null : (border.color.b * 255.0).round().clamp(0, 255),
      borderColorA: border == null ? null : (border.color.a * 255.0).round().clamp(0, 255),
      borderWidth: border?.width,
      borderCornerRadius: border?.cornerRadius,
    );
    return compute(_compositeInIsolate, params);
  }
}

/// Parameter bag — only primitive types so it can cross isolate boundaries.
class _CompositeParams {
  const _CompositeParams({
    required this.backBytes,
    required this.frontBytes,
    required this.overlayScale,
    required this.jpegQuality,
    required this.overlayMargin,
    required this.flipFrontCamera,
    required this.overlayPositionIndex,
    this.borderColorR,
    this.borderColorG,
    this.borderColorB,
    this.borderColorA,
    this.borderWidth,
    this.borderCornerRadius,
  });

  final Uint8List backBytes;
  final Uint8List frontBytes;
  final double overlayScale;
  final int jpegQuality;
  final int overlayMargin;
  final bool flipFrontCamera;
  final int overlayPositionIndex;
  final int? borderColorR;
  final int? borderColorG;
  final int? borderColorB;
  final int? borderColorA;
  final double? borderWidth;
  final double? borderCornerRadius;
}

/// Runs in a background isolate.
Uint8List _compositeInIsolate(_CompositeParams p) {
  // 1. Decode both images.
  img.Image? back;
  try {
    back = img.decodeImage(p.backBytes);
  } catch (e) {
    throw Exception('dual_capture: failed to decode back-camera image: $e');
  }
  if (back == null) throw Exception('dual_capture: failed to decode back-camera image');

  img.Image? rawFront;
  try {
    rawFront = img.decodeImage(p.frontBytes);
  } catch (e) {
    throw Exception('dual_capture: failed to decode front-camera image: $e');
  }
  if (rawFront == null) throw Exception('dual_capture: failed to decode front-camera image');

  // 2. Resize front to overlayScale * backWidth, preserving aspect ratio.
  final overlayW = (back.width * p.overlayScale).round();
  final overlayH =
      (rawFront.height * (overlayW / rawFront.width)).round();
  var front = img.copyResize(rawFront, width: overlayW, height: overlayH,
      interpolation: img.Interpolation.linear);

  // 3. Optionally flip front horizontally.
  if (p.flipFrontCamera) {
    front = img.flipHorizontal(front);
  }

  // 4. Apply rounded corners (and border if specified).
  final hasBorder = p.borderWidth != null && p.borderWidth! > 0;
  final radius = (p.borderCornerRadius ?? 0.0).round();

  front = _applyRoundedCorners(front, radius);

  if (hasBorder) {
    front = _applyBorder(
      front,
      borderWidth: p.borderWidth!.round(),
      cornerRadius: radius,
      r: p.borderColorR ?? 255,
      g: p.borderColorG ?? 255,
      b: p.borderColorB ?? 255,
      a: p.borderColorA ?? 255,
    );
  }

  // 7. Calculate destination position from OverlayPosition + margin.
  final position = OverlayPosition.values[p.overlayPositionIndex];
  int dstX;
  int dstY;
  switch (position) {
    case OverlayPosition.bottomRight:
      dstX = back.width - front.width - p.overlayMargin;
      dstY = back.height - front.height - p.overlayMargin;
    case OverlayPosition.bottomLeft:
      dstX = p.overlayMargin;
      dstY = back.height - front.height - p.overlayMargin;
    case OverlayPosition.topRight:
      dstX = back.width - front.width - p.overlayMargin;
      dstY = p.overlayMargin;
    case OverlayPosition.topLeft:
      dstX = p.overlayMargin;
      dstY = p.overlayMargin;
  }

  // 8. Composite overlay onto back image.
  final composited = img.compositeImage(
    back,
    front,
    dstX: dstX,
    dstY: dstY,
    blend: img.BlendMode.alpha,
  );

  // 9. Encode as JPEG.
  return Uint8List.fromList(
    img.encodeJpg(composited, quality: p.jpegQuality),
  );
}

/// Applies a rounded-corner alpha mask to [src] in place, returning the result.
img.Image _applyRoundedCorners(img.Image src, int radius) {
  if (radius <= 0) return src;
  // Ensure image is RGBA so we can set the alpha channel.
  final out = src.format == img.Format.uint8 && src.numChannels == 4
      ? src.clone()
      : src.convert(numChannels: 4);

  final w = out.width;
  final h = out.height;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (_isOutsideRoundedRect(x, y, w, h, radius)) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return out;
}

/// Returns true if pixel (px, py) is outside a rounded rectangle.
bool _isOutsideRoundedRect(int px, int py, int w, int h, int r) {
  // Check corners.
  if (px < r && py < r) {
    return _distSq(px, py, r, r) > r * r;
  }
  if (px >= w - r && py < r) {
    return _distSq(px, py, w - r - 1, r) > r * r;
  }
  if (px < r && py >= h - r) {
    return _distSq(px, py, r, h - r - 1) > r * r;
  }
  if (px >= w - r && py >= h - r) {
    return _distSq(px, py, w - r - 1, h - r - 1) > r * r;
  }
  return false;
}

double _distSq(int px, int py, int cx, int cy) {
  final dx = px - cx;
  final dy = py - cy;
  return (dx * dx + dy * dy).toDouble();
}

/// Wraps [inner] in a border of [borderWidth] pixels, with the same corner
/// radius applied to the outer edge.
img.Image _applyBorder(
  img.Image inner, {
  required int borderWidth,
  required int cornerRadius,
  required int r,
  required int g,
  required int b,
  required int a,
}) {
  final outerW = inner.width + borderWidth * 2;
  final outerH = inner.height + borderWidth * 2;

  // Fill border image with border colour.
  final border = img.Image(width: outerW, height: outerH, numChannels: 4);
  for (var y = 0; y < outerH; y++) {
    for (var x = 0; x < outerW; x++) {
      if (_isOutsideRoundedRect(x, y, outerW, outerH, cornerRadius + borderWidth)) {
        border.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        border.setPixelRgba(x, y, r, g, b, a);
      }
    }
  }

  // Composite inner (already rounded) onto border.
  return img.compositeImage(
    border,
    inner,
    dstX: borderWidth,
    dstY: borderWidth,
    blend: img.BlendMode.alpha,
  );
}
