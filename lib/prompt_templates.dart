import 'package:flutter/services.dart';

class PromptTemplates {
  PromptTemplates({AssetBundle? assetBundle})
    : _assets = assetBundle ?? rootBundle;

  final AssetBundle _assets;

  Future<String> tutorSystem({
    required String learnerName,
    required String buddyName,
    required String language,
    required String learnerPreference,
  }) async => (await _assets.loadString('assets/prompts/tutor_system.txt'))
      .replaceAll('{{learner_name}}', learnerName)
      .replaceAll('{{buddy_name}}', buddyName)
      .replaceAll('{{language}}', language)
      .replaceAll('{{learner_preference}}', learnerPreference);

  Future<String> answerFeedback() =>
      _assets.loadString('assets/prompts/answer_feedback.txt');

  Future<String> chatbot({
    required String learnerName,
    required String buddyName,
  }) async => (await _assets.loadString('assets/prompts/chatbot.txt'))
      .replaceAll('{{learner_name}}', learnerName)
      .replaceAll('{{buddy_name}}', buddyName);
}
