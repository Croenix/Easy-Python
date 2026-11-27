import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

import 'model_manager.dart';
import 'prompt_templates.dart';
import 'python_teaching_mode.dart';

abstract interface class TutorModel {
  Future<void> load(String modelPath);
  Stream<String> generate({
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
    required double temperature,
  });
  Future<void> unload();
}

class LlamaCppTutorModel implements TutorModel {
  LlamaCppTutorModel({LlamaController? controller})
    : _controller = controller ?? LlamaController();

  LlamaController _controller;

  @override
  Future<void> load(String modelPath) async {
    await _controller.loadModel(
      modelPath: modelPath,
      threads: 4,
      contextSize: 2048,
      gpuLayers: 0,
    );
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
    required double temperature,
  }) => _controller.generateChat(
    messages: [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: userPrompt),
    ],
    template: 'chatml',
    maxTokens: maxTokens,
    temperature: temperature,
    topP: .85,
    topK: 30,
    repeatPenalty: 1.12,
  );

  @override
  Future<void> unload() async {
    await _controller.dispose();
    _controller = LlamaController();
  }
}

/// Swappable offline tutor runtime. The backend explains work; it never scores it.
class OnDeviceTutor {
  OnDeviceTutor({
    TutorModel? model,
    ModelManager? manager,
    PythonTeachingMode? teachingMode,
  }) : _model = model ?? LlamaCppTutorModel(),
       _manager = manager ?? ModelManager(),
       _teachingMode = teachingMode ?? const PythonTeachingMode();

  final TutorModel _model;
  final ModelManager _manager;
  final PythonTeachingMode _teachingMode;
  bool _ready = false;
  ModelSpec? selectedModel;
  bool get isReady => _ready;

  Future<void> prepare({
    required String customInstructions,
    required void Function(double progress) onProgress,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError(
        'The downloaded on-device tutor is available on Android.',
      );
    }
    try {
      final probe = LlamaController();
      final device = await probe.detectGpu();
      await probe.dispose();
      if (device.freeRamBytes > 0 && device.freeRamBytes < 600 * 1024 * 1024) {
        throw StateError(
          'This phone has too little free memory (${(device.freeRamBytes / (1024 * 1024)).round()} MB) for on-device inference.',
        );
      }
      final totalRam = device.deviceLocalMemoryBytes > 0
          ? device.deviceLocalMemoryBytes
          : (device.freeRamBytes > 0
                ? device.freeRamBytes
                : 4 * 1024 * 1024 * 1024);
      selectedModel = totalRam < 4 * 1024 * 1024 * 1024
          ? ModelCatalog.lowMemory
          : ModelCatalog.standard;
      final file = await _manager.download(
        selectedModel!,
        onProgress: onProgress,
      );
      await _model.load(file.path);
      _ready = true;
    } catch (error) {
      throw StateError(
        'Could not prepare the on-device Python buddy. Connect once to download '
        'the selected model, check available storage and memory, then retry. $error',
      );
    }
  }

  Stream<String> ask({
    required String question,
    required int level,
    required String module,
    required List<String> unlockedConcepts,
    required String customInstructions,
    int attempt = 1,
    String preparedExample = '',
    String retrievedLessonContext = '',
    List<String> recentConversation = const [],
    String learnerName = 'friend',
    String buddyName = 'Pixel',
    String language = 'English',
  }) async* {
    if (!_ready) {
      yield* _teachingMode.streamChat(
        prompt: question,
        userName: learnerName,
        currentTopic: module,
        conversationHistory: recentConversation,
      );
      return;
    }
    final concepts = unlockedConcepts.isEmpty
        ? 'None yet; use only the Introduction task.'
        : unlockedConcepts.join(', ');
    final preference = customInstructions.trim().isEmpty
        ? 'Warm, concise, beginner-friendly.'
        : customInstructions.trim();
    final prompt =
        '''Current User Progress: Level $level, Module $module.
Unlocked Concepts: $concepts.
Learner: $learnerName. Buddy: $buddyName.
Attempt: $attempt. Prepared lesson example (use only if a worked example is appropriate): $preparedExample.
Retrieved lesson chunks (use these first): $retrievedLessonContext
Recent conversation (last six messages): ${recentConversation.join('\n')}
Learner Preference: $preference.
User Submission/Question: $question''';
    final raw = StringBuffer();
    var yieldedLength = 0;
    try {
      await for (final token
          in _model
              .generate(
                systemPrompt: await PromptTemplates().tutorSystem(
                  learnerName: learnerName,
                  buddyName: buddyName,
                  language: language,
                  learnerPreference: customInstructions.trim().isEmpty
                      ? 'Warm, concise, beginner-friendly.'
                      : customInstructions.trim(),
                ),
                userPrompt: prompt,
                maxTokens: 220,
                temperature: .4,
              )
              .timeout(const Duration(seconds: 12))) {
        raw.write(token);
        final partial = _messagePrefix(raw.toString());
        if (partial.length > yieldedLength) {
          yield partial.substring(yieldedLength);
          yieldedLength = partial.length;
        }
      }
      final decoded = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final message = decoded['message'];
      if (message is! String || message.trim().isEmpty) {
        throw const FormatException(
          'Tutor response did not match the JSON schema.',
        );
      }
      if (yieldedLength == 0) yield message;
    } catch (_) {
      if (yieldedLength == 0) {
        yield* _teachingMode.streamChat(
          prompt: question,
          userName: learnerName,
          currentTopic: module,
          conversationHistory: recentConversation,
        );
      }
    }
    if (yieldedLength == 0) {
      yield* _teachingMode.streamChat(
        prompt: question,
        userName: learnerName,
        currentTopic: module,
        conversationHistory: recentConversation,
      );
    }
  }

  Future<void> close() async {
    if (Platform.isAndroid && !_ready) {
      await _model.unload();
    } else {
      await unload();
    }
    _manager.close();
  }

  Future<void> unload() async {
    if (!_ready) return;
    _ready = false;
    await _model.unload();
  }

  String _messagePrefix(String value) {
    final marker = RegExp(r'"message"\s*:\s*"').firstMatch(value);
    if (marker == null) return '';
    final output = StringBuffer();
    var escaped = false;
    for (var i = marker.end; i < value.length; i++) {
      final char = value[i];
      if (escaped) {
        output.write(switch (char) {
          'n' => '\n',
          'r' => '\r',
          't' => '\t',
          _ => char,
        });
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '"') {
        break;
      } else {
        output.write(char);
      }
    }
    return output.toString();
  }
}

class PreparedHintFallback {
  static String forQuestion(
    String question, {
    int attempt = 1,
    String preparedExample = '',
  }) {
    if (attempt == 3 && preparedExample.isNotEmpty) {
      return 'Here is a small worked example from this task:\n$preparedExample';
    }
    if (attempt >= 4 && preparedExample.isNotEmpty) {
      return 'Let’s walk through this task with a worked example:\n$preparedExample';
    }
    final lower = question.toLowerCase();
    if (lower.contains('quote') || lower.contains('parenth')) {
      return attempt < 2
          ? 'Quick hint: look for a pair of symbols that should match.'
          : 'Check that each opening quote and parenthesis has a matching closing one.';
    }
    if (lower.contains('indent') || lower.contains('syntax')) {
      return 'Quick hint: compare the line with the example and check the exact line named by the error.';
    }
    if (lower.contains('variable') || lower.contains('name')) {
      return 'Quick hint: give the value a clear name, then use that name where you need the value.';
    }
    if (lower.contains('list') || lower.contains('fruit')) {
      return 'Quick hint: a list keeps several values together. Check the current task for the syntax it has unlocked.';
    }
    return 'Quick hint: break the problem into one small step, then compare your code with the current lesson example.';
  }
}
