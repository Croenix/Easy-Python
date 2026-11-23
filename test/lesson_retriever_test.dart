import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/content_pack.dart';
import 'package:pypath/lesson_content.dart';
import 'package:pypath/lesson_retriever.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retrieves at most three short lesson chunks for the current task',
    () async {
      final pack = await ContentPackLoader().load(
        'assets/content/en/python-v1.json',
      );
      final retriever = LessonRetriever.fromPack(pack, lessonGuides);
      final results = retriever.retrieve(
        'How can I show a welcome message with print?',
        currentTaskId: 'L1-01',
      );

      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(3));
      expect(results.first.taskId, 'L1-01');
      expect(
        results.every(
          (chunk) => chunk.text.split(RegExp(r'\s+')).length <= 120,
        ),
        isTrue,
      );
    },
  );

  test(
    'falls back to the current task when there is no lexical match',
    () async {
      final pack = await ContentPackLoader().load(
        'assets/content/en/python-v1.json',
      );
      final retriever = LessonRetriever.fromPack(
        pack,
        const <String, LessonGuide>{},
      );
      final results = retriever.retrieve('zzqxv', currentTaskId: 'L1-02');
      expect(results, isNotEmpty);
      expect(results.every((chunk) => chunk.taskId == 'L1-02'), isTrue);
    },
  );
}
