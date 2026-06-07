import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String uid;
  final String email;
  final String displayName;
  final List<String> childrenIds;
  final String role; // "parent"
  final SubscriptionInfo subscription;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.childrenIds,
    this.role = "parent",
    required this.subscription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class SubscriptionInfo {
  final String plan; // "free" | "plus_980"
  final String status; // "active" | "cancelled"
  final DateTime? startDate;
  final DateTime? renewalDate;

  SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startDate,
    this.renewalDate,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionInfoToJson(this);
}
