import 'dart:isolate';
import 'dart:typed_data';

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
    final scale = options.overlayScale;
    final quality = options.jpegQuality;
    final margin = options.overlayMargin;
    final flip = options.flipFrontCamera;
    final posIndex = options.overlayPosition.index;
    final borderR = border == null ? -1 : (border.color.r * 255.0).round().clamp(0, 255);
    final borderG = border == null ? -1 : (border.color.g * 255.0).round().clamp(0, 255);
    final borderB = border == null ? -1 : (border.color.b * 255.0).round().clamp(0, 255);
    final borderA = border == null ? -1 : (border.color.a * 255.0).round().clamp(0, 255);
    final borderW = border?.width ?? -1.0;
    final borderRadius = border?.cornerRadius ?? 0.0;

    // Use Isolate.run with a closure — all captured values are primitives or
    // Uint8List, both of which are safe to copy across isolate boundaries.
    return Isolate.run(() => _composite(
          backBytes: backImageBytes,
          frontBytes: frontImageBytes,
          overlayScale: scale,
          jpegQuality: quality,
          overlayMargin: margin,
          flipFrontCamera: flip,
          overlayPositionIndex: posIndex,
          borderColorR: borderR,
          borderColorG: borderG,
          borderColorB: borderB,
          borderColorA: borderA,
          borderWidth: borderW,
          borderCornerRadius: borderRadius,
        ));
  }
}

Uint8List _composite({
  required Uint8List backBytes,
  required Uint8List frontBytes,
  required double overlayScale,
  required int jpegQuality,
  required int overlayMargin,
  required bool flipFrontCamera,
  required int overlayPositionIndex,
  required int borderColorR,
  required int borderColorG,
  required int borderColorB,
  required int borderColorA,
  required double borderWidth,
  required double borderCornerRadius,
}) {
  // 1. Decode both images.
  img.Image? back;
  try {
    back = img.decodeImage(backBytes);
  } catch (e) {
    throw Exception('dual_capture: failed to decode back-camera image: $e');
  }
  if (back == null) throw Exception('dual_capture: failed to decode back-camera image');

  img.Image? rawFront;
  try {
    rawFront = img.decodeImage(frontBytes);
  } catch (e) {
    throw Exception('dual_capture: failed to decode front-camera image: $e');
  }
  if (rawFront == null) throw Exception('dual_capture: failed to decode front-camera image');

  // 2. Resize front to overlayScale * backWidth, preserving aspect ratio.
  final overlayW = (back.width * overlayScale).round();
  final overlayH = (rawFront.height * (overlayW / rawFront.width)).round();
  var front = img.copyResize(rawFront,
      width: overlayW, height: overlayH, interpolation: img.Interpolation.linear);

  // 3. Optionally flip front horizontally.
  if (flipFrontCamera) front = img.flipHorizontal(front);

  // 4. Apply rounded corners + optional border.
  final radius = borderCornerRadius.round();
  front = _applyRoundedCorners(front, radius);

  final hasBorder = borderWidth > 0;
  if (hasBorder) {
    front = _applyBorder(
      front,
      borderWidth: borderWidth.round(),
      cornerRadius: radius,
      r: borderColorR,
      g: borderColorG,
      b: borderColorB,
      a: borderColorA,
    );
  }

  // 5. Calculate destination position.
  final position = OverlayPosition.values[overlayPositionIndex];
  int dstX;
  int dstY;
  switch (position) {
    case OverlayPosition.bottomRight:
      dstX = back.width - front.width - overlayMargin;
      dstY = back.height - front.height - overlayMargin;
    case OverlayPosition.bottomLeft:
      dstX = overlayMargin;
      dstY = back.height - front.height - overlayMargin;
    case OverlayPosition.topRight:
      dstX = back.width - front.width - overlayMargin;
      dstY = overlayMargin;
    case OverlayPosition.topLeft:
      dstX = overlayMargin;
      dstY = overlayMargin;
  }

  // 6. Composite and encode.
  final composited = img.compositeImage(back, front,
      dstX: dstX, dstY: dstY, blend: img.BlendMode.alpha);

  return Uint8List.fromList(img.encodeJpg(composited, quality: jpegQuality));
}

img.Image _applyRoundedCorners(img.Image src, int radius) {
  if (radius <= 0) return src;
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

bool _isOutsideRoundedRect(int px, int py, int w, int h, int r) {
  if (px < r && py < r) return _distSq(px, py, r, r) > r * r;
  if (px >= w - r && py < r) return _distSq(px, py, w - r - 1, r) > r * r;
  if (px < r && py >= h - r) return _distSq(px, py, r, h - r - 1) > r * r;
  if (px >= w - r && py >= h - r) return _distSq(px, py, w - r - 1, h - r - 1) > r * r;
  return false;
}

double _distSq(int px, int py, int cx, int cy) {
  final dx = px - cx;
  final dy = py - cy;
  return (dx * dx + dy * dy).toDouble();
}

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
  return img.compositeImage(border, inner,
      dstX: borderWidth, dstY: borderWidth, blend: img.BlendMode.alpha);
}
