import 'content_pack.dart';

class CodeRunResult {
  const CodeRunResult({
    required this.stdout,
    this.stderr = '',
    this.timedOut = false,
    this.executionError,
  });

  final String stdout;
  final String stderr;
  final bool timedOut;
  final String? executionError;
}

class AnswerEvaluation {
  const AnswerEvaluation({
    required this.isCorrect,
    required this.message,
    this.similarity = 0,
  });

  final bool isCorrect;
  final String message;
  final double similarity;
}

/// Deterministic evaluator. It never calls or trusts an LLM for correctness.
class AnswerEvaluator {
  const AnswerEvaluator({this.shortAnswerThreshold = .70});

  final double shortAnswerThreshold;

  AnswerEvaluation evaluate(
    PracticalItem item,
    String response, {
    CodeRunResult? runResult,
  }) {
    switch (item.type) {
      case 'yesNo':
      case 'multipleChoice':
        final correct = _normalize(response) == _normalize(item.answer ?? '');
        return AnswerEvaluation(
          isCorrect: correct,
          message: correct
              ? 'That is correct.'
              : 'Not quite. Review the lesson and try again.',
        );
      case 'shortAnswer':
        final expected = _tokens(item.answer ?? '');
        final actual = _tokens(response);
        final similarity = _dice(expected, actual);
        final hasRequiredKeywords = item.requiredKeywords.every(
          (word) => actual.containsAll(_tokens(word)),
        );
        final correct =
            similarity >= shortAnswerThreshold && hasRequiredKeywords;
        return AnswerEvaluation(
          isCorrect: correct,
          similarity: similarity,
          message: correct
              ? 'That covers the key idea.'
              : 'Try again and include the key idea from the lesson.',
        );
      case 'code':
      case 'fixTheBug':
        if (runResult == null) {
          return const AnswerEvaluation(
            isCorrect: false,
            message: 'Run your code to check it.',
          );
        }
        final correct =
            !runResult.timedOut &&
            runResult.executionError == null &&
            runResult.stderr.isEmpty &&
            _normalize(runResult.stdout) == _normalize(_expectedOutput(item));
        return AnswerEvaluation(
          isCorrect: correct,
          message: correct
              ? 'Your program passed the check.'
              : 'Your program has not passed the check yet.',
        );
      default:
        return const AnswerEvaluation(
          isCorrect: false,
          message: 'This question type is not supported.',
        );
    }
  }

  String _expectedOutput(PracticalItem item) {
    final test = item.tests.isEmpty ? null : item.tests.first;
    return test?['stdout']?.toString() ?? '';
  }

  String _normalize(String value) =>
      value.trim().replaceAll('\r\n', '\n').toLowerCase();

  Set<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toSet();

  double _dice(Set<String> expected, Set<String> actual) {
    if (expected.isEmpty && actual.isEmpty) return 1;
    if (expected.isEmpty || actual.isEmpty) return 0;
    final overlap = expected.intersection(actual).length;
    final dice = (2 * overlap) / (expected.length + actual.length);
    // Brief answers can add surrounding words without changing the meaning.
    final keyPhraseCoverage = overlap / expected.length;
    return dice > keyPhraseCoverage * .8 ? dice : keyPhraseCoverage * .8;
  }
}
