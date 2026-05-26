import 'package:flutter/material.dart';

import 'dual_capture_options.dart';
import 'dual_capture_result.dart';
import 'dual_capture_screen.dart';

/// Top-level API for triggering a dual-camera capture.
abstract final class DualCapture {
  /// Launches the dual-camera capture UI and returns the result.
  ///
  /// Pushes a full-screen [DualCaptureScreen] over the current route.
  /// Returns `null` if the user dismisses the screen without capturing.
  static Future<DualCaptureResult?> capture(
    BuildContext context, {
    DualCaptureOptions options = const DualCaptureOptions(),
  }) {
    return Navigator.of(context).push<DualCaptureResult>(
      MaterialPageRoute<DualCaptureResult>(
        fullscreenDialog: true,
        builder: (_) => DualCaptureScreen(options: options),
      ),
    );
  }
}
