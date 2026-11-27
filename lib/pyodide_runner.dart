import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'answer_evaluator.dart';

class _LocalPyodideServer {
  static _LocalPyodideServer? _instance;
  static Future<_LocalPyodideServer> get instance async =>
      _instance ??= await _LocalPyodideServer._start();

  final HttpServer _server;
  final int port;

  _LocalPyodideServer._(this._server, this.port);

  Future<void> close({bool force = false}) => _server.close(force: force);

  static Future<_LocalPyodideServer> _start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final response = request.response;
      response.headers.add('Access-Control-Allow-Origin', '*');
      response.headers.add(
        'Access-Control-Allow-Methods',
        'GET, HEAD, OPTIONS',
      );
      response.headers.add('Cross-Origin-Opener-Policy', 'same-origin');
      response.headers.add('Cross-Origin-Embedder-Policy', 'require-corp');

      if (request.method == 'OPTIONS') {
        response.statusCode = HttpStatus.ok;
        await response.close();
        return;
      }

      try {
        var rawPath = request.uri.path;
        if (rawPath.startsWith('/')) rawPath = rawPath.substring(1);
        final assetPath = Uri.decodeComponent(rawPath);

        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        if (assetPath.endsWith('.html')) {
          response.headers.contentType = ContentType.html;
        } else if (assetPath.endsWith('.js')) {
          response.headers.contentType = ContentType(
            'application',
            'javascript',
            charset: 'utf-8',
          );
        } else if (assetPath.endsWith('.wasm')) {
          response.headers.contentType = ContentType('application', 'wasm');
        } else if (assetPath.endsWith('.json')) {
          response.headers.contentType = ContentType.json;
        } else if (assetPath.endsWith('.zip')) {
          response.headers.contentType = ContentType('application', 'zip');
        } else {
          response.headers.contentType = ContentType.binary;
        }

        response.contentLength = bytes.length;
        response.add(bytes);
      } catch (_) {
        response.statusCode = HttpStatus.notFound;
        response.write('Asset not found');
      } finally {
        await response.close();
      }
    });

    return _LocalPyodideServer._(server, server.port);
  }
}

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
  String? _initializationError;

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
                  request.url.startsWith('about:') ||
                  request.url.startsWith('http://127.0.0.1:') ||
                  request.url.startsWith('http://localhost:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      android.setAllowFileAccess(true);
      android.setAllowContentAccess(true);
    }
    _controller = controller;
    _startAndLoad();
  }

  Future<void> _startAndLoad() async {
    try {
      final server = await _LocalPyodideServer.instance;
      if (!mounted) return;
      await _controller.loadRequest(
        Uri.parse('http://127.0.0.1:${server.port}/assets/pyodide/worker.html'),
      );
    } catch (_) {
      if (mounted) {
        try {
          await _controller.loadFlutterAsset('assets/pyodide/worker.html');
        } catch (error) {
          _markInitializationFailed(
            'Could not load the offline Python runtime: $error',
          );
        }
      }
    }
  }

  void _markInitializationFailed(String message) {
    _initializationError = message;
    if (!_ready.isCompleted) _ready.complete();
    widget.onReady?.call(false);
  }

  Future<CodeRunResult> run(
    String source, {
    List<String> inputs = const [],
    Map<String, String> projectFiles = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!_ready.isCompleted) {
      try {
        await _ready.future.timeout(const Duration(seconds: 25));
      } on TimeoutException {
        return const CodeRunResult(
          stdout: '',
          executionError: 'The offline Python runtime is still loading.',
        );
      }
    }
    if (_initializationError case final error?) {
      return CodeRunResult(stdout: '', executionError: error);
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
    final payload = jsonEncode([
      id,
      source,
      inputs,
      projectFiles,
      timeout.inMilliseconds,
    ]);
    try {
      await _controller.runJavaScript('''
        const args = JSON.parse(${jsonEncode(payload)});
        window.runPython(args[0], args[1], args[2], args[3], args[4]);
      ''');
      return await completer.future.timeout(
        timeout + const Duration(milliseconds: 500),
        onTimeout: () => CodeRunResult(
          stdout: '',
          timedOut: true,
          executionError:
              'Your code took longer than ${timeout.inSeconds} seconds.',
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
        _markInitializationFailed(
          data['error'] as String? ??
              'The offline Python runtime failed to start.',
        );
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
