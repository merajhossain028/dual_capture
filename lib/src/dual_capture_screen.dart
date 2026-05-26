import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dual_capture_controller.dart';
import 'dual_capture_options.dart';
import 'dual_capture_preview.dart';
import 'dual_capture_result.dart';

/// Full-screen camera UI that drives the complete dual-capture pipeline.
///
/// Push this route via [DualCapture.capture] or directly via [Navigator.push].
/// It pops with a [DualCaptureResult] on success, or `null` if the user
/// dismisses without capturing.
class DualCaptureScreen extends StatefulWidget {
  /// Creates a [DualCaptureScreen] with the given [options].
  const DualCaptureScreen({super.key, this.options = const DualCaptureOptions()});

  /// Compositing options forwarded to [DualCaptureController].
  final DualCaptureOptions options;

  @override
  State<DualCaptureScreen> createState() => _DualCaptureScreenState();
}

class _DualCaptureScreenState extends State<DualCaptureScreen> {
  late final DualCaptureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DualCaptureController(options: widget.options);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _stateLabel(DualCaptureState s) {
    switch (s) {
      case DualCaptureState.uninitialized:
        return 'Preparing…';
      case DualCaptureState.initializingBack:
        return 'Starting back camera…';
      case DualCaptureState.readyBack:
        return 'Ready';
      case DualCaptureState.capturingBack:
        return 'Capturing back camera…';
      case DualCaptureState.captureDoneBack:
        return 'Back photo saved';
      case DualCaptureState.initializingFront:
        return 'Starting front camera…';
      case DualCaptureState.readyFront:
        return 'Front camera ready';
      case DualCaptureState.capturingFront:
        return 'Capturing front camera…';
      case DualCaptureState.compositing:
        return 'Compositing image…';
      case DualCaptureState.done:
        return 'Done!';
      case DualCaptureState.error:
        return 'Error';
    }
  }

  Future<void> _onShutter() async {
    DualCaptureResult? result;
    try {
      result = await _controller.capture();
    } catch (_) {
      // Error state is reflected on the controller; let the UI update.
    }
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          final busy = _controller.isBusy;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview.
              DualCapturePreview(controller: _controller),

              // Dim overlay when pipeline is busy.
              if (busy)
                const ColoredBox(color: Color(0x66000000)),

              // Status banner.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: const Color(0x88000000),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _stateLabel(state),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Spinner during compositing / initialising.
              if (state == DualCaptureState.compositing ||
                  state == DualCaptureState.initializingBack ||
                  state == DualCaptureState.initializingFront)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Close button.
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

              // Shutter button + hint (only when ready for back camera).
              if (state == DualCaptureState.readyBack)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Back camera → front camera',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _onShutter,
                          child: Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
