import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import 'dual_capture_exception.dart';
import 'dual_capture_options.dart';
import 'dual_capture_result.dart';
import 'image_compositor.dart';

/// The lifecycle states of a [DualCaptureController].
enum DualCaptureState {
  /// No camera has been initialised yet.
  uninitialized,

  /// The back camera is being initialised.
  initializingBack,

  /// The back camera is ready; awaiting the user to trigger capture.
  readyBack,

  /// The back camera shutter has been triggered.
  capturingBack,

  /// The back-camera photo has been saved to disk.
  captureDoneBack,

  /// The front camera is being initialised.
  initializingFront,

  /// The front camera is ready (warm-up delay elapsed).
  readyFront,

  /// The front camera shutter has been triggered.
  capturingFront,

  /// Both photos have been captured; compositing is in progress.
  compositing,

  /// Compositing is complete; [DualCaptureController.lastResult] is set.
  done,

  /// An error occurred; see [DualCaptureController.error].
  error,
}

/// Manages the back → front capture pipeline.
///
/// Extends [ChangeNotifier] — use [ListenableBuilder] to rebuild UI on state
/// changes.
class DualCaptureController extends ChangeNotifier {
  /// Creates a controller with the given [options].
  DualCaptureController({DualCaptureOptions? options})
      : _options = options ?? DualCaptureOptions.defaults;

  final DualCaptureOptions _options;

  DualCaptureState _state = DualCaptureState.uninitialized;
  Object? _error;
  DualCaptureResult? _lastResult;
  CameraController? _backController;
  CameraController? _frontController;

  /// Current pipeline state.
  DualCaptureState get state => _state;

  /// The error that caused the [DualCaptureState.error] state, if any.
  Object? get error => _error;

  /// The most recent successfully composited result.
  DualCaptureResult? get lastResult => _lastResult;

  /// The currently active [CameraController], for use with [CameraPreview].
  CameraController? get activeCameraController {
    if (_state == DualCaptureState.readyBack ||
        _state == DualCaptureState.capturingBack ||
        _state == DualCaptureState.captureDoneBack) {
      return _backController;
    }
    if (_state == DualCaptureState.readyFront ||
        _state == DualCaptureState.capturingFront) {
      return _frontController;
    }
    return null;
  }

  /// True when a camera has been initialised and is showing a live preview.
  bool get isReady =>
      _state == DualCaptureState.readyBack ||
      _state == DualCaptureState.readyFront;

  /// True when the pipeline is busy and should not be interrupted.
  bool get isBusy =>
      _state != DualCaptureState.uninitialized &&
      _state != DualCaptureState.readyBack &&
      _state != DualCaptureState.error &&
      _state != DualCaptureState.done;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initialises the back camera and transitions to [DualCaptureState.readyBack].
  ///
  /// Must only be called when [state] is [DualCaptureState.uninitialized].
  Future<void> initialize() async {
    assert(
      _state == DualCaptureState.uninitialized,
      'initialize() called in state $_state',
    );
    try {
      _setState(DualCaptureState.initializingBack);
      final cameras = await availableCameras();
      final backDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => throw const DualCaptureException('No back camera found'),
      );
      _backController = CameraController(
        backDesc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _backController!.initialize();
      _setState(DualCaptureState.readyBack);
    } catch (e) {
      _setError(e);
    }
  }

  /// Runs the full sequential capture pipeline and returns the result.
  ///
  /// Must only be called when [state] is [DualCaptureState.readyBack].
  Future<DualCaptureResult> capture() async {
    assert(
      _state == DualCaptureState.readyBack,
      'capture() called in state $_state',
    );
    try {
      final capturedAt = DateTime.now().toUtc();

      // 1-2. Capture back camera.
      _setState(DualCaptureState.capturingBack);
      final backFile = await _backController!.takePicture();
      _setState(DualCaptureState.captureDoneBack);

      // 4. Null + notify first, then wait one frame so CameraPreview is removed
      //    from the tree before dispose() triggers its internal listeners.
      final backCtrl = _backController!;
      _backController = null;
      _setState(DualCaptureState.initializingFront);
      await WidgetsBinding.instance.endOfFrame;
      await backCtrl.dispose();
      final cameras = await availableCameras();
      final frontDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () =>
            throw const DualCaptureException('No front camera found'),
      );
      _frontController = CameraController(
        frontDesc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _frontController!.initialize();

      // 6. Warm-up delay.
      await Future<void>.delayed(_options.frontCameraWarmupDelay);
      _setState(DualCaptureState.readyFront);

      // 7-8. Capture front camera.
      _setState(DualCaptureState.capturingFront);
      final frontFile = await _frontController!.takePicture();

      // 9. Null out before disposing so preview stops rendering it first.
      final frontCtrl = _frontController!;
      _frontController = null;
      _setState(DualCaptureState.compositing);
      await frontCtrl.dispose();
      final backBytes = await File(backFile.path).readAsBytes();
      final frontBytes = await File(frontFile.path).readAsBytes();

      final compositedBytes = await ImageCompositor.composite(
        backImageBytes: backBytes,
        frontImageBytes: frontBytes,
        options: _options,
      );

      final tempDir = Directory.systemTemp;
      final timestamp = capturedAt.millisecondsSinceEpoch;
      final compositedFile =
          File('${tempDir.path}/dual_capture_composited_$timestamp.jpg');
      await compositedFile.writeAsBytes(compositedBytes);

      final result = DualCaptureResult(
        compositedFile: compositedFile,
        backCameraFile: File(backFile.path),
        frontCameraFile: File(frontFile.path),
        capturedAt: capturedAt,
      );
      _lastResult = result;
      _setState(DualCaptureState.done);
      return result;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _setState(DualCaptureState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(Object e) {
    _error = e is DualCaptureException
        ? e
        : DualCaptureException(e.toString(), e);
    _state = DualCaptureState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _backController?.dispose();
    _frontController?.dispose();
    super.dispose();
  }
}
