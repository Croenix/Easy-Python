import 'content_pack.dart';
import 'lesson_content.dart';

class LessonChunk {
  const LessonChunk({
    required this.taskId,
    required this.title,
    required this.text,
  });

  final String taskId;
  final String title;
  final String text;
}

/// Offline first-pass lesson retrieval. It keeps chunks short and returns up to
/// three relevant passages; an embedding ranker can be swapped in later.
class LessonRetriever {
  LessonRetriever._(this.chunks);

  final List<LessonChunk> chunks;

  factory LessonRetriever.fromPack(
    ContentPack? pack,
    Map<String, LessonGuide> legacyGuides,
  ) {
    final all = <LessonChunk>[];
    final included = <String>{};
    for (final task in pack?.tasks ?? const <ContentTask>[]) {
      final paragraphs = <String>[
        task.overview,
        for (final section in task.lesson)
          '${section['heading'] ?? ''}: ${section['body'] ?? ''}',
        for (final example in task.examples)
          '${example['title'] ?? ''}: ${example['explanation'] ?? ''} Code: ${example['code'] ?? ''}',
        task.project['scenario'] as String? ?? '',
      ].where((item) => item.trim().isNotEmpty).toList();
      all.addAll(_chunk(task.id, task.title, paragraphs));
      included.add(task.id);
    }
    for (final entry in legacyGuides.entries) {
      if (included.contains(entry.key)) continue;
      final guide = entry.value;
      all.addAll(
        _chunk(entry.key, entry.key, [
          guide.plainLanguage,
          guide.whyItMatters,
          guide.walkThrough,
          guide.watchOut,
          guide.topicTakeaway,
        ]),
      );
    }
    return LessonRetriever._(all);
  }

  List<LessonChunk> retrieve(
    String query, {
    String? currentTaskId,
    int limit = 3,
  }) {
    final terms = _terms(query);
    if (terms.isEmpty || chunks.isEmpty) return const [];
    final ranked = chunks.map((chunk) {
      final words = _terms(chunk.text);
      final overlap = terms.intersection(words).length;
      final coverage = overlap / terms.length;
      final density = overlap / words.length.clamp(1, 999999);
      final currentBoost = chunk.taskId == currentTaskId ? 2.0 : 0;
      return (chunk: chunk, score: coverage + density + currentBoost);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final relevant = ranked.where((item) => item.score > 0).take(limit);
    if (relevant.isNotEmpty) return relevant.map((item) => item.chunk).toList();
    return ranked
        .where((item) => item.chunk.taskId == currentTaskId)
        .take(limit)
        .map((item) => item.chunk)
        .toList();
  }

  static List<LessonChunk> _chunk(
    String taskId,
    String title,
    List<String> paragraphs,
  ) {
    const maxWords = 120;
    final result = <LessonChunk>[];
    var current = <String>[];
    for (final paragraph in paragraphs) {
      final words = paragraph.split(RegExp(r'\s+'));
      for (var offset = 0; offset < words.length; offset += maxWords) {
        final piece = words.skip(offset).take(maxWords).join(' ');
        if (current.join(' ').split(RegExp(r'\s+')).length +
                    piece.split(' ').length >
                maxWords &&
            current.isNotEmpty) {
          result.add(
            LessonChunk(taskId: taskId, title: title, text: current.join(' ')),
          );
          current = [];
        }
        current.add(piece);
      }
    }
    if (current.isNotEmpty) {
      result.add(
        LessonChunk(taskId: taskId, title: title, text: current.join(' ')),
      );
    }
    return result;
  }

  static Set<String> _terms(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_ ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 1)
      .toSet();
}
