import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'answer_evaluator.dart';
import 'design_system.dart';
import 'content_pack.dart';
import 'lesson_content.dart';
import 'lesson_retriever.dart';
import 'on_device_tutor.dart';
import 'personalization.dart';
import 'pyodide_runner.dart';
import 'python_ide_screen.dart';
import 'python_teaching_mode.dart';

const ink = AppColors.ink;
const primary = AppColors.blue;
const accent = AppColors.orange;
const coral = AppColors.coral;
const success = AppColors.green;
const error = AppColors.danger;
const streakColor = AppColors.orange;
const surface = AppColors.lightBackground;
const codeColor = AppColors.code;
ContentPack? activeContentPack;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PyPathApp());
}

class PyPathApp extends StatefulWidget {
  const PyPathApp({super.key});

  @override
  State<PyPathApp> createState() => _PyPathAppState();
}

class _PyPathAppState extends State<PyPathApp> {
  final learner = LearnerState();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([learner.load(), _loadContentPack()]).then((_) {
      if (mounted) setState(() => ready = true);
    });
  }

  Future<void> _loadContentPack() async {
    try {
      activeContentPack = await ContentPackLoader().load(
        'assets/content/en/python-v1.json',
      );
      lessonGuides.addAll(activeContentPack!.guides);
    } catch (_) {
      // Keep the bundled legacy lessons usable if a local pack is damaged.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Python',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: learner.themeMode,
      home: !ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : learner.onboarded
          ? MainShell(learner: learner, onChanged: () => setState(() {}))
          : WelcomeScreen(learner: learner, onDone: () => setState(() {})),
    );
  }
}

class Lesson {
  const Lesson(
    this.id,
    this.title,
    this.module,
    this.minutes,
    this.summary,
    this.example, {
    this.completed = false,
  });
  final String id;
  final String title;
  final String module;
  final int minutes;
  final String summary;
  final String example;
  final bool completed;
}

const lessons = <Lesson>[
  Lesson(
    'L1-01',
    'Introduction',
    'Getting started',
    5,
    'Python is a language for giving clear instructions to a computer. You can use it to automate small tasks, explore data, or build apps.',
    'print("Hello, Python!")',
  ),
  Lesson(
    'L1-02',
    'Get Started',
    'Getting started',
    5,
    'A program is a set of instructions. Python reads your code and runs each instruction in order.',
    'print("Good morning, Asha!")',
  ),
  Lesson(
    'L1-03',
    'Syntax',
    'Getting started',
    6,
    'A comment is a note for people reading your code. Start it with #. Python skips that line when it runs your program.',
    '# Welcome message\nprint("You can do this!")',
  ),
  Lesson(
    'L1-04',
    'Save a value in a variable',
    'Variables and data',
    7,
    'A variable gives a value a useful name. Choose names that tell you what the value represents.',
    'name = "Asha"\nprint(name)',
  ),
  Lesson(
    'L1-05',
    'Work with numbers',
    'Variables and data',
    7,
    'Python can add, subtract, multiply, and divide numbers. Use ** for powers and // for whole-number division.',
    'minutes = 25\nprint(minutes + 5)',
  ),
  Lesson(
    'L1-06',
    'Join text with f-strings',
    'Variables and data',
    7,
    'An f-string places variable values inside a sentence. Put f before the quote and wrap each variable in braces.',
    'name = "Asha"\nprint(f"Welcome, {name}!")',
  ),
  Lesson(
    'L1-07',
    'Choose the right data type',
    'Variables and data',
    7,
    'Text is a str, whole numbers are int, decimal numbers are float, and True or False values are bool.',
    'age = 21\nprint(type(age).__name__)',
  ),
  Lesson(
    'L1-08',
    'Compare values',
    'Decisions',
    7,
    'Comparisons answer a yes-or-no question. They produce True or False. Use == to compare and = to assign.',
    'temperature = 18\nprint(temperature < 20)',
  ),
  Lesson(
    'L1-09',
    'Make a decision with if',
    'Decisions',
    8,
    'An if statement runs an indented block only when its condition is true. Indentation shows which lines belong together.',
    'rainy = True\nif rainy:\n    print("Take an umbrella")',
  ),
  Lesson(
    'L1-10',
    'Add another choice',
    'Decisions',
    8,
    'Use elif for another condition and else for the fallback. Python stops at the first matching branch.',
    'score = 82\nif score >= 80:\n    print("Great work!")\nelse:\n    print("Keep practicing")',
  ),
  Lesson(
    'L1-11',
    'Combine conditions',
    'Decisions',
    8,
    'Use and when both conditions must be true, or when either can be true, and not to reverse a condition.',
    'age = 19\nhas_ticket = True\nprint(age >= 18 and has_ticket)',
  ),
  Lesson(
    'L1-12',
    'Repeat with for',
    'Loops',
    8,
    'A for loop repeats its indented block for each item in a sequence. It is a good fit when you know what to loop over.',
    'for day in ["Mon", "Tue", "Wed"]:\n    print(day)',
  ),
  Lesson(
    'L1-13',
    'Count with range',
    'Loops',
    8,
    'range(stop) counts from zero up to, but not including, stop. Add a start value when counting from somewhere else.',
    'for number in range(1, 4):\n    print(number)',
  ),
  Lesson(
    'L1-14',
    'Repeat with while',
    'Loops',
    9,
    'A while loop repeats while its condition is true. Update the condition inside the loop so it can eventually stop.',
    'tries = 0\nwhile tries < 3:\n    print("Try again")\n    tries += 1',
  ),
  Lesson(
    'L1-15',
    'Control a loop',
    'Loops',
    8,
    'Use break to stop a loop early and continue to skip to the next turn. Keep loop control easy to follow.',
    'for number in range(1, 6):\n    if number == 4:\n        break\n    print(number)',
  ),
  Lesson(
    'L1-16',
    'Plan a guessing game',
    'Loops',
    10,
    'A guessing game combines input, decisions, and repetition. First make a clear plan: choose a secret number, ask, compare, and repeat.',
    'secret = 7\nguess = 5\nif guess < secret:\n    print("Try a higher number")',
  ),
];

enum TaskStatus { locked, current, completed, quickReview }

class LearnerState extends ChangeNotifier {
  static const storageKey = 'pypath.mobile.v1';
  bool onboarded = false;
  String username = 'friend';
  String get name => username;
  ThemeMode themeMode = ThemeMode.system;
  String goal = 'Just curious';
  String dailyTime = '30 min';
  String experience = 'New';
  String ageRange = '18–24';
  String qualification = 'Undergraduate';
  String referralSource = 'Search';
  String hasCodedBefore = 'No';
  String pythonLevel = 'Beginner';
  String learningStyle = 'Hands-on';
  String language = 'English';
  String buddyName = 'Python Coach';
  String tutorInstructions = '';
  String selectedStage4Track = 'web';
  final Set<String> quickReviewTasks = {};
  final adaptation = PersonalizationState();
  int xp = 0;
  int streak = 0;
  int selectedLesson = 0;
  String? lastActivityDay;
  String? streakFreezeWeek;
  final Set<String> completed = {};
  final Set<String> readLessons = {};
  final Set<String> attemptedPracticals = {};
  final Set<String> answeredPracticalQuestions = {};
  final Set<String> passedPracticalQuestions = {};
  final Set<String> completedExercises = {};
  final Set<String> seenReviews = {};
  final Map<String, int> failures = {};

  String get rank => xp >= 8000
      ? 'Master'
      : xp >= 4000
      ? 'Engineer'
      : xp >= 1500
      ? 'Developer'
      : xp >= 500
      ? 'Coder'
      : 'Newbie';
  double masteryFor(String topicId) => adaptation.mastery(topicId);
  int get lessonsPerDay => PersonalizationEngine.lessonsPerDay(dailyTime);
  DateTime get estimatedFinishDate {
    final total = activeContentPack?.tasks.length ?? lessons.length;
    final remaining = (total - completed.length).clamp(1, 100);
    return PersonalizationEngine.estimatedFinishDate(
      from: DateTime.now(),
      remainingLessons: remaining,
      dailyTime: dailyTime,
    );
  }

  int get nextRankXp => xp < 500
      ? 500
      : xp < 1500
      ? 1500
      : xp < 4000
      ? 4000
      : xp < 8000
      ? 8000
      : 10000;
  int get rankStart => xp < 500
      ? 0
      : xp < 1500
      ? 500
      : xp < 4000
      ? 1500
      : xp < 8000
      ? 4000
      : 8000;
  int get dueReviews => completed.length > seenReviews.length
      ? completed.length - seenReviews.length
      : 0;

  double get overallRoadmapProgress {
    final tasks = activeContentPack?.tasks ?? const <ContentTask>[];
    if (tasks.isEmpty) return (completed.length / 16).clamp(0.0, 1.0);
    final done = tasks.where((t) => completed.contains(t.id)).length;
    return (done / tasks.length).clamp(0.0, 1.0);
  }

  int get currentActiveRoadmapIndex {
    final tasks = activeContentPack?.tasks ?? const <ContentTask>[];
    if (tasks.isEmpty) return selectedLesson.clamp(0, lessons.length - 1);
    final idx = tasks.indexWhere((t) => !completed.contains(t.id));
    return idx != -1 ? idx : tasks.length - 1;
  }

  TaskStatus taskStatus(
    String taskId,
    int globalIndex,
    List<ContentTask> allTasks,
  ) {
    if (completed.contains(taskId)) {
      if (quickReviewTasks.contains(taskId)) return TaskStatus.quickReview;
      return TaskStatus.completed;
    }
    final firstUncompleted = allTasks.indexWhere(
      (t) => !completed.contains(t.id),
    );
    if (firstUncompleted == -1 ||
        globalIndex == firstUncompleted ||
        globalIndex <= selectedLesson) {
      return TaskStatus.current;
    }
    if (globalIndex == 0 ||
        (globalIndex > 0 && completed.contains(allTasks[globalIndex - 1].id))) {
      return TaskStatus.current;
    }
    return TaskStatus.locked;
  }

  double stageProgress(CourseStage stage) {
    if (stage.tasks.isEmpty) return 0.0;
    final done = stage.tasks.where((t) => completed.contains(t.id)).length;
    return (done / stage.tasks.length).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      onboarded = data['onboarded'] == true;
      username = data['username'] as String? ?? username;
      final savedTheme = data['themeMode'] as String?;
      if (savedTheme != null) {
        themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }
      goal = data['goal'] as String? ?? goal;
      dailyTime = data['dailyTime'] as String? ?? dailyTime;
      experience = data['experience'] as String? ?? experience;
      ageRange = data['ageRange'] as String? ?? ageRange;
      qualification = data['qualification'] as String? ?? qualification;
      referralSource = data['referralSource'] as String? ?? referralSource;
      hasCodedBefore = data['hasCodedBefore'] as String? ?? hasCodedBefore;
      pythonLevel = data['pythonLevel'] as String? ?? pythonLevel;
      learningStyle = data['learningStyle'] as String? ?? learningStyle;
      language = data['language'] as String? ?? language;
      final savedBuddy = data['buddyName'] as String?;
      buddyName =
          (savedBuddy == null ||
              savedBuddy == 'Pixel' ||
              savedBuddy == 'Supernova AI' ||
              savedBuddy == 'Supernova')
          ? 'Python Coach'
          : savedBuddy;
      tutorInstructions = data['tutorInstructions'] as String? ?? '';
      selectedStage4Track = data['selectedStage4Track'] as String? ?? 'web';
      quickReviewTasks.addAll(
        (data['quickReviewTasks'] as List? ?? []).cast<String>(),
      );
      adaptation.difficulty =
          data['difficulty'] as int? ?? adaptation.difficulty;
      adaptation.correctStreak = data['correctStreak'] as int? ?? 0;
      adaptation.wrongStreak = data['wrongStreak'] as int? ?? 0;
      final rawAttempts = data['topicAttempts'] as Map? ?? {};
      adaptation.topicAttempts.addAll(
        rawAttempts.map(
          (key, value) => MapEntry(key.toString(), (value as List).cast<int>()),
        ),
      );
      adaptation.revisionQueue.addAll(
        (data['revisionQueue'] as List? ?? []).cast<String>(),
      );
      xp = data['xp'] as int? ?? 0;
      streak = data['streak'] as int? ?? 0;
      selectedLesson = data['selectedLesson'] as int? ?? 0;
      lastActivityDay = data['lastActivityDay'] as String?;
      streakFreezeWeek = data['streakFreezeWeek'] as String?;
      completed.addAll((data['completed'] as List? ?? []).cast<String>());
      readLessons.addAll((data['readLessons'] as List? ?? []).cast<String>());
      attemptedPracticals.addAll(
        (data['attemptedPracticals'] as List? ?? []).cast<String>(),
      );
      answeredPracticalQuestions.addAll(
        (data['answeredPracticalQuestions'] as List? ?? []).cast<String>(),
      );
      passedPracticalQuestions.addAll(
        (data['passedPracticalQuestions'] as List? ?? []).cast<String>(),
      );
      completedExercises.addAll(
        (data['completedExercises'] as List? ?? []).cast<String>(),
      );
      seenReviews.addAll((data['seenReviews'] as List? ?? []).cast<String>());
      final rawFailures = data['failures'] as Map? ?? {};
      failures.addAll(
        rawFailures.map((key, value) => MapEntry(key.toString(), value as int)),
      );
    } catch (_) {
      // A damaged local save starts fresh rather than blocking the learner.
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'onboarded': onboarded,
        'username': username,
        'themeMode': themeMode.name,
        'goal': goal,
        'dailyTime': dailyTime,
        'experience': experience,
        'ageRange': ageRange,
        'qualification': qualification,
        'referralSource': referralSource,
        'hasCodedBefore': hasCodedBefore,
        'pythonLevel': pythonLevel,
        'learningStyle': learningStyle,
        'language': language,
        'buddyName': buddyName,
        'tutorInstructions': tutorInstructions,
        'selectedStage4Track': selectedStage4Track,
        'quickReviewTasks': quickReviewTasks.toList(),
        'difficulty': adaptation.difficulty,
        'correctStreak': adaptation.correctStreak,
        'wrongStreak': adaptation.wrongStreak,
        'topicAttempts': adaptation.topicAttempts,
        'revisionQueue': adaptation.revisionQueue.toList(),
        'xp': xp,
        'streak': streak,
        'selectedLesson': selectedLesson,
        'lastActivityDay': lastActivityDay,
        'streakFreezeWeek': streakFreezeWeek,
        'completed': completed.toList(),
        'readLessons': readLessons.toList(),
        'attemptedPracticals': attemptedPracticals.toList(),
        'answeredPracticalQuestions': answeredPracticalQuestions.toList(),
        'passedPracticalQuestions': passedPracticalQuestions.toList(),
        'completedExercises': completedExercises.toList(),
        'seenReviews': seenReviews.toList(),
        'failures': failures,
      }),
    );
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await save();
  }

  void _recordLearningDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (lastActivityDay == todayKey) return;
    if (lastActivityDay != null) {
      final previous = DateTime.tryParse(lastActivityDay!);
      if (previous != null) {
        final gap = today.difference(previous).inDays;
        if (gap == 1) {
          streak++;
        } else if (gap == 2 && streakFreezeWeek != _weekKey(today)) {
          // Spend the weekly freeze automatically to cover one missed day.
          streakFreezeWeek = _weekKey(today);
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    lastActivityDay = todayKey;
  }

  String _weekKey(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return '${monday.year}-${monday.month}-${monday.day}';
  }

  Future<void> completeLesson(int index) async {
    final id = index < lessons.length ? lessons[index].id : 'L1-01';
    readLessons.add(id);
    _syncTaskCompletion(id);
    _recordLearningDay();
    await save();
  }

  void _syncTaskCompletion(String id) {
    final allT = activeContentPack?.tasks ?? const <ContentTask>[];
    final index = allT.isNotEmpty
        ? allT.indexWhere((task) => task.id == id)
        : lessons.indexWhere((lesson) => lesson.id == id);
    if (index < 0) return;
    final canComplete = PersonalizationEngine.taskComplete(
      lessonRead: readLessons.contains(id),
      practicalsAttempted: attemptedPracticals.contains(id),
      topicMastery: masteryFor(id),
    );
    if (canComplete && completed.add(id)) {
      xp += 20;
      final maxLen = allT.isNotEmpty ? allT.length : lessons.length;
      if (index >= selectedLesson && index < maxLen - 1) {
        selectedLesson = index + 1;
      }
    }
  }

  Future<void> recordFailure(String id) async {
    failures[id] = (failures[id] ?? 0) + 1;
    final topicId = id.replaceAll('-EX', '');
    attemptedPracticals.add(topicId);
    PersonalizationEngine.recordAnswer(
      adaptation,
      topicId: topicId,
      correct: false,
    );
    _syncTaskCompletion(topicId);
    await save();
  }

  Future<void> recordPracticalResult({
    required String taskId,
    required String questionId,
    required List<String> taskQuestionIds,
    required bool correct,
  }) async {
    answeredPracticalQuestions.add(questionId);
    if (correct && passedPracticalQuestions.add(questionId)) xp += 4;
    PersonalizationEngine.recordAnswer(
      adaptation,
      topicId: taskId,
      correct: correct,
    );
    if (taskQuestionIds.every(answeredPracticalQuestions.contains)) {
      attemptedPracticals.add(taskId);
    }
    // When all questions in the practical are passed, unlock the next task
    if (taskQuestionIds.isNotEmpty &&
        taskQuestionIds.every(passedPracticalQuestions.contains)) {
      readLessons.add(taskId);
      if (completed.add(taskId)) {
        xp += 20;
        final allT = activeContentPack?.tasks ?? const <ContentTask>[];
        final curIdx = allT.indexWhere((t) => t.id == taskId);
        if (curIdx >= 0 && curIdx < allT.length - 1) {
          selectedLesson = curIdx + 1;
        }
      }
    }
    _syncTaskCompletion(taskId);
    _recordLearningDay();
    await save();
  }

  Future<void> awardExercise(String id, {int hintCount = 0}) async {
    if (completedExercises.add(id)) {
      xp += (6 * (1 - .25 * hintCount.clamp(0, 3))).round().clamp(2, 6);
      final topicId = id.replaceAll('-EX', '');
      attemptedPracticals.add(topicId);
      PersonalizationEngine.recordAnswer(
        adaptation,
        topicId: topicId,
        correct: true,
      );
      _syncTaskCompletion(topicId);
    }
    _recordLearningDay();
    await save();
  }

  Future<void> completeReview(String id) async {
    if (seenReviews.add(id)) xp += 5;
    _recordLearningDay();
    await save();
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.learner, required this.onDone});
  final LearnerState learner;
  final VoidCallback onDone;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int step = 0;
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.learner.username == 'friend' ? '' : widget.learner.username,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          gradient: step == 0
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8AAEFF),
                    Color(0xFF6D83F4),
                    Color(0xFF7773E9),
                  ],
                )
              : LinearGradient(
                  colors: context.isDarkMode
                      ? const [Color(0xFF13152C), Color(0xFF1A1D36)]
                      : const [Color(0xFFF7F8FE), Color(0xFFEEF1FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(child: step == 0 ? _welcome() : _setupPage()),
      ),
    );
  }

  Widget _welcome() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                'assets/branding/easy-python-wordmark.png',
                width: 148,
                height: 42,
                fit: BoxFit.contain,
                semanticLabel: 'Easy Python',
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .17),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Learn anywhere',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(flex: 2),
        const _LearningIllustration(),
        const Spacer(flex: 2),
        const Text(
          'Learn Python,\none small win at a time',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Short lessons, hands-on practice, and a path that grows with you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .88),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: coral,
              foregroundColor: Colors.white,
              elevation: 5,
              shadowColor: coral.withValues(alpha: .4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () => setState(() => step = 1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start learning',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'No account needed  ·  Your progress stays on this device',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .78),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _setupPage() {
    final learner = widget.learner;
    final pageTitle = switch (step) {
      1 => 'About you',
      2 => 'Your Python background',
      3 => 'Build your routine',
      _ => 'Your learning plan',
    };
    final pageHint = switch (step) {
      1 =>
        'A few details help your Python coach tailor the learning experience.',
      2 => 'We will start at a level that feels right for you.',
      3 => 'Choose a pace and style that fit your day.',
      _ => 'A simple path shaped around your time and experience.',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => setState(() => step = step - 1),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              Text('$step/3', style: TextStyle(color: context.appMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pageTitle,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pageHint,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                if (step == 1) ...[
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 24,
                    decoration: InputDecoration(
                      labelText: 'What should we call you?',
                      hintText: 'Your first name or nickname',
                      prefixIcon: const Icon(Icons.waving_hand_rounded),
                      filled: true,
                      fillColor: context.appSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceGroup(
                    title: 'Your age range',
                    options: const ['Under 18', '18–24', '25–34', '35+'],
                    value: learner.ageRange,
                    onSelect: (v) => setState(() => learner.ageRange = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'Qualification',
                    options: const [
                      'School',
                      'Undergraduate',
                      'Graduate',
                      'Other',
                    ],
                    value: learner.qualification,
                    onSelect: (v) => setState(() => learner.qualification = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'How did you hear about us?',
                    options: const [
                      'Search',
                      'Social media',
                      'Friend',
                      'Other',
                    ],
                    value: learner.referralSource,
                    onSelect: (v) => setState(() => learner.referralSource = v),
                  ),
                ],
                if (step == 2) ...[
                  _ChoiceGroup(
                    title: 'Have you coded before?',
                    options: const ['Yes', 'No'],
                    value: learner.hasCodedBefore,
                    onSelect: (v) => setState(() => learner.hasCodedBefore = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'Your Python level',
                    options: const [
                      'New to Python',
                      'Beginner',
                      'Intermediate',
                      'Advanced',
                    ],
                    value: learner.pythonLevel,
                    onSelect: (v) => setState(() => learner.pythonLevel = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'What brings you here?',
                    options: const [
                      'Career',
                      'Automation',
                      'Data / AI',
                      'Just curious',
                    ],
                    value: learner.goal,
                    onSelect: (v) => setState(() => learner.goal = v),
                  ),
                ],
                if (step == 3) ...[
                  _ChoiceGroup(
                    title: 'Daily learning time',
                    options: const ['15 min', '30 min', '45 min', '60 min'],
                    value: learner.dailyTime,
                    onSelect: (v) => setState(() => learner.dailyTime = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'Learning style',
                    options: const ['Hands-on', 'Read first', 'Examples first'],
                    value: learner.learningStyle,
                    onSelect: (v) => setState(() => learner.learningStyle = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'Language',
                    options: const ['English', 'Malayalam'],
                    value: learner.language,
                    onSelect: (v) => setState(() => learner.language = v),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceGroup(
                    title: 'Choose your tutor name',
                    options: const ['Python Coach', 'Nova', 'Byte'],
                    value: learner.buddyName,
                    onSelect: (v) => setState(() => learner.buddyName = v),
                  ),
                ],
                if (step == 4) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${learner.username}!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Starting point: ${learner.pythonLevel}',
                            style: TextStyle(color: context.appText),
                          ),
                          Text(
                            'Daily pace: ${learner.lessonsPerDay} lesson${learner.lessonsPerDay == 1 ? '' : 's'}',
                            style: TextStyle(color: context.appText),
                          ),
                          Text(
                            'Estimated finish: ${learner.estimatedFinishDate.toLocal().toString().split(' ').first}',
                            style: TextStyle(color: context.appText),
                          ),
                          Text(
                            'Goal: ${learner.goal}',
                            style: TextStyle(color: context.appText),
                          ),
                          Text(
                            'Learning style: ${learner.learningStyle}',
                            style: TextStyle(color: context.appText),
                          ),
                          Text(
                            'Buddy: ${learner.buddyName}',
                            style: TextStyle(color: context.appText),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your plan adjusts as you practice. You can change your daily time later.',
                            style: TextStyle(
                              height: 1.45,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                /*
                const SizedBox(height: 18),
                _ChoiceGroup(
                  title: 'Daily time',
                  options: const ['15 min', '30 min', '45 min'],
                  value: learner.dailyTime,
                  onSelect: (v) => setState(() => learner.dailyTime = v),
                ),
                const SizedBox(height: 18),
                _ChoiceGroup(
                  title: 'Python experience',
                  options: const ['New', 'Some', 'Pro'],
                  value: learner.experience,
                  onSelect: (v) => setState(() => learner.experience = v),
                ),
                */
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () {
                if (step < 4) {
                  if (step == 3) _prepareLearningPlan();
                  setState(() => step++);
                } else {
                  _finish();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: coral,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                step == 3
                    ? 'Build my plan'
                    : step == 4
                    ? 'Start learning'
                    : 'Continue',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    await widget.learner.finishOnboarding();
    widget.onDone();
  }

  void _prepareLearningPlan() {
    final enteredName = nameController.text.trim();
    widget.learner.username = enteredName.isEmpty ? 'friend' : enteredName;
    widget.learner.selectedStage4Track =
        PersonalizationEngine.defaultStage4TrackForGoal(widget.learner.goal);

    final level = widget.learner.pythonLevel;
    final codedBefore = widget.learner.hasCodedBefore == 'Yes';

    if (level == 'Advanced') {
      final reviewIds = [
        'L1-01',
        'L1-02',
        'L1-03',
        'L1-04',
        'L1-05',
        'L1-06',
        'L1-07',
        'L2-01',
        'L2-02',
        'L2-03',
        'L2-04',
        'L2-05',
      ];
      widget.learner.quickReviewTasks.addAll(reviewIds);
      widget.learner.completed.addAll(reviewIds);
      widget.learner.selectedLesson = 12; // Stage 3 Topic 13 (0-indexed: 12)
    } else if (level == 'Intermediate') {
      final reviewIds = [
        'L1-01',
        'L1-02',
        'L1-03',
        'L1-04',
        'L1-05',
        'L1-06',
        'L1-07',
      ];
      widget.learner.quickReviewTasks.addAll(reviewIds);
      widget.learner.completed.addAll(reviewIds);
      widget.learner.selectedLesson = 7; // Stage 2 Topic 8 (0-indexed: 7)
    } else if (codedBefore) {
      final reviewIds = ['L1-01', 'L1-02'];
      widget.learner.quickReviewTasks.addAll(reviewIds);
      widget.learner.completed.addAll(reviewIds);
      widget.learner.selectedLesson = 2;
    } else {
      widget.learner.selectedLesson = 0;
    }

    widget.learner.adaptation.difficulty =
        PersonalizationEngine.startingDifficulty(widget.learner.pythonLevel);
  }
}

class _LearningIllustration extends StatelessWidget {
  const _LearningIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 290,
    height: 290,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 258,
          height: 258,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFD36A),
          ),
        ),
        Container(
          width: 218,
          height: 218,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .3),
              width: 2,
            ),
          ),
        ),
        Container(
          width: 160,
          height: 142,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C82D8), Color(0xFF1757A8)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x553157A7),
                blurRadius: 22,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 12,
                child: Container(
                  width: 54,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16477E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Icon(
                Icons.laptop_mac_rounded,
                color: Colors.white,
                size: 76,
              ),
              Positioned(
                bottom: 13,
                right: 15,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD36A),
                  ),
                  child: const Center(
                    child: Text(
                      'Py',
                      style: TextStyle(
                        color: Color(0xFF234779),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 20,
          left: 30,
          child: _FloatBadge(
            icon: Icons.auto_stories_rounded,
            color: Color(0xFFFF8C76),
          ),
        ),
        const Positioned(
          top: 37,
          right: 22,
          child: _FloatBadge(
            icon: Icons.bolt_rounded,
            color: Color(0xFF766BF1),
          ),
        ),
        const Positioned(
          bottom: 26,
          left: 18,
          child: _FloatBadge(
            icon: Icons.code_rounded,
            color: Color(0xFF59C8AE),
          ),
        ),
        const Positioned(
          bottom: 38,
          right: 20,
          child: _FloatBadge(
            icon: Icons.star_rounded,
            color: Color(0xFFFFA94D),
          ),
        ),
      ],
    ),
  );
}

class _FloatBadge extends StatelessWidget {
  const _FloatBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22334C85),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, color: color, size: 27),
  );
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.options,
    required this.value,
    required this.onSelect,
  });
  final String title;
  final List<String> options;
  final String value;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: context.appText),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (option) => ChoiceChip(
                label: Text(option),
                selected: value == option,
                onSelected: (_) => onSelect(option),
                selectedColor: context.isDarkMode
                    ? const Color(0xFF263A5E)
                    : const Color(0xFFDCEAF6),
                backgroundColor: context.isDarkMode
                    ? const Color(0xFF242844)
                    : Colors.white,
                labelStyle: TextStyle(
                  color: value == option
                      ? (context.isDarkMode ? const Color(0xFF90C2FF) : primary)
                      : context.appText,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: value == option
                        ? (context.isDarkMode
                              ? const Color(0xFF90C2FF)
                              : primary)
                        : context.appBorder,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.learner, required this.onChanged});
  final LearnerState learner;
  final VoidCallback onChanged;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        learner: widget.learner,
        onOpenLesson: openLesson,
        onAskTutor: openTutor,
        onTab: (i) => setState(() => tab = i),
        onChanged: refresh,
      ),
      PathScreen(learner: widget.learner, onOpenLesson: openLesson),
      PythonIdeScreen(learnerName: widget.learner.name),
      PracticeScreen(learner: widget.learner, onChanged: refresh),
      ProfileScreen(learner: widget.learner, onChanged: refresh),
    ];
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_rounded),
            label: 'Roadmap',
          ),
          NavigationDestination(
            icon: Icon(Icons.code_rounded),
            selectedIcon: Icon(Icons.code_rounded),
            label: 'IDE',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void refresh() => setState(() {});
  void openLesson(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          learner: widget.learner,
          index: index,
          onChanged: refresh,
          onAskTutor: (question) =>
              openTutor(lessonIndex: index, initialQuestion: question),
        ),
      ),
    );
    refresh();
  }

  void openTutor({int? lessonIndex, String? initialQuestion}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TutorScreen(
          learner: widget.learner,
          lessonIndex:
              lessonIndex ??
              widget.learner.selectedLesson
                  .clamp(0, lessons.length - 1)
                  .toInt(),
          initialQuestion: initialQuestion,
        ),
      ),
    );
  }
}

class _PathModule {
  const _PathModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.start,
    required this.end,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final int start;
  final int end;
  List<int> get indexes => List.generate(end - start + 1, (i) => start + i);
  int completedCount(LearnerState learner) =>
      indexes.where((i) => learner.completed.contains(lessons[i].id)).length;
}

const _pathModules = <_PathModule>[
  _PathModule(
    title: 'Getting started',
    subtitle: 'Your first Python steps',
    icon: Icons.rocket_launch_rounded,
    tint: Color(0xFFFA9A74),
    start: 0,
    end: 2,
  ),
  _PathModule(
    title: 'Variables & data',
    subtitle: 'Give information a name',
    icon: Icons.inventory_2_rounded,
    tint: Color(0xFF55C6B1),
    start: 3,
    end: 6,
  ),
  _PathModule(
    title: 'Decisions',
    subtitle: 'Teach code to choose',
    icon: Icons.alt_route_rounded,
    tint: Color(0xFF8379EE),
    start: 7,
    end: 10,
  ),
  _PathModule(
    title: 'Loops',
    subtitle: 'Repeat useful actions',
    icon: Icons.loop_rounded,
    tint: Color(0xFFF2B942),
    start: 11,
    end: 15,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.learner,
    required this.onOpenLesson,
    required this.onAskTutor,
    required this.onTab,
    required this.onChanged,
  });
  final LearnerState learner;
  final ValueChanged<int> onOpenLesson;
  final VoidCallback onAskTutor;
  final ValueChanged<int> onTab;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final current = learner.selectedLesson.clamp(0, lessons.length - 1).toInt();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HELLO, PYTHON LEARNER',
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Find your next win',
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundAction(
                icon: Icons.search_rounded,
                label: 'Search lessons',
                onTap: () => _showLessonSearch(context),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF45352C)
                      : const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: streakColor,
                      size: 19,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${learner.streak}',
                      style: TextStyle(
                        color: context.appText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ContinueBanner(
            lesson: lessons[current],
            current: current,
            completed: learner.completed.length,
            onTap: () => onOpenLesson(current),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: _SectionLabel('Explore your path')),
              TextButton(
                onPressed: () => onTab(1),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pathModules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .91,
            ),
            itemBuilder: (context, index) {
              final module = _pathModules[index];
              return _CourseTile(
                module: module,
                learner: learner,
                onTap: () => _openModule(context, module),
              );
            },
          ),
          const SizedBox(height: 16),
          // Dedicated Python IDE Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onTab(2),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.isDarkMode
                        ? const [Color(0xFF1E2838), Color(0xFF161F2E)]
                        : const [Color(0xFFEBF5FF), Color(0xFFFFFFFF)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue, AppColors.violet],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Dedicated Python IDE',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: context.appText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Write, run & debug scripts in the Python IDE',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Python teaching mode card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAskTutor,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.isDarkMode
                        ? const [Color(0xFF282641), Color(0xFF20233F)]
                        : const [Color(0xFFF1F0FF), Color(0xFFFFFFFF)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8174EF), Color(0xFFFFA23A)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDarkMode
                                ? Colors.transparent
                                : const Color(0x160F2860),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Python Learning Path',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Instant answers, error debugging & study tips',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => onTab(3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF3E3320)
                      : const Color(0xFFFFF2D7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.isDarkMode
                      ? const Color(0xFFFFD36A)
                      : const Color(0xFFE8A529),
                ),
              ),
              title: Text(
                learner.dueReviews == 0
                    ? 'You’re all caught up'
                    : '${learner.dueReviews} quick reviews',
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text('A few minutes to keep your skills fresh'),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.appMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openModule(BuildContext context, _PathModule module) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ModuleDetailScreen(
          module: module,
          learner: learner,
          onOpenLesson: onOpenLesson,
        ),
      ),
    );
  }

  void _showLessonSearch(BuildContext context) {
    showSearch<int?>(
      context: context,
      delegate: _LessonSearchDelegate(onOpenLesson: onOpenLesson),
    );
  }
}

class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({
    required this.lesson,
    required this.current,
    required this.completed,
    required this.onTap,
  });
  final Lesson lesson;
  final int current;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 204,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF86A8FF), Color(0xFF607FEA), Color(0xFF7E76E8)],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x332F54B5),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -22,
          top: -24,
          child: Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: -53,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD36A).withValues(alpha: .25),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 30,
          top: 32,
          child: Transform.rotate(
            angle: -.12,
            child: Container(
              width: 110,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.laptop_mac_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 115, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'YOUR NEXT STEP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your\nPython journey going',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${lesson.title}  ·  ${lesson.minutes} min',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .87),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: coral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$completed / 16 lessons',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .86),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: context.appSurface,
    shape: CircleBorder(side: BorderSide(color: context.appBorder)),
    elevation: context.isDarkMode ? 0 : 2,
    shadowColor: context.isDarkMode
        ? Colors.transparent
        : const Color(0x1C26395F),
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, color: primary),
    ),
  );
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.module,
    required this.learner,
    required this.onTap,
  });
  final _PathModule module;
  final LearnerState learner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = module.completedCount(learner);
    final total = module.end - module.start + 1;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: module.tint.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(module.icon, color: module.tint, size: 31),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: context.appSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      done == total
                          ? Icons.check_rounded
                          : Icons.arrow_outward_rounded,
                      color: done == total ? success : context.appMuted,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$total bite-size lessons',
                style: TextStyle(color: context.appMuted, fontSize: 10),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: done / total,
                  minHeight: 5,
                  color: module.tint,
                  backgroundColor: context.appSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleDetailScreen extends StatelessWidget {
  const _ModuleDetailScreen({
    required this.module,
    required this.learner,
    required this.onOpenLesson,
  });
  final _PathModule module;
  final LearnerState learner;
  final ValueChanged<int> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final done = module.completedCount(learner);
    final total = module.end - module.start + 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
        children: [
          Container(
            height: 205,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  module.tint.withValues(alpha: .92),
                  const Color(0xFF6C82EA),
                ],
              ),
              borderRadius: BorderRadius.circular(27),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -18,
                  child: Container(
                    width: 155,
                    height: 155,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 23,
                  top: 35,
                  child: Icon(
                    module.icon,
                    size: 105,
                    color: Colors.white.withValues(alpha: .92),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FOUNDATIONS  ·  ${module.end - module.start + 1} LESSONS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 180,
                        child: Text(
                          module.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 185,
                        child: Text(
                          module.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: _SectionLabel('Course outline')),
              Text(
                '$done / $total done',
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (final index in module.indexes)
                  _OutlineLessonRow(
                    index: index,
                    completed: learner.completed.contains(lessons[index].id),
                    onTap: () => onOpenLesson(index),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => onOpenLesson(
                module.indexes.firstWhere(
                  (i) => !learner.completed.contains(lessons[i].id),
                  orElse: () => module.start,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                done == total ? 'Review this course' : 'Start course',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineLessonRow extends StatelessWidget {
  const _OutlineLessonRow({
    required this.index,
    required this.completed,
    required this.onTap,
  });
  final int index;
  final bool completed;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: completed
            ? (context.isDarkMode
                  ? const Color(0xFF183B30)
                  : const Color(0xFFE2F6EF))
            : (context.isDarkMode
                  ? const Color(0xFF252945)
                  : const Color(0xFFF0F2FC)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        completed ? Icons.check_rounded : Icons.play_arrow_rounded,
        color: completed ? success : primary,
        size: 21,
      ),
    ),
    title: Text(
      lessons[index].title,
      style: TextStyle(
        color: context.appText,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    ),
    subtitle: Text(
      '${lessons[index].minutes} min  ·  Lesson ${index + 1}',
      style: TextStyle(color: context.appMuted, fontSize: 11),
    ),
    trailing: Icon(Icons.chevron_right_rounded, color: context.appMuted),
  );
}

class _LessonSearchDelegate extends SearchDelegate<int?> {
  _LessonSearchDelegate({required this.onOpenLesson});
  final ValueChanged<int> onOpenLesson;

  @override
  String get searchFieldLabel => 'Search Python lessons';
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      onPressed: () => query = '',
      icon: const Icon(Icons.clear_rounded),
    ),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final found = <int>[];
    for (var i = 0; i < lessons.length; i++) {
      if (lessons[i].title.toLowerCase().contains(query.toLowerCase()) ||
          lessons[i].module.toLowerCase().contains(query.toLowerCase())) {
        found.add(i);
      }
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final i in found)
          Card(
            child: _OutlineLessonRow(
              index: i,
              completed: false,
              onTap: () {
                close(context, i);
                onOpenLesson(i);
              },
            ),
          ),
        if (found.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matching lessons yet. Try “loops” or “variables”.'),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: context.appText,
    ),
  );
}

class PathScreen extends StatefulWidget {
  const PathScreen({
    super.key,
    required this.learner,
    required this.onOpenLesson,
  });
  final LearnerState learner;
  final ValueChanged<int> onOpenLesson;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  final Map<String, bool> _expanded = {
    'stage-1': true,
    'stage-2': false,
    'stage-3': false,
    'stage-4': false,
  };

  @override
  void initState() {
    super.initState();
    _autoExpandActiveStage();
  }

  void _autoExpandActiveStage() {
    final stages = activeContentPack?.stages ?? const <CourseStage>[];
    final allTasks = activeContentPack?.tasks ?? const <ContentTask>[];
    final activeIdx = widget.learner.currentActiveRoadmapIndex;
    if (activeIdx >= 0 && activeIdx < allTasks.length) {
      final activeStageId = allTasks[activeIdx].stageId;
      for (final s in stages) {
        _expanded[s.id] = (s.id == activeStageId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = activeContentPack?.stages ?? const <CourseStage>[];
    final allTasks = activeContentPack?.tasks ?? const <ContentTask>[];
    final activeIndex = widget.learner.currentActiveRoadmapIndex;
    final activeTask = (activeIndex >= 0 && activeIndex < allTasks.length)
        ? allTasks[activeIndex]
        : null;
    final overallProgress = widget.learner.overallRoadmapProgress;
    final finishDate = widget.learner.estimatedFinishDate;
    final finishFormatted =
        '${finishDate.year}-${finishDate.month.toString().padLeft(2, '0')}-${finishDate.day.toString().padLeft(2, '0')}';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PYTHON MASTERY ROADMAP',
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From Fresher to Master',
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Follow W3Schools sequence with deep, hands-on practice',
                      style: TextStyle(color: context.appMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x160F2860),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: primary,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Top Overall Hero with Progress Ring & Continue Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B82FA),
                  Color(0xFF566DE8),
                  Color(0xFF755EF2),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x383955BD),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Floating Circular Progress Ring
                    Container(
                      width: 62,
                      height: 62,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x280E2463),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: overallProgress,
                            strokeWidth: 5.5,
                            strokeCap: StrokeCap.round,
                            color: success,
                            backgroundColor: const Color(0xFFE9EDF8),
                          ),
                          Text(
                            '${(overallProgress * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OVERALL PROGRESS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeTask != null
                                ? 'Next: ${activeTask.title}'
                                : 'You are all caught up!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.learner.completed.length} of ${allTasks.length} topics mastered',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .88),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pace: ${widget.learner.dailyTime}/day  ·  Est. finish: $finishFormatted',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => widget.onOpenLesson(activeIndex),
                      icon: const Icon(Icons.play_arrow_rounded, size: 19),
                      label: const Text('Continue learning'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.ink,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              const Expanded(child: _SectionLabel('4-Stage Journey')),
              Text(
                'Fresher to Master',
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // The 4 Stage Cards
          for (final stage in stages) _buildStageCard(context, stage, allTasks),
        ],
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    CourseStage stage,
    List<ContentTask> allTasks,
  ) {
    final isExpanded = _expanded[stage.id] ?? false;
    final progress = widget.learner.stageProgress(stage);
    final isFinished = progress >= 1.0;
    final isStage4 = stage.stageNumber == 4;

    // Gradient & icon styling per stage
    final (badgeColor, badgeIcon, gradientColors) = switch (stage.stageNumber) {
      1 => (
        accent,
        Icons.rocket_launch_rounded,
        [const Color(0xFFFFF2E6), const Color(0xFFFFE5D0)],
      ),
      2 => (
        success,
        Icons.layers_rounded,
        [const Color(0xFFE6F8F3), const Color(0xFFD3F2E9)],
      ),
      3 => (
        coral,
        Icons.bolt_rounded,
        [const Color(0xFFFFEFEF), const Color(0xFFFFDEDD)],
      ),
      _ => (
        primary,
        Icons.military_tech_rounded,
        [const Color(0xFFEEF3FF), const Color(0xFFDCE6FF)],
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded
              ? primary.withValues(alpha: .35)
              : context.appBorder,
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: .25)
                : const Color(0x120F2860),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stage Header (tap to toggle expansion)
          InkWell(
            onTap: () => setState(() => _expanded[stage.id] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  // 3D Styled Badge Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: context.isDarkMode
                            ? [
                                badgeColor.withValues(alpha: .3),
                                badgeColor.withValues(alpha: .15),
                              ]
                            : gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: .2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(badgeIcon, color: badgeColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STAGE ${stage.stageNumber}  ·  ${stage.estimatedHours} HOURS',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stage.title,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isStage4
                              ? 'Track: ${_trackLabel(widget.learner.selectedStage4Track)}'
                              : '${stage.tasks.length} topics · ${stage.projects.length} projects',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Circular Progress Ring for Stage
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4.2,
                          strokeCap: StrokeCap.round,
                          color: isFinished ? success : badgeColor,
                          backgroundColor: context.appSubtle,
                        ),
                        if (isFinished)
                          const Icon(
                            Icons.check_rounded,
                            color: success,
                            size: 18,
                          )
                        else
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.appMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),

            // Projects Pill / Summary
            if (stage.projects.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF222642)
                      : const Color(0xFFF6F8FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: badgeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Projects: ${stage.projects.map((p) => p['title']).join(' · ')}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Stage 4 Track Selection Cards
            if (isStage4)
              _buildStage4TrackSelector(context, stage, allTasks)
            else
              // Stage 1, 2, 3 Task List
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    for (final task in stage.tasks)
                      _buildTaskRow(context, task, allTasks),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context,
    ContentTask task,
    List<ContentTask> allTasks,
  ) {
    final globalIndex = allTasks.indexWhere((t) => t.id == task.id);
    final status = widget.learner.taskStatus(task.id, globalIndex, allTasks);
    final isLocked = status == TaskStatus.locked;
    final isCurrent = status == TaskStatus.current;

    final leadingIcon = switch (status) {
      TaskStatus.completed => Icons.check_circle_rounded,
      TaskStatus.quickReview => Icons.star_rounded,
      TaskStatus.current => Icons.play_circle_fill_rounded,
      TaskStatus.locked => Icons.lock_outline_rounded,
    };

    final iconColor = switch (status) {
      TaskStatus.completed => success,
      TaskStatus.quickReview => accent,
      TaskStatus.current => primary,
      TaskStatus.locked => context.appMuted.withValues(alpha: .5),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? primary.withValues(alpha: .06) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: primary.withValues(alpha: .25))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: Icon(leadingIcon, color: iconColor, size: 26),
          title: Text(
            '${task.order}. ${task.title}',
            style: TextStyle(
              color: isLocked ? context.appMuted : context.appText,
              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            '${task.minutes} min · Practical + Project',
            style: TextStyle(color: context.appMuted, fontSize: 10.5),
          ),
          trailing: _buildStatusPill(status),
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Complete the preceding topics to unlock this lesson.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              widget.onOpenLesson(globalIndex);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusPill(TaskStatus status) => switch (status) {
    TaskStatus.completed => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: success.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Done ✓',
        style: TextStyle(
          color: success,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    TaskStatus.quickReview => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Review ★',
        style: TextStyle(
          color: accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    TaskStatus.current => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Start',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    TaskStatus.locked => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Locked',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  };

  Widget _buildStage4TrackSelector(
    BuildContext context,
    CourseStage stage,
    List<ContentTask> allTasks,
  ) {
    final selectedId = widget.learner.selectedStage4Track;
    CourseTrack? currentTrack;
    for (final t in stage.tracks) {
      if (t.id == selectedId) currentTrack = t;
    }
    currentTrack ??= stage.tracks.isNotEmpty ? stage.tracks.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT YOUR SPECIALIZATION TRACK',
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 8),

          // Track Selection Carousel
          SizedBox(
            height: 125,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stage.tracks.length,
              itemBuilder: (context, idx) {
                final track = stage.tracks[idx];
                final isSelected = track.id == selectedId;
                final trackIcon = switch (track.id) {
                  'web' => Icons.language_rounded,
                  'data' => Icons.analytics_rounded,
                  'automation' => Icons.smart_toy_rounded,
                  'ai_ml' => Icons.psychology_rounded,
                  'security' => Icons.security_rounded,
                  _ => Icons.code_rounded,
                };

                return Container(
                  width: 175,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    color: isSelected
                        ? (context.isDarkMode
                              ? const Color(0xFF263256)
                              : const Color(0xFFEBF1FF))
                        : context.appSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected ? primary : context.appBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        setState(() {
                          widget.learner.selectedStage4Track = track.id;
                        });
                        await widget.learner.save();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  trackIcon,
                                  color: isSelected
                                      ? primary
                                      : context.appMuted,
                                  size: 22,
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              track.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: context.appText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Active Track Description & Capstone
          if (currentTrack != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF20243C)
                    : const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Active Track: ${currentTrack.title}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentTrack.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: context.appMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentTrack.technologies
                        .map(
                          (tech) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tech,
                              style: const TextStyle(
                                color: primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // Capstone Project Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDarkMode
                            ? [const Color(0xFF322A4E), const Color(0xFF26203E)]
                            : [
                                const Color(0xFFFFF7ED),
                                const Color(0xFFFFEED9),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: .3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              color: accent,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Capstone: ${currentTrack.capstone['title'] ?? 'Real-World Project'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: context.appText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentTrack.capstone['scenario'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Starting ${currentTrack?.title} Capstone Project!',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 16,
                            ),
                            label: const Text('Start Capstone Project'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: AppColors.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stage 4 Foundation Tasks
            for (final task in stage.tasks)
              _buildTaskRow(context, task, allTasks),
          ],
        ],
      ),
    );
  }

  String _trackLabel(String id) => switch (id) {
    'web' => 'Web Development',
    'data' => 'Data Science & Analytics',
    'automation' => 'Automation & Scripting',
    'ai_ml' => 'AI & Machine Learning',
    'security' => 'Cybersecurity',
    _ => 'Web Development',
  };
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({
    super.key,
    required this.learner,
    required this.index,
    required this.onChanged,
    required this.onAskTutor,
  });
  final LearnerState learner;
  final int index;
  final VoidCallback onChanged;
  final ValueChanged<String> onAskTutor;
  @override
  Widget build(BuildContext context) {
    final allTasks = activeContentPack?.tasks ?? const <ContentTask>[];
    final ContentTask? contentTask = (index >= 0 && index < allTasks.length)
        ? allTasks[index]
        : null;
    final lesson = (index >= 0 && index < lessons.length)
        ? lessons[index]
        : (contentTask != null
              ? Lesson(
                  contentTask.id,
                  contentTask.title,
                  contentTask.stageId,
                  contentTask.minutes,
                  contentTask.overview,
                  '',
                )
              : lessons[0]);
    final guide =
        lessonGuides[contentTask?.id ?? lesson.id] ??
        (contentTask != null ? contentTask.toGuide() : lessonGuides['L1-01']!);
    final done = learner.completed.contains(contentTask?.id ?? lesson.id);
    final read = learner.readLessons.contains(contentTask?.id ?? lesson.id);
    final name = learner.username.trim().isEmpty ? 'friend' : learner.username;
    final friendProblem = guide.friendProblem.replaceAll('{name}', name);
    final totalCount = allTasks.isNotEmpty ? allTasks.length : lessons.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Topic ${index + 1} of $totalCount'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (index + (done ? 1 : .25)) / totalCount,
                  minHeight: 7,
                  color: success,
                  backgroundColor: context.appSubtle,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                children: [
                  Text(
                    '${(contentTask?.stageId ?? "stage-1").toUpperCase()}  ·  TOPIC ${index + 1}/$totalCount',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    contentTask?.title ?? lesson.title,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lesson.minutes} min read · Python 3',
                    style: TextStyle(color: context.appMuted),
                  ),
                  const SizedBox(height: 14),
                  // Five-step learning system pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDarkMode
                            ? const [Color(0xFF222744), Color(0xFF1B1E38)]
                            : const [Color(0xFFEEF2FF), Color(0xFFE4E9FC)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Learn: Spark · Explore · Practice · Review · Build',
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeading(title: '🌟 Start with a spark'),
                  const SizedBox(height: 8),
                  _LessonGuideCard(guide: guide),
                  if (contentTask != null) ...[
                    const SizedBox(height: 20),
                    const _SectionHeading(title: '⚛️ Core Fusion'),
                    const SizedBox(height: 10),
                    for (final section in contentTask.lesson)
                      _ContentSectionCard(
                        heading: section['heading'] ?? '',
                        body: section['body'] ?? '',
                      ),
                  ],
                  const SizedBox(height: 20),
                  const _SectionHeading(title: '🚀 Orbit Examples'),
                  const SizedBox(height: 10),
                  if (contentTask == null)
                    _CodeCard(code: lesson.example)
                  else
                    for (final example in contentTask.examples) ...[
                      _ContentExampleCard(example: example),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 20),
                  _TopicWrapUpCard(takeaway: guide.topicTakeaway),
                  if (contentTask != null) ...[
                    const SizedBox(height: 16),
                    const _SectionHeading(title: '🌌 Nova Project'),
                    const SizedBox(height: 10),
                    _ContentSectionCard(
                      heading:
                          contentTask.project['title'] as String? ??
                          'Mini project',
                      body: contentTask.project['scenario'] as String? ?? '',
                    ),
                  ],
                  const SizedBox(height: 20),
                  _LiveProjectCard(
                    message: friendProblem,
                    onAskTutor: () => onAskTutor(friendProblem),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: contentTask == null
                          ? () => _openPractice(context)
                          : () => _openQuestions(context, contentTask),
                      icon: Icon(
                        contentTask == null
                            ? Icons.code_rounded
                            : Icons.quiz_outlined,
                      ),
                      label: Text(
                        contentTask == null
                            ? 'Try the code'
                            : 'Practice questions',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await learner.completeLesson(index);
                        onChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                learner.completed.contains(lesson.id)
                                    ? 'Task complete · +20 XP'
                                    : 'Lesson marked read. Practice to complete this task.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        done
                            ? 'Task complete ✓'
                            : read
                            ? 'Practice to complete'
                            : 'Mark lesson read',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPractice(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PracticeScreen(
        learner: learner,
        lessonIndex: index,
        standalone: true,
        onChanged: onChanged,
      ),
    ),
  );

  void _openQuestions(BuildContext context, ContentTask task) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionPracticeScreen(
            learner: learner,
            task: task,
            onChanged: onChanged,
            onAskTutor: onAskTutor,
          ),
        ),
      );
}

class QuestionPracticeScreen extends StatefulWidget {
  const QuestionPracticeScreen({
    super.key,
    required this.learner,
    required this.task,
    required this.onChanged,
    required this.onAskTutor,
  });

  final LearnerState learner;
  final ContentTask task;
  final VoidCallback onChanged;
  final ValueChanged<String> onAskTutor;

  @override
  State<QuestionPracticeScreen> createState() => _QuestionPracticeScreenState();
}

class _QuestionPracticeScreenState extends State<QuestionPracticeScreen> {
  final runnerKey = GlobalKey<PyodideRunnerState>();
  late final TextEditingController responseController;
  int questionIndex = 0;
  String? selectedOption;
  String? runOutput;
  AnswerEvaluation? evaluation;
  TeachingFeedback? teachingFeedback;
  bool runnerReady = false;
  bool checking = false;

  PracticalItem get question => widget.task.practicals[questionIndex];

  @override
  void initState() {
    super.initState();
    responseController = TextEditingController();
  }

  @override
  void dispose() {
    responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = questionIndex >= widget.task.practicals.length;
    final isCode =
        !isFinished &&
        (question.type == 'code' || question.type == 'fixTheBug');
    final isPrompt =
        !isFinished &&
        (isCode ||
            (question.commandPrompt != null &&
                question.commandPrompt!.isNotEmpty) ||
            question.type == 'shortAnswer');
    final userName = widget.learner.name.trim().isEmpty
        ? 'friend'
        : widget.learner.name.trim();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.task.title} · Practical')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isFinished)
            _finishPanel(context)
          else
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                      // Stage & Question Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'QUESTION ${questionIndex + 1} OF ${widget.task.practicals.length}',
                            style: const TextStyle(
                              color: primary,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${((questionIndex + (evaluation?.isCorrect == true ? 1 : 0)) / widget.task.practicals.length * 100).round()}% done',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              (questionIndex +
                                  (evaluation?.isCorrect == true ? 1 : 0)) /
                              widget.task.practicals.length,
                          minHeight: 7,
                          color: success,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Friendly AI Agent Greeting
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1E2838)
                              : const Color(0xFFEDF4FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primary.withValues(
                              alpha: context.isDarkMode ? 0.35 : 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withValues(alpha: 0.15),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  color: primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.learner.buddyName} (AI Coach)',
                                    style: const TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (question.scenario != null &&
                                            question.scenario!.isNotEmpty)
                                        ? 'Hey $userName! ${question.scenario}'
                                        : 'Hey $userName, let\'s tackle this hands-on challenge together!',
                                    style: TextStyle(
                                      color: context.appText,
                                      fontSize: 13.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question Prompt
                      Text(
                        question.prompt,
                        style: TextStyle(
                          fontSize: 19,
                          height: 1.35,
                          color: context.appText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Input Options / Terminal
                      if (question.type == 'yesNo')
                        _choiceOptions(const ['Yes', 'No'])
                      else if (question.type == 'multipleChoice')
                        _choiceOptions(question.options)
                      else if (isPrompt) ...[
                        // Command Prompt Style Terminal
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E293B),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(13),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isCode
                                            ? 'terminal · python 3 prompt'
                                            : 'command prompt',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 2,
                                        right: 8,
                                      ),
                                      child: Text(
                                        '>>> ',
                                        style: TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontFamily: 'monospace',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: responseController,
                                        minLines: isCode ? 4 : 1,
                                        maxLines: isCode ? 10 : 4,
                                        keyboardType: isCode
                                            ? TextInputType.multiline
                                            : TextInputType.text,
                                        style: const TextStyle(
                                          color: Color(0xFFF8FAFC),
                                          fontFamily: 'monospace',
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                        cursorColor: const Color(0xFF38BDF8),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: isCode
                                              ? 'Type Python code here…'
                                              : 'Type your answer here…',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCode) ...[
                          const SizedBox(height: 10),
                          Text(
                            runnerReady
                                ? 'Python runs on this device and works offline.'
                                : 'Preparing the offline Python runner…',
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (runOutput != null)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B132B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF1C2541),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OUTPUT',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    runOutput!.isEmpty
                                        ? '(no output)'
                                        : runOutput!,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],

                      // AI Analysis Feedback
                      if (evaluation != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: evaluation!.isCorrect
                                ? (context.isDarkMode
                                      ? const Color(0xFF14382F)
                                      : const Color(0xFFE8F6EF))
                                : (context.isDarkMode
                                      ? const Color(0xFF452227)
                                      : const Color(0xFFFFF1EE)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: evaluation!.isCorrect
                                  ? success.withValues(alpha: 0.5)
                                  : error.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    evaluation!.isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: evaluation!.isCorrect
                                        ? success
                                        : error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      teachingFeedback?.headline ??
                                          (evaluation!.isCorrect
                                              ? 'Right! Well done, $userName.'
                                              : 'Not quite yet, $userName.'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: evaluation!.isCorrect
                                            ? success
                                            : error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                evaluation!.message,
                                style: TextStyle(
                                  height: 1.45,
                                  color: context.appText,
                                ),
                              ),
                              if (teachingFeedback?.tip != null ||
                                  (question.aiExplanation != null &&
                                      question.aiExplanation!.isNotEmpty)) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? Colors.black26
                                        : Colors.white70,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 16,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          teachingFeedback?.tip != null
                                              ? 'Python Tip: ${teachingFeedback!.tip}'
                                              : question.aiExplanation!,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                            color: context.appText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!evaluation!.isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => widget.onAskTutor(
                                  '${question.prompt}\nMy attempt: ${responseController.text}\nHelp me understand why this was not right.',
                                ),
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  'Ask ${widget.learner.buddyName} for a hint',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: checking || (isCode && !runnerReady)
                            ? null
                            : evaluation?.isCorrect == true
                            ? _nextQuestion
                            : isCode
                            ? _runCode
                            : _checkWrittenAnswer,
                        child: Text(
                          checking
                              ? 'Checking…'
                              : evaluation?.isCorrect == true
                              ? questionIndex + 1 ==
                                        widget.task.practicals.length
                                    ? 'Finish practical'
                                    : 'Next question'
                              : isCode
                              ? 'Run and check'
                              : 'Check answer',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(
              child: PyodideRunner(
                key: runnerKey,
                onReady: (ready) {
                  if (mounted && runnerReady != ready) {
                    setState(() => runnerReady = ready);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceOptions(List<String> options) => Column(
    children: options
        .map(
          (option) => Card(
            // ignore: deprecated_member_use
            child: RadioListTile<String>(
              value: option,
              // ignore: deprecated_member_use
              groupValue: selectedOption,
              // ignore: deprecated_member_use
              onChanged: evaluation?.isCorrect == true
                  ? null
                  : (value) => setState(() => selectedOption = value),
              title: Text(option),
            ),
          ),
        )
        .toList(),
  );

  Future<void> _checkWrittenAnswer() async {
    final response = selectedOption ?? responseController.text.trim();
    final analysis = const PythonTeachingMode().analyzeSubmission(
      question: question,
      userResponse: response,
      userName: widget.learner.name,
    );
    teachingFeedback = analysis;
    final result = AnswerEvaluation(
      isCorrect: analysis.isCorrect,
      message: analysis.explanation,
    );
    await _recordResult(response, result);
  }

  Future<void> _runCode() async {
    final source = responseController.text;
    setState(() => checking = true);
    try {
      final runResult = await runnerKey.currentState!.run(source);
      final analysis = const PythonTeachingMode().analyzeSubmission(
        question: question,
        userResponse: source,
        userName: widget.learner.name,
        runResult: runResult,
      );
      teachingFeedback = analysis;
      final evaluationResult = AnswerEvaluation(
        isCorrect: analysis.isCorrect,
        message: analysis.explanation,
      );
      if (!mounted) return;
      setState(() => runOutput = runResult.stdout);
      await _recordResult(source, evaluationResult);
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _recordResult(String response, AnswerEvaluation result) async {
    await widget.learner.recordPracticalResult(
      taskId: widget.task.id,
      questionId: question.id,
      taskQuestionIds: widget.task.practicals.map((item) => item.id).toList(),
      correct: result.isCorrect,
    );
    if (!mounted) return;
    setState(() => evaluation = result);
    widget.onChanged();
  }

  void _nextQuestion() {
    if (questionIndex + 1 >= widget.task.practicals.length) {
      setState(() => questionIndex = widget.task.practicals.length);
      return;
    }
    setState(() {
      questionIndex++;
      selectedOption = null;
      evaluation = null;
      teachingFeedback = null;
      runOutput = null;
      responseController.clear();
    });
  }

  Widget _finishPanel(BuildContext context) {
    final project = widget.task.project;
    final projectTitle =
        project['title'] as String? ?? 'Real-World Mini Project';
    final projectScenario = project['scenario'] as String? ?? '';
    final projectSteps =
        (project['steps'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        <String>[];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Icon(Icons.celebration_rounded, color: success, size: 56),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Topic Completed!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'You mastered the practical questions for ${widget.task.title}. The next task on your roadmap is unlocked!',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),

        // Real-World Mini Project Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF1E2838)
                : const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REAL-WORLD MINI PROJECT',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          projectTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (projectScenario.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  projectScenario,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: context.appText,
                  ),
                ),
              ],
              if (projectSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Project Steps:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                for (final step in projectSteps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: context.appMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.alt_route_rounded),
          label: const Text('Back to Roadmap'),
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w800,
      color: context.appText,
    ),
  );
}

class _ContentSectionCard extends StatelessWidget {
  const _ContentSectionCard({required this.heading, required this.body});
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 7),
          Text(body, style: TextStyle(height: 1.5, color: context.appText)),
        ],
      ),
    ),
  );
}

class _ContentExampleCard extends StatelessWidget {
  const _ContentExampleCard({required this.example});
  final Map<String, String> example;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        example['title'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      _CodeCard(code: example['code'] ?? ''),
      const SizedBox(height: 8),
      _ContentSectionCard(
        heading: 'Output',
        body: '${example['output'] ?? ''}\n\n${example['explanation'] ?? ''}',
      ),
    ],
  );
}

class _LessonGuideCard extends StatelessWidget {
  const _LessonGuideCard({required this.guide});
  final LessonGuide guide;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1D2742),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, color: primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Topic brief',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          guide.plainLanguage,
          style: TextStyle(color: context.appText, fontSize: 15, height: 1.55),
        ),
        const SizedBox(height: 16),
        _GuideDetail(title: 'Why it helps', text: guide.whyItMatters),
        const SizedBox(height: 14),
        _GuideDetail(title: 'How the example works', text: guide.walkThrough),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF3A3020)
                : const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: context.isDarkMode
                    ? const Color(0xFFFFD36A)
                    : const Color(0xFFB77913),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guide.watchOut,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? const Color(0xFFFFE4A3)
                        : const Color(0xFF73531D),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GuideDetail extends StatelessWidget {
  const _GuideDetail({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(color: context.appText, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(text, style: TextStyle(color: context.appText, height: 1.55)),
    ],
  );
}

class _TopicWrapUpCard extends StatelessWidget {
  const _TopicWrapUpCard({required this.takeaway});
  final String takeaway;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.isDarkMode
          ? const Color(0xFF173C35)
          : const Color(0xFFEAF7F1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: context.isDarkMode
            ? const Color(0xFF28594E)
            : const Color(0xFFD4EDE1),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: success, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Topic wrap-up · What you learned',
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                takeaway,
                style: TextStyle(color: context.appText, height: 1.55),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LiveProjectCard extends StatelessWidget {
  const _LiveProjectCard({required this.message, required this.onAskTutor});
  final String message;
  final VoidCallback onAskTutor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: context.isDarkMode
            ? const [Color(0xFF1B3046), Color(0xFF19372F)]
            : const [Color(0xFFEAF6FF), Color(0xFFEAF9F4)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.chat_bubble_rounded, color: primary, size: 18),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Live project · Help a friend',
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.favorite_rounded, color: Color(0xFFFF8B84), size: 17),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '“$message”',
          style: TextStyle(color: context.appText, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAskTutor,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Open live project tutor'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Topic complete? Put it to work on this real-world problem. Your AI tutor gives live hints; first setup downloads the model once.',
          style: TextStyle(color: context.appMuted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: codeColor,
      borderRadius: BorderRadius.circular(15),
      border: const Border(left: BorderSide(color: accent, width: 4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PYTHON 3',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF9EB5D3),
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            height: 1.6,
            color: Color(0xFFEAF0F8),
          ),
        ),
      ],
    ),
  );
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.learner,
    required this.onChanged,
    this.lessonIndex,
    this.standalone = false,
  });
  final LearnerState learner;
  final VoidCallback onChanged;
  final int? lessonIndex;
  final bool standalone;
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final runnerKey = GlobalKey<PyodideRunnerState>();
  late int index;
  late final TextEditingController controller;
  String output = '';
  String? friendlyError;
  int hintCount = 0;
  bool passed = false;
  bool runnerReady = false;
  bool running = false;

  @override
  void initState() {
    super.initState();
    index =
        widget.lessonIndex ??
        widget.learner.selectedLesson.clamp(0, lessons.length - 1).toInt();
    controller = TextEditingController(text: _practiceExample(index));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[index];
    final body = SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (!widget.standalone)
            Text(
              'Daily practice',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'EXERCISE  ·  ${lesson.id}',
            style: TextStyle(
              color: primary,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _prompt(index),
            style: TextStyle(
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: codeColor,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: controller,
              minLines: 7,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                color: Color(0xFFEAF0F8),
                fontFamily: 'monospace',
                fontSize: 15,
                height: 1.5,
              ),
              cursorColor: accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Write Python here',
                hintStyle: TextStyle(color: Colors.white38),
                labelText: 'Python editor',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: running || !runnerReady ? null : _run,
                  icon: running
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(running ? 'Running…' : 'Run code'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showHint,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text('Hint $hintCount/3'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Output',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: friendlyError != null
                    ? (context.isDarkMode
                          ? const Color(0xFF6E2A34)
                          : const Color(0xFFF3C6C2))
                    : context.appBorder,
              ),
            ),
            child: Text(
              output.isEmpty ? 'Your program output will appear here.' : output,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
                color: context.appText,
              ),
            ),
          ),
          if (friendlyError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(friendlyError!, style: const TextStyle(color: error)),
            ),
          const SizedBox(height: 18),
          Text(
            'Checks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 8),
          _TestRow(
            label: 'Program runs without an error',
            passed: output.isNotEmpty && friendlyError == null,
          ),
          _TestRow(label: 'Output matches this lesson', passed: passed),
          if (passed)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF173C35)
                    : const Color(0xFFE7F5EE),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: success),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Nice work! Your code passed.',
                      style: TextStyle(
                        color: context.isDarkMode
                            ? const Color(0xFF86E3B8)
                            : const Color(0xFF206543),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.learner.awardExercise(
                        '${lesson.id}-EX',
                        hintCount: hintCount,
                      );
                      widget.onChanged();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Practice complete · XP added'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('+ XP'),
                  ),
                ],
              ),
            ),
          if (!passed && (widget.learner.failures['${lesson.id}-EX'] ?? 0) >= 3)
            TextButton(
              onPressed: _showSolution,
              child: const Text('See worked example'),
            ),
          const SizedBox(height: 20),
          if (!widget.standalone)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome_rounded,
                  color: streakColor,
                ),
                title: Text(
                  widget.learner.dueReviews == 0
                      ? 'No review items due'
                      : '${widget.learner.dueReviews} quick reviews',
                ),
                subtitle: const Text('Review a finished lesson'),
                onTap: () => _review(context),
              ),
            ),
        ],
      ),
    );
    final runnerStack = Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned(
          left: 0,
          bottom: 0,
          child: IgnorePointer(
            child: PyodideRunner(
              key: runnerKey,
              onReady: (ready) {
                if (mounted && runnerReady != ready) {
                  setState(() => runnerReady = ready);
                }
              },
            ),
          ),
        ),
      ],
    );
    return widget.standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('Try it')),
            body: runnerStack,
          )
        : runnerStack;
  }

  String _practiceExample(int lessonIndex) {
    for (final task in activeContentPack?.tasks ?? const <ContentTask>[]) {
      if (task.id == lessons[lessonIndex].id && task.examples.isNotEmpty) {
        return task.examples.first['code'] ?? lessons[lessonIndex].example;
      }
    }
    return lessons[lessonIndex].example;
  }

  String _expectedExampleOutput(int lessonIndex) {
    for (final task in activeContentPack?.tasks ?? const <ContentTask>[]) {
      if (task.id == lessons[lessonIndex].id && task.examples.isNotEmpty) {
        return task.examples.first['output'] ?? '';
      }
    }
    const outputs = {
      'L1-01': 'Hello, Python!\n',
      'L1-02': 'Good morning, Asha!\n',
      'L1-03': 'You can do this!\n',
      'L1-04': 'Asha\n',
      'L1-05': '30\n',
      'L1-06': 'Welcome, Asha!\n',
      'L1-07': 'int\n',
      'L1-08': 'True\n',
      'L1-09': 'Take an umbrella\n',
      'L1-10': 'Great work!\n',
      'L1-11': 'True\n',
      'L1-12': 'Mon\nTue\nWed\n',
      'L1-13': '1\n2\n3\n',
      'L1-14': 'Try again\nTry again\nTry again\n',
      'L1-15': '1\n2\n3\n',
      'L1-16': 'Try a higher number\n',
    };
    return outputs[lessons[lessonIndex].id] ?? '';
  }

  String _prompt(int lessonIndex) {
    for (final task in activeContentPack?.tasks ?? const <ContentTask>[]) {
      if (task.id == lessons[lessonIndex].id) {
        final codeQuestions = task.practicals.where(
          (item) => item.type == 'code',
        );
        if (codeQuestions.isNotEmpty) return codeQuestions.last.prompt;
      }
    }
    return 'Run the example for “${lessons[lessonIndex].title}”. Then change one value and run it again.';
  }

  Future<void> _run() async {
    final source = controller.text;
    final runner = runnerKey.currentState;
    if (runner == null || !runnerReady) {
      setState(() {
        friendlyError =
            'The offline Python runtime is preparing. Try again in a moment.';
      });
      return;
    }
    setState(() {
      running = true;
      friendlyError = null;
    });
    final result = await runner.run(source);
    final expected = _expectedExampleOutput(
      index,
    ).trim().replaceAll('\r\n', '\n');
    final actual = result.stdout.trim().replaceAll('\r\n', '\n');
    final codeRun = CodeRunResult(
      stdout: result.stdout,
      stderr: result.stderr,
      timedOut: result.timedOut,
      executionError: result.executionError,
    );
    const evaluator = AnswerEvaluator();
    final evaluated = evaluator.evaluate(
      PracticalItem(
        id: 'editor-run',
        type: 'code',
        prompt: 'Run the current task.',
        tests: [
          {'stdout': expected},
        ],
      ),
      source,
      runResult: CodeRunResult(
        stdout: actual,
        stderr: codeRun.stderr,
        timedOut: codeRun.timedOut,
        executionError: codeRun.executionError,
      ),
    );
    final correct = evaluated.isCorrect;
    setState(() {
      output = result.stdout;
      friendlyError =
          result.executionError ??
          (result.stderr.isEmpty ? null : result.stderr);
      passed = correct;
      running = false;
    });
    if (friendlyError != null || result.timedOut || !passed) {
      await widget.learner.recordFailure('${lessons[index].id}-EX');
    }
    widget.onChanged();
  }

  void _showHint() {
    if (hintCount >= 3) return;
    setState(() => hintCount++);
    final hints = [
      'Start by reading the example from top to bottom.',
      'Keep the quotes and parentheses balanced.',
      'Try running the starter code first, then edit one small part.',
    ];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hint $hintCount of 3'),
        content: Text(hints[hintCount - 1]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSolution() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worked example',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            lessons[index].example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
  void _review(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        _ReviewSheet(learner: widget.learner, onChanged: widget.onChanged),
  );
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.label, required this.passed});
  final String label;
  final bool passed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          passed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 19,
          color: passed ? success : const Color(0xFF9CA8B7),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(label, style: TextStyle(color: context.appText)),
        ),
      ],
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.learner, required this.onChanged});
  final LearnerState learner;
  final VoidCallback onChanged;
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int cursor = 0;
  @override
  Widget build(BuildContext context) {
    final due = lessons
        .where(
          (l) =>
              widget.learner.completed.contains(l.id) &&
              !widget.learner.seenReviews.contains(l.id),
        )
        .toList();
    if (due.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You’re all caught up. Finish a lesson and it will appear here.',
          ),
        ),
      );
    }
    final lesson = due[cursor.clamp(0, due.length - 1).toInt()];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick review  ·  ${cursor + 1} of ${due.length}',
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lesson.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.summary,
              style: TextStyle(height: 1.45, color: context.appMuted),
            ),
            const SizedBox(height: 14),
            _CodeCard(code: lesson.example),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await widget.learner.completeReview(lesson.id);
                  widget.onChanged();
                  if (cursor + 1 >= due.length) {
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    setState(() => cursor++);
                  }
                },
                child: const Text('I remember this · +5 XP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorMessage {
  _TutorMessage(this.isUser, this.text, {this.loading = false});
  final bool isUser;
  String text;
  bool loading;
}

class TutorScreen extends StatefulWidget {
  const TutorScreen({
    super.key,
    required this.learner,
    required this.lessonIndex,
    this.initialQuestion,
  });
  final LearnerState learner;
  final int lessonIndex;
  final String? initialQuestion;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final tutor = OnDeviceTutor();
  final input = TextEditingController();
  final scrollController = ScrollController();
  late final List<_TutorMessage> messages;
  bool enabled = true;
  bool preparing = false;
  bool generating = false;
  double progress = 0;
  String? statusMessage;
  late final AppLifecycleListener lifecycleListener;
  Timer? unloadTimer;

  @override
  void initState() {
    super.initState();
    lifecycleListener = AppLifecycleListener(onStateChange: _handleLifecycle);
    input.text = widget.initialQuestion ?? '';
    messages = [
      _TutorMessage(
        false,
        'Hey ${widget.learner.username}, I’m ${widget.learner.buddyName}. Tell me what part feels tricky and we’ll work it out together.',
      ),
    ];
  }

  @override
  void dispose() {
    lifecycleListener.dispose();
    unloadTimer?.cancel();
    input.dispose();
    scrollController.dispose();
    tutor.close();
    super.dispose();
  }

  void _handleLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unloadTimer?.cancel();
      unloadTimer = null;
      return;
    }
    if (state == AppLifecycleState.paused) {
      unloadTimer?.cancel();
      unloadTimer = Timer(const Duration(minutes: 2), () async {
        await tutor.unload();
        if (!mounted) return;
        setState(() {
          statusMessage =
              'The on-device model is paused to save memory. Tap download icon to load it again.';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[widget.lessonIndex];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, Color(0xFF9A73F8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Python tutor',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          if (!tutor.isReady && !preparing)
            IconButton(
              tooltip: 'Download offline AI model',
              onPressed: _enableTutor,
              icon: const Icon(Icons.download_rounded, color: AppColors.orange),
            ),
          IconButton(
            tooltip: 'Customize tutor',
            onPressed: _customizeTutor,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF302B50)
                  : const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  tutor.isReady
                      ? Icons.phonelink_lock_rounded
                      : Icons.auto_awesome_rounded,
                  color: tutor.isReady ? primary : AppColors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tutor.isReady
                        ? '${widget.learner.buddyName} · on-device model active'
                        : '${widget.learner.buddyName} · built-in teaching mode active',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: success,
                  size: 17,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 17, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Learning: ${lesson.title}',
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: context.appMuted,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount:
                  messages.length +
                  (messages.length == 1 && !preparing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  return _TutorBubble(message: messages[index]);
                }
                return _suggestions();
              },
            ),
          ),
          if (preparing) _preparingStatus(),
          if (statusMessage != null && !preparing)
            _TutorStatus(message: statusMessage!, onRetry: _enableTutor),
          if (!tutor.isReady && !preparing && messages.length <= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: _enableTutor,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF23253A)
                        : const Color(0xFFF1F3FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Optional: Download an on-device AI model',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _suggestions() => Padding(
    padding: const EdgeInsets.only(left: 42, top: 10, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try asking',
          style: TextStyle(
            color: context.appMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SuggestionChip(
              label: 'Explain this simply',
              onTap: () => _sendPreset(
                'Explain ${lessons[widget.lessonIndex].title} in simple words with one short example.',
              ),
            ),
            _SuggestionChip(
              label: 'Give me a hint',
              onTap: () => _sendPreset(
                'Give me one small hint for ${lessons[widget.lessonIndex].title}. Do not show the full answer yet.',
              ),
            ),
            _SuggestionChip(
              label: 'Show a practice idea',
              onTap: () => _sendPreset(
                'Give me a tiny practice challenge about ${lessons[widget.lessonIndex].title}.',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _preparingStatus() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
    child: Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                progress > 0
                    ? 'Downloading on-device tutor · ${(progress * 100).round()}%'
                    : 'Preparing ${widget.learner.buddyName}…',
                style: TextStyle(color: context.appMuted, fontSize: 13),
              ),
            ),
          ],
        ),
        if (progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              value: progress,
              color: primary,
              backgroundColor: context.appSubtle,
            ),
          ),
      ],
    ),
  );

  Widget _composer() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText:
                    'Ask ${widget.learner.buddyName} anything about Python…',
                filled: true,
                fillColor: context.isDarkMode
                    ? const Color(0xFF242844)
                    : const Color(0xFFF5F4FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send question',
            onPressed: enabled && !generating ? _send : null,
            icon: const Icon(Icons.arrow_upward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.isDarkMode
                  ? const Color(0xFF2E3352)
                  : const Color(0xFFD6D4E1),
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _enableTutor() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.phonelink_lock_rounded,
          color: primary,
          size: 34,
        ),
        title: const Text('Set up your private AI tutor?'),
        content: const Text(
          'The app chooses a compact coding model for this phone, then downloads it once over Wi-Fi. Model questions and streamed replies run on-device. The model is checked with SHA-256 before it is opened.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download model'),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    setState(() {
      preparing = true;
      statusMessage = null;
      progress = 0;
    });
    try {
      await tutor.prepare(
        customInstructions: widget.learner.tutorInstructions,
        onProgress: (value) {
          if (mounted) setState(() => progress = value);
        },
      );
      if (!mounted) return;
      setState(() {
        enabled = true;
        preparing = false;
        statusMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      final cleanMsg = error
          .toString()
          .replaceAll('StateError: ', '')
          .replaceAll('Exception: ', '')
          .replaceAll('HttpException: ', '')
          .trim();
      setState(() {
        preparing = false;
        statusMessage = cleanMsg.isNotEmpty
            ? cleanMsg
            : 'Could not prepare the local AI model. Check your connection and free storage, confirm Android 11 or newer, then retry.';
      });
    }
  }

  void _sendPreset(String text) {
    input.text = text;
    _send();
  }

  Future<void> _send() async {
    final question = input.text.trim();
    if (!enabled || generating || question.isEmpty) return;
    final progressIndex = widget.lessonIndex
        .clamp(0, lessons.length - 1)
        .toInt();
    final progressLesson = lessons[progressIndex];
    final attempt = messages.where((message) => message.isUser).length + 1;
    final recentConversation = messages
        .skip(messages.length > 6 ? messages.length - 6 : 0)
        .map(
          (message) =>
              '${message.isUser ? 'Learner' : widget.learner.buddyName}: ${message.text}',
        )
        .toList(growable: false);
    final retrievedChunks = LessonRetriever.fromPack(
      activeContentPack,
      lessonGuides,
    ).retrieve(question, currentTaskId: progressLesson.id);
    final retrievedContext = retrievedChunks
        .map((chunk) => '${chunk.title}: ${chunk.text}')
        .join('\n\n');
    var preparedExample = progressLesson.example;
    for (final task in activeContentPack?.tasks ?? const <ContentTask>[]) {
      if (task.id == progressLesson.id && task.examples.isNotEmpty) {
        preparedExample = task.examples.first['code'] ?? preparedExample;
      }
    }
    final levelMatch = RegExp(r'^L(\d+)-').firstMatch(progressLesson.id);
    final level = int.tryParse(levelMatch?.group(1) ?? '') ?? 1;
    final unlockedConcepts = <String>{
      for (final lesson in lessons)
        if (widget.learner.completed.contains(lesson.id)) lesson.title,
      progressLesson.title,
    }.toList();
    input.clear();
    setState(() {
      generating = true;
      messages.add(_TutorMessage(true, question));
      messages.add(_TutorMessage(false, '', loading: true));
    });
    _scrollToBottom();
    final response = StringBuffer();
    try {
      await for (final token in tutor.ask(
        question: question,
        level: level,
        module: progressLesson.module,
        unlockedConcepts: unlockedConcepts,
        customInstructions: widget.learner.tutorInstructions,
        attempt: attempt,
        preparedExample: preparedExample,
        retrievedLessonContext: retrievedContext,
        recentConversation: recentConversation,
        learnerName: widget.learner.username,
        buddyName: widget.learner.buddyName,
        language: widget.learner.language,
      )) {
        response.write(token);
        if (!mounted) return;
        setState(() {
          messages.last.text = response.toString();
          messages.last.loading = false;
        });
        _scrollToBottom();
      }
      if (response.isEmpty && mounted) {
        messages.last.text =
            'I couldn’t create a reply. Try asking in a different way.';
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          messages.last.text =
              'The on-device model could not answer that. You can retry or ask a shorter question.';
          messages.last.loading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
          messages.last.loading = false;
        });
      }
      _scrollToBottom();
    }
  }

  Future<void> _customizeTutor() async {
    final controller = TextEditingController(
      text: widget.learner.tutorInstructions,
    );
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make the tutor yours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell Easy Python how you like to learn. This preference is saved on this device.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 240,
              decoration: const InputDecoration(
                hintText:
                    'For example: Give short hints first, then a simple example.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _PreferenceChip(
                  label: 'Short answers',
                  onTap: () => controller.text =
                      'Keep answers short and use simple words.',
                ),
                _PreferenceChip(
                  label: 'More examples',
                  onTap: () => controller.text =
                      'Use extra everyday examples and explain them step by step.',
                ),
                _PreferenceChip(
                  label: 'Hints first',
                  onTap: () => controller.text =
                      'Give hints before showing a full solution.',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save style'),
          ),
        ],
      ),
    );
    if (saved != null) {
      widget.learner.tutorInstructions = saved;
      await widget.learner.save();
    }
    controller.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _TutorBubble extends StatelessWidget {
  const _TutorBubble({required this.message});
  final _TutorMessage message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: message.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF302B50)
                  : const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: primary,
              size: 17,
            ),
          ),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: message.isUser ? primary : context.appSurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(17),
                topRight: const Radius.circular(17),
                bottomLeft: Radius.circular(message.isUser ? 17 : 5),
                bottomRight: Radius.circular(message.isUser ? 5 : 17),
              ),
              border: message.isUser
                  ? null
                  : Border.all(color: context.appBorder),
            ),
            child: message.loading && message.text.isEmpty
                ? SizedBox(
                    width: 38,
                    height: 18,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: primary,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHigh,
                    ),
                  )
                : SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: message.isUser ? Colors.white : context.appText,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    backgroundColor: context.appSurface,
    side: BorderSide(color: context.appBorder),
    labelStyle: TextStyle(
      color: context.appText,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    backgroundColor: context.isDarkMode
        ? const Color(0xFF302B50)
        : const Color(0xFFEDEBFF),
    side: BorderSide.none,
    labelStyle: const TextStyle(
      color: primary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _TutorStatus extends StatelessWidget {
  const _TutorStatus({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.isDarkMode
          ? const Color(0xFF45262D)
          : const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 12, color: context.appText),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.learner,
    required this.onChanged,
  });
  final LearnerState learner;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      14,
      (i) => i < learner.streak && learner.streak > 0,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text(
            'Your profile',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: context.isDarkMode
                        ? const Color(0xFF263353)
                        : const Color(0xFFE6F0F9),
                    child: Text(
                      learner.username.isEmpty
                          ? 'P'
                          : learner.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        learner.username == 'friend'
                            ? 'Your name'
                            : learner.username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit your name',
                        onPressed: () => _editName(context),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      ),
                    ],
                  ),
                  Text(
                    learner.rank,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.appText,
                    ),
                  ),
                  Text(
                    '${learner.xp} XP earned',
                    style: TextStyle(color: context.appMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                        value: '${learner.streak}',
                        label: 'day streak',
                        icon: Icons.local_fire_department_rounded,
                        color: streakColor,
                      ),
                      _Stat(
                        value: '${learner.completed.length}',
                        label: 'lessons',
                        icon: Icons.menu_book_rounded,
                        color: primary,
                      ),
                      _Stat(
                        value: '${learner.seenReviews.length}',
                        label: 'reviews',
                        icon: Icons.auto_awesome_rounded,
                        color: success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Streak calendar'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: days
                    .map(
                      (active) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: active
                              ? (context.isDarkMode
                                    ? const Color(0xFF4D3319)
                                    : const Color(0xFFFFE5C8))
                              : (context.isDarkMode
                                    ? const Color(0xFF242844)
                                    : const Color(0xFFF0F3F7)),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          active ? Icons.check_rounded : Icons.circle_outlined,
                          size: 17,
                          color: active
                              ? streakColor
                              : (context.isDarkMode
                                    ? const Color(0xFF4C5274)
                                    : const Color(0xFFCBD2DC)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Skills'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  _SkillBar(
                    name: 'Getting started',
                    value: (learner.completed.length / 3).clamp(0.0, 1.0),
                  ),
                  _SkillBar(
                    name: 'Variables and data',
                    value:
                        (learner.completed
                                    .where(
                                      (id) =>
                                          id.compareTo('L1-04') >= 0 &&
                                          id.compareTo('L1-07') <= 0,
                                    )
                                    .length /
                                4)
                            .clamp(0.0, 1.0),
                  ),
                  _SkillBar(
                    name: 'Decisions',
                    value:
                        (learner.completed
                                    .where(
                                      (id) =>
                                          id.compareTo('L1-08') >= 0 &&
                                          id.compareTo('L1-11') <= 0,
                                    )
                                    .length /
                                4)
                            .clamp(0.0, 1.0),
                  ),
                  _SkillBar(
                    name: 'Loops',
                    value:
                        (learner.completed
                                    .where((id) => id.compareTo('L1-12') >= 0)
                                    .length /
                                5)
                            .clamp(0.0, 1.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Badges'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    label: 'First steps',
                    earned: learner.completed.isNotEmpty,
                    icon: Icons.flag_rounded,
                  ),
                  _Badge(
                    label: 'Practice pal',
                    earned: learner.seenReviews.isNotEmpty,
                    icon: Icons.auto_awesome_rounded,
                  ),
                  _Badge(
                    label: 'Week streak',
                    earned: learner.streak >= 7,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: primary),
            title: const Text('Learning goal'),
            subtitle: Text('${learner.goal} · ${learner.dailyTime} a day'),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: primary),
            title: const Text('Learning buddy'),
            subtitle: Text(learner.buddyName),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: primary),
            title: const Text('Appearance'),
            subtitle: const Text('Choose light, dark, or follow your device'),
            trailing: DropdownButton<ThemeMode>(
              value: learner.themeMode,
              dropdownColor: context.appSurface,
              onChanged: (mode) async {
                if (mode == null) return;
                learner.themeMode = mode;
                await learner.save();
                onChanged();
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(
      text: learner.username == 'friend' ? '' : learner.username,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What should your tutor call you?'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: 24,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'First name or nickname',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      learner.username = name.trim();
      await learner.save();
      onChanged();
    }
    controller.dispose();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: context.appText,
        ),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: context.appMuted)),
    ],
  );
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.name, required this.value});
  final String name;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.appText,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: context.appMuted),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: success,
            backgroundColor: context.appSubtle,
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.earned, required this.icon});
  final String label;
  final bool earned;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(
      icon,
      size: 17,
      color: earned
          ? streakColor
          : (context.isDarkMode ? const Color(0xFF7E86A6) : Colors.blueGrey),
    ),
    label: Text(label),
    backgroundColor: earned
        ? (context.isDarkMode
              ? const Color(0xFF3D2F1B)
              : const Color(0xFFFFF3E4))
        : (context.isDarkMode
              ? const Color(0xFF242844)
              : const Color(0xFFF0F3F6)),
    side: BorderSide(
      color: context.isDarkMode
          ? (earned ? const Color(0xFF5E492B) : context.appBorder)
          : (earned ? const Color(0xFFFFE0B8) : const Color(0xFFE2E7EE)),
    ),
    labelStyle: TextStyle(
      color: earned
          ? (context.isDarkMode ? const Color(0xFFFFD36A) : ink)
          : (context.isDarkMode ? const Color(0xFF9CA4C2) : Colors.blueGrey),
      fontWeight: FontWeight.w600,
    ),
  );
}
