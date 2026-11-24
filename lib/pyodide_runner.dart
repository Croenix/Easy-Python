import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'answer_evaluator.dart';

class PyodideRunner extends StatefulWidget {
  const PyodideRunner({super.key, this.onReady});
  final ValueChanged<bool>? onReady;

  @override
  PyodideRunnerState createState() => PyodideRunnerState();
}

class PyodideRunnerState extends State<PyodideRunner> {
  late final WebViewController _controller;
  final Completer<void> _ready = Completer<void>();
  Completer<CodeRunResult>? _pending;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('EasyPython', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url.startsWith('file:') ||
                  request.url.startsWith('about:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      android.setAllowFileAccess(true);
      android.setAllowContentAccess(true);
    }
    _controller = controller..loadFlutterAsset('assets/pyodide/worker.html');
  }

  Future<CodeRunResult> run(
    String source, {
    List<String> inputs = const [],
  }) async {
    if (!_ready.isCompleted) {
      try {
        await _ready.future.timeout(const Duration(seconds: 20));
      } on TimeoutException {
        return const CodeRunResult(
          stdout: '',
          executionError: 'The offline Python runtime is still loading.',
        );
      }
    }
    if (_pending != null) {
      return const CodeRunResult(
        stdout: '',
        executionError: 'A Python run is already in progress.',
      );
    }
    final id = ++_nextId;
    final completer = Completer<CodeRunResult>();
    _pending = completer;
    final payload = jsonEncode([id, source, inputs]);
    await _controller.runJavaScript('''
      const args = JSON.parse(${jsonEncode(payload)});
      window.runPython(args[0], args[1], args[2]);
    ''');
    try {
      return await completer.future.timeout(
        const Duration(milliseconds: 3500),
        onTimeout: () => const CodeRunResult(
          stdout: '',
          timedOut: true,
          executionError: 'Your code took longer than 3 seconds.',
        ),
      );
    } finally {
      if (identical(_pending, completer)) _pending = null;
    }
  }

  void _handleMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['type'] == 'ready') {
        if (!_ready.isCompleted) _ready.complete();
        widget.onReady?.call(true);
        return;
      }
      if (data['type'] == 'workerError') {
        widget.onReady?.call(false);
        return;
      }
      if (data['type'] != 'result' ||
          _pending == null ||
          _pending!.isCompleted) {
        return;
      }
      _pending!.complete(
        CodeRunResult(
          stdout: data['stdout'] as String? ?? '',
          stderr: data['stderr'] as String? ?? '',
          timedOut: data['timedOut'] == true,
          executionError: data['error'] as String?,
        ),
      );
    } catch (_) {
      if (_pending != null && !_pending!.isCompleted) {
        _pending!.complete(
          const CodeRunResult(
            stdout: '',
            executionError: 'Invalid runner response.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 1,
    height: 1,
    child: WebViewWidget(controller: _controller),
  );
}
