import 'package:json_annotation/json_annotation.dart';

part 'story.g.dart';

@JsonSerializable()
class Story {
  final String id;
  final String title;
  final String? description; // プレビュー用テキスト (一覧エンドポイントで返される)
  final String theme; // "kindness", "honesty", "courage", etc.
  final int gradeLevel; // 3-4
  final int difficulty; // 1-3 (難易度)
  final bool isPremium;
  // content is null when loaded from the list endpoint (loaded on detail fetch)
  final StoryContent? content;
  final int durationSeconds;
  final String? illustrationUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Story({
    required this.id,
    required this.title,
    this.description,
    required this.theme,
    required this.gradeLevel,
    this.difficulty = 1,
    required this.isPremium,
    this.content,
    required this.durationSeconds,
    this.illustrationUrl,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);
}

@JsonSerializable()
class StoryContent {
  final String introduction;
  final List<String> mainNarrative;
  final String dilemmaScene;
  final List<StoryChoice> choices;
  final String? illustrationUrl;

  StoryContent({
    required this.introduction,
    required this.mainNarrative,
    required this.dilemmaScene,
    required this.choices,
    this.illustrationUrl,
  });

  factory StoryContent.fromJson(Map<String, dynamic> json) =>
      _$StoryContentFromJson(json);
  Map<String, dynamic> toJson() => _$StoryContentToJson(this);
}

@JsonSerializable()
class StoryChoice {
  final String id;
  final String text;
  final String? value; // "kindness", "honesty", "courage", etc. (nullable from API)
  final String branchContent;
  final String reflection;

  StoryChoice({
    required this.id,
    required this.text,
    this.value,
    required this.branchContent,
    required this.reflection,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) =>
      _$StoryChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$StoryChoiceToJson(this);
}
