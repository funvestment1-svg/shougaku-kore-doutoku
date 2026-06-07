import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String storyId;
  final int questionNumber;
  final String text;
  final List<QuestionOption> options;
  final String correctAnswerId;
  final String explanation;
  final List<String> keywords;

  Question({
    required this.id,
    required this.storyId,
    required this.questionNumber,
    required this.text,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
    required this.keywords,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}

@JsonSerializable()
class QuestionOption {
  final String id;
  final String label;
  final String text;

  QuestionOption({
    required this.id,
    required this.label,
    required this.text,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}
