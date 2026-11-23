class PersonalizationState {
  PersonalizationState({
    this.difficulty = 1,
    this.correctStreak = 0,
    this.wrongStreak = 0,
    Map<String, List<int>> topicAttempts = const {},
    Set<String> revisionQueue = const {},
  }) : topicAttempts = topicAttempts.map(
         (key, value) => MapEntry(key, List<int>.of(value)),
       ),
       revisionQueue = Set<String>.of(revisionQueue);

  int difficulty;
  int correctStreak;
  int wrongStreak;
  final Map<String, List<int>> topicAttempts;
  final Set<String> revisionQueue;

  double mastery(String topicId) =>
      PersonalizationEngine.mastery(topicAttempts[topicId] ?? const []);
}

class PersonalizationEngine {
  const PersonalizationEngine._();

  static void recordAnswer(
    PersonalizationState state, {
    required String topicId,
    required bool correct,
  }) {
    final attempts = state.topicAttempts.putIfAbsent(topicId, () => []);
    attempts.add(correct ? 1 : 0);
    if (attempts.length > 10) attempts.removeAt(0);

    if (correct) {
      state.correctStreak++;
      state.wrongStreak = 0;
      if (state.correctStreak >= 3) {
        state.difficulty = (state.difficulty + 1).clamp(1, 5);
        state.correctStreak = 0;
      }
    } else {
      state.wrongStreak++;
      state.correctStreak = 0;
      if (state.wrongStreak >= 2) {
        state.difficulty = (state.difficulty - 1).clamp(1, 5);
        state.wrongStreak = 0;
      }
    }

    final score = state.mastery(topicId);
    if (attempts.length >= 3 && score < .60) {
      state.revisionQueue.add(topicId);
    } else if (score >= .70) {
      state.revisionQueue.remove(topicId);
    }
  }

  static double mastery(List<int> attempts) {
    if (attempts.isEmpty) return 0;
    final recent = attempts.length <= 10
        ? attempts
        : attempts.sublist(attempts.length - 10);
    var weightedCorrect = 0;
    var totalWeight = 0;
    for (var index = 0; index < recent.length; index++) {
      final weight = index + 1;
      weightedCorrect += recent[index] * weight;
      totalWeight += weight;
    }
    return totalWeight == 0 ? 0 : weightedCorrect / totalWeight;
  }

  static int lessonsPerDay(String dailyTime) {
    final minutes = int.tryParse(dailyTime.replaceAll(RegExp(r'\D'), '')) ?? 12;
    return (minutes ~/ 12).clamp(1, 100);
  }

  static DateTime estimatedFinishDate({
    required DateTime from,
    required int remainingLessons,
    required String dailyTime,
  }) {
    final perDay = lessonsPerDay(dailyTime);
    final studyDays = (remainingLessons / perDay).ceil();
    final calendarDays = (studyDays * 7 / 6).ceil();
    return from.add(Duration(days: calendarDays));
  }

  static int startIndexForLevel(String level) => switch (level) {
    'Intermediate' => 8,
    'Advanced' => 12,
    _ => 0,
  };

  static int startingDifficulty(String level) => switch (level) {
    'Intermediate' => 3,
    'Advanced' => 4,
    _ => 1,
  };

  static bool taskComplete({
    required bool lessonRead,
    required bool practicalsAttempted,
    required double topicMastery,
  }) =>
      lessonRead && practicalsAttempted && topicMastery >= .70;
}
