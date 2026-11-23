import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/personalization.dart';

void main() {
  test('difficulty rises after three correct answers and falls after two wrong', () {
    final state = PersonalizationState(difficulty: 2);
    for (var i = 0; i < 3; i++) {
      PersonalizationEngine.recordAnswer(state, topicId: 'syntax', correct: true);
    }
    expect(state.difficulty, 3);
    PersonalizationEngine.recordAnswer(state, topicId: 'syntax', correct: false);
    PersonalizationEngine.recordAnswer(state, topicId: 'syntax', correct: false);
    expect(state.difficulty, 2);
  });

  test('mastery weights recent answers and adds weak topics to revision', () {
    final state = PersonalizationState();
    PersonalizationEngine.recordAnswer(state, topicId: 'lists', correct: true);
    PersonalizationEngine.recordAnswer(state, topicId: 'lists', correct: false);
    PersonalizationEngine.recordAnswer(state, topicId: 'lists', correct: false);
    expect(state.mastery('lists'), lessThan(.60));
    expect(state.revisionQueue, contains('lists'));
    expect(PersonalizationEngine.mastery([0, 1]), greaterThan(.60));
  });

  test('pacing, finish estimate, start point, and completion use handoff rules', () {
    expect(PersonalizationEngine.lessonsPerDay('30 min'), 2);
    expect(
      PersonalizationEngine.estimatedFinishDate(
        from: DateTime(2026, 1, 1),
        remainingLessons: 12,
        dailyTime: '30 min',
      ),
      DateTime(2026, 1, 8),
    );
    expect(PersonalizationEngine.startIndexForLevel('Intermediate'), 8);
    expect(
      PersonalizationEngine.taskComplete(
        lessonRead: true,
        practicalsAttempted: true,
        topicMastery: .7,
      ),
      isTrue,
    );
  });
}
