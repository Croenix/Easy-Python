import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/content_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the versioned first three W3Schools-style tasks', () async {
    final pack = await ContentPackLoader().load(
      'assets/content/en/python-v1.json',
    );

    expect(pack.id, 'python-core-en');
    expect(pack.version, 1);
    expect(pack.tasks.map((task) => task.title).toList(), [
      'Introduction',
      'Get Started',
      'Syntax',
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
