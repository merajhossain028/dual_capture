import 'dart:io';

import 'package:dual_capture/dual_capture.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DualCaptureExampleApp());
}

class DualCaptureExampleApp extends StatelessWidget {
  const DualCaptureExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dual_capture example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dual_capture demos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoTile(
            title: 'Quick capture',
            subtitle: 'Default options — tap to capture.',
            onTap: () async {
              final result = await DualCapture.capture(context);
              if (result != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultPage(result: result),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _DemoTile(
            title: 'Custom options',
            subtitle: 'All options explicitly set.',
            onTap: () async {
              final result = await DualCapture.capture(
                context,
                options: const DualCaptureOptions(
                  overlayPosition: OverlayPosition.topLeft,
                  overlayScale: 0.25,
                  jpegQuality: 90,
                  overlayMargin: 20,
                  flipFrontCamera: true,
                  overlayBorder: OverlayBorder(
                    color: Color(0xFF6C63FF),
                    width: 3.0,
                    cornerRadius: 16.0,
                  ),
                  frontCameraWarmupDelay: Duration(milliseconds: 700),
                ),
              );
              if (result != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultPage(result: result),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _DemoTile(
            title: 'Embedded preview',
            subtitle: 'Controller owned by a page, not a route.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EmbeddedPreviewPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result page
// ---------------------------------------------------------------------------

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result});

  final DualCaptureResult result;

  String _fileInfo(File f) {
    try {
      final kb = (f.lengthSync() / 1024).toStringAsFixed(1);
      return '${f.uri.pathSegments.last} ($kb KB)';
    } catch (_) {
      return f.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(result.compositedFile),
            ),
            const SizedBox(height: 16),
            Text('Composited', style: Theme.of(context).textTheme.labelLarge),
            Text(_fileInfo(result.compositedFile)),
            const SizedBox(height: 8),
            Text('Back camera', style: Theme.of(context).textTheme.labelLarge),
            Text(_fileInfo(result.backCameraFile)),
            const SizedBox(height: 8),
            Text('Front camera', style: Theme.of(context).textTheme.labelLarge),
            Text(_fileInfo(result.frontCameraFile)),
            const SizedBox(height: 8),
            Text('Captured at', style: Theme.of(context).textTheme.labelLarge),
            Text(result.capturedAt.toIso8601String()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Embedded preview page
// ---------------------------------------------------------------------------

class EmbeddedPreviewPage extends StatefulWidget {
  const EmbeddedPreviewPage({super.key});

  @override
  State<EmbeddedPreviewPage> createState() => _EmbeddedPreviewPageState();
}

class _EmbeddedPreviewPageState extends State<EmbeddedPreviewPage> {
  late final DualCaptureController _controller;
  DualCaptureResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = DualCaptureController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final result = await _controller.capture();
      if (mounted) setState(() => _result = result);
    } catch (_) {
      // Error state shown via DualCapturePreview.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embedded preview')),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: _result != null
                  ? Image.file(_result!.compositedFile, fit: BoxFit.cover)
                  : DualCapturePreview(controller: _controller),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => Chip(
                      label: Text(_controller.state.name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _controller.state == DualCaptureState.readyBack
                          ? _capture
                          : null,
                      child: const Text('Capture'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
