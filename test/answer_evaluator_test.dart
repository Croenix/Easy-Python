import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/answer_evaluator.dart';
import 'package:pypath/content_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const evaluator = AnswerEvaluator();

  late ContentPack pack;
  setUpAll(() async {
    pack = await ContentPackLoader().load('assets/content/en/python-v1.json');
  });

  test('checks multiple choice and yes/no answers deterministically', () {
    final task = pack.tasks.first;
    expect(
      evaluator.evaluate(task.practicals[0], 'print("Hi")').isCorrect,
      isTrue,
    );
    expect(
      evaluator.evaluate(task.practicals[0], 'show("Hi")').isCorrect,
      isFalse,
    );
    expect(evaluator.evaluate(task.practicals[1], 'YES').isCorrect, isTrue);
  });

  test('short answers need the similarity threshold and required keywords', () {
    final item = pack.tasks[1].practicals[1];
    final accepted = evaluator.evaluate(
      item,
      'Check the output after running it.',
    );
    final rejected = evaluator.evaluate(
      item,
      'Check the display after it starts.',
    );
    expect(accepted.similarity, greaterThanOrEqualTo(.70));
    expect(accepted.isCorrect, isTrue);
    expect(rejected.isCorrect, isFalse);
  });

  test('code correctness comes from runner output, not answer text', () {
    final item = pack.tasks.first.practicals[2];
    expect(evaluator.evaluate(item, 'anything').isCorrect, isFalse);
    expect(
      evaluator
          .evaluate(
            item,
            'print("Ready to learn!")',
            runResult: const CodeRunResult(stdout: 'Ready to learn!\n'),
          )
          .isCorrect,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(
            item,
            'print("Ready to learn!")',
            runResult: const CodeRunResult(stdout: '', timedOut: true),
          )
          .isCorrect,
      isFalse,
    );
  });
}
