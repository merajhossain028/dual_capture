# dual_capture

Capture back and front camera in one tap. The two shots are composited into a single JPEG with a picture-in-picture overlay — you get the composited image plus both raw files.

## Features

- One-call API: `DualCapture.capture(context)`
- Back → front sequential pipeline with automatic camera switching
- Picture-in-picture overlay at any corner (bottom-right, bottom-left, top-right, top-left)
- Configurable overlay size, margin, JPEG quality, and front-camera flip
- Optional rounded-corner border around the overlay
- Compositing runs in a background isolate (no UI jank)
- Embedded preview support via `DualCaptureController` + `DualCapturePreview`

## Platform setup

### iOS

Add the following entries to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>dual_capture needs camera access to take photos.</string>
```

### Android

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Getting started

```yaml
dependencies:
  dual_capture: ^0.1.0
```

## Usage

### One-shot capture

```dart
import 'package:dual_capture/dual_capture.dart';

final result = await DualCapture.capture(context);
if (result != null) {
  // result.compositedFile  — back + front composited JPEG
  // result.backCameraFile  — raw back-camera JPEG
  // result.frontCameraFile — raw front-camera JPEG
  // result.capturedAt      — UTC DateTime
}
```

### Custom options

```dart
final result = await DualCapture.capture(
  context,
  options: const DualCaptureOptions(
    overlayPosition: OverlayPosition.topLeft,
    overlayScale: 0.25,
    jpegQuality: 90,
    overlayBorder: OverlayBorder(
      color: Color(0xFF6C63FF),
      width: 3.0,
      cornerRadius: 16.0,
    ),
  ),
);
```

### Embedded preview (controller API)

```dart
class _MyState extends State<MyPage> {
  late final DualCaptureController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DualCaptureController();
    _ctrl.initialize();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: DualCapturePreview(controller: _ctrl)),
        ElevatedButton(
          onPressed: _ctrl.state == DualCaptureState.readyBack
              ? () async {
                  final result = await _ctrl.capture();
                  // use result …
                }
              : null,
          child: const Text('Capture'),
        ),
      ],
    );
  }
}
```

## API

| Class / member | Description |
|---|---|
| `DualCapture.capture(context, {options})` | Pushes capture UI, returns `DualCaptureResult?` |
| `DualCaptureController` | Manages the pipeline; extends `ChangeNotifier` |
| `DualCaptureController.initialize()` | Opens back camera |
| `DualCaptureController.capture()` | Runs full pipeline, returns result |
| `DualCaptureController.state` | Current `DualCaptureState` |
| `DualCapturePreview` | `Widget` that shows the live camera feed |
| `DualCaptureScreen` | Full-screen camera UI (used internally by `DualCapture.capture`) |
| `DualCaptureOptions` | All capture settings in one object |
| `DualCaptureResult` | Holds the three output files + timestamp |
| `OverlayPosition` | Enum: `bottomRight`, `bottomLeft`, `topRight`, `topLeft` |
| `OverlayBorder` | Optional border around the PiP overlay |
| `DualCaptureException` | Thrown when the pipeline encounters an error |

## How it works

```
┌─────────────────────────────────────────────────────┐
│ 1. Open back camera → show preview                  │
│ 2. User taps shutter → takePicture() (back)         │
│ 3. Dispose back controller (iOS race-condition fix) │
│ 4. Open front camera → warm-up delay → takePicture()│
│ 5. Dispose front controller                         │
│ 6. Background isolate:                              │
│    a. Decode both JPEGs                             │
│    b. Resize front to overlayScale × back width     │
│    c. Optionally flip front horizontally            │
│    d. Apply rounded corners + optional border       │
│    e. Composite onto back image at chosen corner    │
│    f. Encode result as JPEG                         │
│ 7. Return DualCaptureResult                         │
└─────────────────────────────────────────────────────┘
```

## Contributing

PRs and issues welcome at the [issue tracker](https://github.com/merajhossain028/dual_capture/issues).
