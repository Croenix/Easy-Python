import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/content_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the 4-stage Python mastery roadmap content pack', () async {
    final pack = await ContentPackLoader().load(
      'assets/content/en/python-v1.json',
    );

    expect(pack.id, 'python-core-en');
    expect(pack.version, 1);
    expect(pack.stages.length, 4);
    expect(pack.stages[0].title, contains('Foundations'));
    expect(pack.stages[1].title, contains('Intermediate'));
    expect(pack.stages[2].title, contains('Advanced'));
    expect(pack.stages[3].title, contains('Mastery'));

    // Stage 1 has 7 topics and 2 projects
    expect(pack.stages[0].tasks.length, 7);
    expect(pack.stages[0].projects.length, 2);
    expect(pack.stages[0].tasks.first.title, 'Introduction');
    expect(pack.stages[0].tasks[1].title, contains('Variables'));
    expect(pack.stages[0].tasks[2].title, contains('Operators'));
    expect(pack.stages[0].tasks[3].title, contains('Loops'));
    expect(pack.stages[0].tasks[4].title, 'Strings');
    expect(pack.stages[0].tasks[5].title, contains('Lists'));
    expect(pack.stages[0].tasks[6].title, 'Functions');

    // Stage 4 has tracks
    expect(pack.stages[3].tracks.length, 5);
    expect(pack.stages[3].tracks.map((t) => t.id).toList(), [
      'web',
      'data',
      'automation',
      'ai_ml',
      'security',
    ]);

    expect(pack.tasks.first.practicals.first.type, 'multipleChoice');
    expect(pack.tasks.first.project['steps'], isA<List>());
    expect(pack.guides['L1-01']?.friendProblem, contains('{name}'));
  });

  test('rejects unsupported content pack schemas', () {
    expect(
      () => ContentPack.fromJson({'schemaVersion': 99}),
      throwsFormatException,
    );
  });
}
