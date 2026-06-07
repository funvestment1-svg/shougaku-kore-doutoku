import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

@JsonSerializable()
class NotificationPreferences {
  final bool emailNotificationsEnabled;
  final String emailFrequency; // "weekly", "biweekly", "monthly", "custom"
  final List<int> customEmailDays; // [0=日, 1=月, ..., 6=土]
  final String emailTime; // "HH:mm" format (e.g., "18:00")
  final String emailTimeZone; // "Asia/Tokyo", "America/New_York", etc.
  final bool fcmNotificationsEnabled;
  final DateTime updatedAt;

  NotificationPreferences({
    this.emailNotificationsEnabled = true,
    this.emailFrequency = 'weekly',
    this.customEmailDays = const [],
    this.emailTime = '18:00',
    this.emailTimeZone = 'Asia/Tokyo',
    this.fcmNotificationsEnabled = true,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  // Copyメソッド
  NotificationPreferences copyWith({
    bool? emailNotificationsEnabled,
    String? emailFrequency,
    List<int>? customEmailDays,
    String? emailTime,
    String? emailTimeZone,
    bool? fcmNotificationsEnabled,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      emailFrequency: emailFrequency ?? this.emailFrequency,
      customEmailDays: customEmailDays ?? this.customEmailDays,
      emailTime: emailTime ?? this.emailTime,
      emailTimeZone: emailTimeZone ?? this.emailTimeZone,
      fcmNotificationsEnabled:
          fcmNotificationsEnabled ?? this.fcmNotificationsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // デフォルト値で初期化
  static NotificationPreferences defaultPreferences() => NotificationPreferences(
        updatedAt: DateTime.now(),
      );
}
