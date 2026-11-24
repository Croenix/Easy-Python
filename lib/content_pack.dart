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
    this.aiExplanation,
    this.scenario,
    this.commandPrompt,
  });

  final String id;
  final String type;
  final String prompt;
  final int difficulty;
  final List<String> options;
  final String? answer;
  final List<String> requiredKeywords;
  final List<Map<String, dynamic>> tests;
  final String? aiExplanation;
  final String? scenario;
  final String? commandPrompt;

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
    aiExplanation: json['aiExplanation'] as String?,
    scenario: json['scenario'] as String?,
    commandPrompt: json['commandPrompt'] as String?,
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
    this.stageId = 'stage-1',
    this.subtitle = '',
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
  final String stageId;
  final String subtitle;

  LessonGuide toGuide() => LessonGuide(
    plainLanguage: overview,
    whyItMatters: lesson.isNotEmpty ? (lesson.first['body'] ?? '') : overview,
    walkThrough: lesson.length > 1 ? (lesson[1]['body'] ?? '') : (lesson.isNotEmpty ? lesson.first['body']! : overview),
    watchOut: lesson.length > 2 ? (lesson[2]['body'] ?? '') : (lesson.isNotEmpty ? lesson.first['body']! : overview),
    topicTakeaway: lesson.isNotEmpty ? (lesson.last['body'] ?? '') : overview,
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
    practicals: (json['practicals'] as List? ?? const [])
        .map((item) => PracticalItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    project: Map<String, dynamic>.from((json['project'] as Map?) ?? const {}),
    stageId: json['stageId'] as String? ?? 'stage-1',
    subtitle: json['subtitle'] as String? ?? '',
  );
}

class CourseTrack {
  const CourseTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.technologies = const [],
    required this.capstone,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final List<String> technologies;
  final Map<String, dynamic> capstone;

  factory CourseTrack.fromJson(Map<String, dynamic> json) => CourseTrack(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    subtitle: json['subtitle'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? 'web',
    technologies: _stringList(json['technologies']),
    capstone: json['capstone'] is Map
        ? Map<String, dynamic>.from(json['capstone'] as Map)
        : const {},
  );
}

class CourseStage {
  const CourseStage({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.estimatedHours,
    this.badge = 'rocket',
    required this.tasks,
    this.projects = const [],
    this.tracks = const [],
  });

  final String id;
  final int stageNumber;
  final String title;
  final String subtitle;
  final int estimatedHours;
  final String badge;
  final List<ContentTask> tasks;
  final List<Map<String, dynamic>> projects;
  final List<CourseTrack> tracks;

  factory CourseStage.fromJson(Map<String, dynamic> json) => CourseStage(
    id: _requiredString(json, 'id'),
    stageNumber: json['stageNumber'] as int? ?? 1,
    title: _requiredString(json, 'title'),
    subtitle: json['subtitle'] as String? ?? '',
    estimatedHours: json['estimatedHours'] as int? ?? 5,
    badge: json['badge'] as String? ?? 'rocket',
    tasks: json['tasks'] is List
        ? (json['tasks'] as List)
            .map((task) => ContentTask.fromJson(task as Map<String, dynamic>))
            .toList(growable: false)
        : const [],
    projects: json['projects'] is List
        ? (json['projects'] as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList(growable: false)
        : const [],
    tracks: json['tracks'] is List
        ? (json['tracks'] as List)
            .map((t) => CourseTrack.fromJson(t as Map<String, dynamic>))
            .toList(growable: false)
        : const [],
  );
}

class ContentPack {
  const ContentPack({
    required this.id,
    required this.version,
    required this.language,
    this.course,
    this.stages = const [],
    required this.tasks,
  });

  final String id;
  final int version;
  final String language;
  final String? course;
  final List<CourseStage> stages;
  final List<ContentTask> tasks;

  Map<String, LessonGuide> get guides => {
    for (final task in tasks) task.id: task.toGuide(),
  };

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 && json['schemaVersion'] != 2) {
      throw const FormatException('Unsupported content pack schema version.');
    }

    final stages = json['stages'] is List
        ? (json['stages'] as List)
            .map((stage) => CourseStage.fromJson(stage as Map<String, dynamic>))
            .toList(growable: false)
        : const <CourseStage>[];

    final List<ContentTask> parsedTasks;
    if (json['tasks'] is List && (json['tasks'] as List).isNotEmpty) {
      parsedTasks = (json['tasks'] as List)
          .map((task) => ContentTask.fromJson(task as Map<String, dynamic>))
          .toList(growable: false);
    } else {
      parsedTasks = [for (final s in stages) ...s.tasks];
    }

    parsedTasks.sort((a, b) => a.order.compareTo(b.order));
    if (parsedTasks.map((task) => task.id).toSet().length != parsedTasks.length) {
      throw const FormatException('Content task ids must be unique.');
    }

    return ContentPack(
      id: _requiredString(json, 'id'),
      version: json['version'] as int? ?? 1,
      language: _requiredString(json, 'language'),
      course: json['course'] as String?,
      stages: stages,
      tasks: parsedTasks,
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
  if (value is! List) return const [];
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
