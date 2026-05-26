import 'dart:io';

/// The result of a completed dual-capture session.
///
/// All three [File] references point to the system's temporary directory;
/// copy them to permanent storage if you need to keep them after the app
/// restarts, since the OS may purge the temp directory at any time.
class DualCaptureResult {
  /// Creates a [DualCaptureResult].
  const DualCaptureResult({
    required this.compositedFile,
    required this.backCameraFile,
    required this.frontCameraFile,
    required this.capturedAt,
  });

  /// The composited JPEG containing the back-camera image with the front-camera
  /// picture-in-picture overlay applied.
  final File compositedFile;

  /// The raw JPEG captured from the back camera, before any compositing.
  final File backCameraFile;

  /// The raw JPEG captured from the front camera, before any compositing.
  final File frontCameraFile;

  /// The UTC timestamp at which the capture was initiated.
  final DateTime capturedAt;

  @override
  String toString() => 'DualCaptureResult('
      'capturedAt: $capturedAt, '
      'composited: ${compositedFile.path}, '
      'back: ${backCameraFile.path}, '
      'front: ${frontCameraFile.path})';
}
