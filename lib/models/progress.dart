import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

@JsonSerializable()
class Progress {
  final String id;
  final String childId;
  final String? storyId;
  final String action;        // "story_completed", etc.
  final int pointsDelta;
  final DateTime recordedAt;  // バックエンドの recorded_at

  Progress({
    required this.id,
    required this.childId,
    this.storyId,
    required this.action,
    this.pointsDelta = 0,
    required this.recordedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}
