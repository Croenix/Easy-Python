import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/answer_evaluator.dart';
import 'package:pypath/content_pack.dart';
import 'package:pypath/supernova_ai.dart';

void main() {
  const supernova = SupernovaEngine();

  group('SupernovaEngine - Practical Submission Diagnostics', () {
    test('analyzes multiple choice question correctly', () {
      const item = PracticalItem(
        id: 'q1',
        type: 'multipleChoice',
        prompt: 'Which keyword creates a function?',
        answer: 'def',
        options: ['def', 'fun', 'function', 'define'],
      );

      final pass = supernova.analyzeSubmission(
        question: item,
        userResponse: 'def',
        userName: 'Achu',
      );
      expect(pass.isCorrect, isTrue);
      expect(pass.headline, contains('Achu'));

      final fail = supernova.analyzeSubmission(
        question: item,
        userResponse: 'fun',
        userName: 'Achu',
      );
      expect(fail.isCorrect, isFalse);
      expect(fail.headline, contains('Achu'));
    });

    test('diagnoses Python SyntaxError when colon is missing', () {
      const item = PracticalItem(
        id: 'q2',
        type: 'code',
        prompt: 'Define a function called hello that prints hi.',
        tests: [
          {'stdout': 'hi\n'},
        ],
      );

      final analysis = supernova.analyzeSubmission(
        question: item,
        userResponse: 'def hello()\n    print("hi")',
        userName: 'Achu',
        runResult: const CodeRunResult(
          stdout: '',
          stderr: 'SyntaxError: expected ":"',
        ),
      );

      expect(analysis.isCorrect, isFalse);
      expect(analysis.headline, contains('Syntax Alert'));
      expect(analysis.explanation, contains('trailing colon'));
    });

    test('diagnoses TypeError when combining str and int', () {
      const item = PracticalItem(
        id: 'q3',
        type: 'code',
        prompt: 'Print score and age.',
      );

      final analysis = supernova.analyzeSubmission(
        question: item,
        userResponse: 'print("Score: " + 10)',
        userName: 'Achu',
        runResult: const CodeRunResult(
          stdout: '',
          stderr: 'TypeError: can only concatenate str (not "int") to str',
        ),
      );

      expect(analysis.isCorrect, isFalse);
      expect(analysis.headline, contains('Type Mismatch'));
      expect(analysis.explanation, contains('Convert numbers using `str()`'));
    });

    test('diagnoses tuple vs list misconception when output is empty/wrong', () {
      const item = PracticalItem(
        id: 'q4',
        type: 'code',
        prompt: 'Create a list of fruits and print it.',
        tests: [
          {'stdout': "['apple', 'banana']\n"},
        ],
      );

      final analysis = supernova.analyzeSubmission(
        question: item,
        userResponse: 'fruits = ("apple", "banana")\nprint(fruits)',
        userName: 'Achu',
        runResult: const CodeRunResult(
          stdout: "('apple', 'banana')",
        ),
      );

      expect(analysis.isCorrect, isFalse);
      expect(analysis.explanation, contains('Tuple'));
      expect(analysis.cosmicTip, contains('square brackets'));
    });
  });

  group('SupernovaEngine - Conversational AI & Streaming', () {
    test('generates topic explanation for decorators', () {
      final reply = supernova.generateResponse(
        prompt: 'Can you explain decorators?',
        userName: 'Achu',
      );
      expect(reply, contains('Hey Achu!'));
      expect(reply, contains('@my_decorator'));
    });

    test('streams chat tokens smoothly', () async {
      final chunks = <String>[];
      await for (final token in supernova.streamChat(
        prompt: 'What is the difference between list and tuple?',
        userName: 'Achu',
      )) {
        chunks.add(token);
      }
      expect(chunks, isNotEmpty);
      final fullText = chunks.join('');
      expect(fullText, contains('Lists'));
      expect(fullText, contains('Tuples'));
    });
  });
}
