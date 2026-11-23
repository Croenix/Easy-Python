import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/on_device_tutor.dart';
import 'package:pypath/prompt_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tutor prompt is editable and fills the learner and buddy context',
    () async {
      final prompt = await PromptTemplates().tutorSystem(
        learnerName: 'Mira',
        buddyName: 'Pixel',
      language: 'Malayalam',
        learnerPreference: 'Use short examples.',
      );

      expect(prompt, contains('Pixel'));
      expect(prompt, contains('Mira'));
    expect(prompt, contains('Reply in Malayalam'));
      expect(prompt, contains('Use short examples.'));
      expect(prompt, contains('Never decide whether an answer is correct'));
    },
  );

  test('prepared hints progress from nudge to worked example', () {
    final attemptOne = PreparedHintFallback.forQuestion(
      'missing quote',
      attempt: 1,
    );
    final attemptTwo = PreparedHintFallback.forQuestion(
      'missing quote',
      attempt: 2,
    );
    final attemptThree = PreparedHintFallback.forQuestion(
      'missing quote',
      attempt: 3,
      preparedExample: 'print("Hi")',
    );

    expect(attemptOne, contains('look for a pair'));
    expect(attemptTwo, contains('matching closing one'));
    expect(attemptThree, contains('print("Hi")'));
  });
}
