import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class MonthlyReport {
  final String id;
  final String childId;
  final int month;
  final int year;

  // 学習統計
  @JsonKey(defaultValue: 0)
  final int storiesCompleted;
  @JsonKey(defaultValue: 0)
  final int totalStudyMinutes;
  @JsonKey(defaultValue: 0)
  final int totalPointsEarned;

  // 徳目スコア
  @JsonKey(defaultValue: 50.0)
  final double kindnessScore;
  @JsonKey(defaultValue: 50.0)
  final double honestyScore;
  @JsonKey(defaultValue: 50.0)
  final double responsibilityScore;
  @JsonKey(defaultValue: 50.0)
  final double courageScore;
  @JsonKey(defaultValue: 50.0)
  final double respectScore;
  @JsonKey(defaultValue: 50.0)
  final double cooperationScore;

  // AIコメント
  final String? highlightComment;
  final String? growthComment;
  final String? adviceComment;
  final String? parentMessage;

  final DateTime generatedAt;

  // 後方互換性のため旧フィールドを保持
  final PatternScores? patternScores;
  final List<TopImpression> topImpressions;

  MonthlyReport({
    required this.id,
    required this.childId,
    required this.month,
    required this.year,
    this.storiesCompleted = 0,
    this.totalStudyMinutes = 0,
    this.totalPointsEarned = 0,
    this.kindnessScore = 50.0,
    this.honestyScore = 50.0,
    this.responsibilityScore = 50.0,
    this.courageScore = 50.0,
    this.respectScore = 50.0,
    this.cooperationScore = 50.0,
    this.highlightComment,
    this.growthComment,
    this.adviceComment,
    this.parentMessage,
    required this.generatedAt,
    this.patternScores,
    this.topImpressions = const [],
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyReportToJson(this);
}

@JsonSerializable()
class PatternScores {
  final double compassion; // 0-100
  final double fairness;
  final double responsibility;
  final double challenge;

  PatternScores({
    required this.compassion,
    required this.fairness,
    required this.responsibility,
    required this.challenge,
  });

  factory PatternScores.fromJson(Map<String, dynamic> json) =>
      _$PatternScoresFromJson(json);
  Map<String, dynamic> toJson() => _$PatternScoresToJson(this);
}

@JsonSerializable()
class TopImpression {
  final String storyId;
  final String storyTitle;
  final String choiceMade;
  final String valueReflected;
  final String parentQuestion;

  TopImpression({
    required this.storyId,
    required this.storyTitle,
    required this.choiceMade,
    required this.valueReflected,
    required this.parentQuestion,
  });

  factory TopImpression.fromJson(Map<String, dynamic> json) =>
      _$TopImpressionFromJson(json);
  Map<String, dynamic> toJson() => _$TopImpressionToJson(this);
}
