import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'dual_capture_controller.dart';

/// Displays the live camera preview managed by [DualCaptureController].
///
/// Shows [loadingWidget] while initialising and [errorWidget] on failure.
class DualCapturePreview extends StatelessWidget {
  /// Creates a [DualCapturePreview].
  const DualCapturePreview({
    super.key,
    required this.controller,
    this.loadingWidget,
    this.errorWidget,
  });

  /// The controller driving this preview.
  final DualCaptureController controller;

  /// Widget shown while the camera is initialising. Defaults to a white
  /// [CircularProgressIndicator] on a black background.
  final Widget? loadingWidget;

  /// Widget shown when the controller is in the error state. Defaults to
  /// centred red error text.
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.state == DualCaptureState.error) {
          return errorWidget ??
              Center(
                child: Text(
                  controller.error?.toString() ?? 'An error occurred',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
        }

        final cam = controller.activeCameraController;
        if (cam == null || !cam.value.isInitialized) {
          return loadingWidget ??
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
        }

        return CameraPreview(cam);
      },
    );
  }
}
