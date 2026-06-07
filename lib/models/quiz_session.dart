import 'package:json_annotation/json_annotation.dart';

part 'quiz_session.g.dart';

@JsonSerializable()
class QuizSession {
  final String id;
  final String storyId;
  final String childId;
  final List<QuizAnswer> answers;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalTimeSeconds;
  final int pointsEarned;
  final String reflectionNotes;

  QuizSession({
    required this.id,
    required this.storyId,
    required this.childId,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    required this.totalTimeSeconds,
    required this.pointsEarned,
    required this.reflectionNotes,
  });

  /// スコアを百分率で計算
  int get score {
    if (answers.isEmpty) return 0;
    final correctCount = answers.where((a) => a.isCorrect).length;
    return ((correctCount / answers.length) * 100).toInt();
  }

  /// クイズ完了判定
  bool get isCompleted => completedAt != null;

  factory QuizSession.fromJson(Map<String, dynamic> json) =>
      _$QuizSessionFromJson(json);

  Map<String, dynamic> toJson() => _$QuizSessionToJson(this);
}

@JsonSerializable()
class QuizAnswer {
  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime answeredAt;

  QuizAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.answeredAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerToJson(this);
}
