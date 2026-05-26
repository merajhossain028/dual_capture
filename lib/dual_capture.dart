/// A Flutter package for dual camera capture.
///
/// Use [DualCapture.capture] for a one-shot capture, or instantiate a
/// [DualCaptureController] directly for embedded/custom UIs.
library dual_capture;

export 'src/dual_capture_api.dart' show DualCapture;
export 'src/dual_capture_controller.dart'
    show DualCaptureController, DualCaptureState;
export 'src/dual_capture_exception.dart' show DualCaptureException;
export 'src/dual_capture_options.dart' show DualCaptureOptions;
export 'src/dual_capture_preview.dart' show DualCapturePreview;
export 'src/dual_capture_result.dart' show DualCaptureResult;
export 'src/dual_capture_screen.dart' show DualCaptureScreen;
export 'src/overlay_border.dart' show OverlayBorder;
export 'src/overlay_position.dart' show OverlayPosition;
