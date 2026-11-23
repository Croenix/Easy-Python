import 'dart:convert';

import 'package:flutter/services.dart';

import 'lesson_content.dart';

class PracticalItem {
  const PracticalItem({
    required this.id,
    required this.type,
    required this.prompt,
    this.difficulty = 1,
    this.options = const [],
    this.answer,
    this.requiredKeywords = const [],
    this.tests = const [],
  });

  final String id;
  final String type;
  final String prompt;
  final int difficulty;
  final List<String> options;
  final String? answer;
  final List<String> requiredKeywords;
  final List<Map<String, dynamic>> tests;

  factory PracticalItem.fromJson(Map<String, dynamic> json) => PracticalItem(
    id: _requiredString(json, 'id'),
    type: _requiredString(json, 'type'),
    prompt: _requiredString(json, 'prompt'),
    difficulty: (json['difficulty'] as int? ?? 1).clamp(1, 5).toInt(),
    options: _stringList(json['options']),
    answer: json['answer'] as String?,
    requiredKeywords: _stringList(json['requiredKeywords']),
    tests: json['tests'] is List
        ? (json['tests'] as List)
              .map((test) => Map<String, dynamic>.from(test as Map))
              .toList(growable: false)
        : const [],
  );
}

class ContentTask {
  const ContentTask({
    required this.id,
    required this.title,
    required this.order,
    required this.minutes,
    required this.overview,
    required this.lesson,
    required this.examples,
    required this.practicals,
    required this.project,
  });

  final String id;
  final String title;
  final int order;
  final int minutes;
  final String overview;
  final List<Map<String, String>> lesson;
  final List<Map<String, String>> examples;
  final List<PracticalItem> practicals;
  final Map<String, dynamic> project;

  LessonGuide toGuide() => LessonGuide(
    plainLanguage: overview,
    whyItMatters: lesson.first['body'] ?? '',
    walkThrough: lesson.length > 1 ? lesson[1]['body']! : lesson.first['body']!,
    watchOut: lesson.length > 2 ? lesson[2]['body']! : lesson.first['body']!,
    topicTakeaway: lesson.last['body'] ?? '',
    friendProblem: project['friendPrompt'] as String? ?? '',
  );

  factory ContentTask.fromJson(Map<String, dynamic> json) => ContentTask(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    order: json['order'] as int,
    minutes: json['minutes'] as int,
    overview: _requiredString(json, 'overview'),
    lesson: _sectionList(json['lesson']),
    examples: _sectionList(json['examples']),
    practicals: (json['practicals'] as List)
        .map((item) => PracticalItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    project: Map<String, dynamic>.from(json['project'] as Map),
  );
}

class ContentPack {
  const ContentPack({
    required this.id,
    required this.version,
    required this.language,
    required this.tasks,
  });

  final String id;
  final int version;
  final String language;
  final List<ContentTask> tasks;

  Map<String, LessonGuide> get guides => {
    for (final task in tasks) task.id: task.toGuide(),
  };

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported content pack schema version.');
    }
    final tasks =
        (json['tasks'] as List)
            .map((task) => ContentTask.fromJson(task as Map<String, dynamic>))
            .toList(growable: false)
          ..sort((a, b) => a.order.compareTo(b.order));
    if (tasks.map((task) => task.id).toSet().length != tasks.length) {
      throw const FormatException('Content task ids must be unique.');
    }
    return ContentPack(
      id: _requiredString(json, 'id'),
      version: json['version'] as int,
      language: _requiredString(json, 'language'),
      tasks: tasks,
    );
  }
}

class ContentPackLoader {
  ContentPackLoader({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;
  final AssetBundle assetBundle;

  Future<ContentPack> load(String assetPath) async {
    final raw = await assetBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Content pack must be a JSON object.');
    }
    return ContentPack.fromJson(decoded);
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Content pack field "$key" must be a string.');
  }
  return value;
}

List<String> _stringList(Object? value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];

List<Map<String, String>> _sectionList(Object? value) {
  if (value is! List) throw const FormatException('Expected a content list.');
  return value
      .map((entry) {
        if (entry is! Map) {
          throw const FormatException('Expected a content item.');
        }
        return entry.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      })
      .toList(growable: false);
}
