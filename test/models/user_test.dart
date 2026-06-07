import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/user.dart';

void main() {
  group('User model', () {
    final subscriptionJson = {
      'plan': 'plus_980',
      'status': 'active',
      'startDate': '2024-01-01T00:00:00.000Z',
      'renewalDate': '2024-04-01T00:00:00.000Z',
    };

    final userJson = {
      'uid': 'uid-123',
      'email': 'parent@example.com',
      'displayName': '保護者 太郎',
      'childrenIds': ['child-1', 'child-2'],
      'role': 'parent',
      'subscription': subscriptionJson,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-03-15T00:00:00.000Z',
    };

    group('SubscriptionInfo', () {
      test('fromJson parses correctly', () {
        final sub = SubscriptionInfo.fromJson(subscriptionJson);
        expect(sub.plan, 'plus_980');
        expect(sub.status, 'active');
        expect(sub.startDate, DateTime.parse('2024-01-01T00:00:00.000Z'));
        expect(sub.renewalDate, DateTime.parse('2024-04-01T00:00:00.000Z'));
      });

      test('fromJson with null dates', () {
        final json = {
          'plan': 'free',
          'status': 'active',
          'startDate': null,
          'renewalDate': null,
        };
        final sub = SubscriptionInfo.fromJson(json);
        expect(sub.plan, 'free');
        expect(sub.startDate, isNull);
        expect(sub.renewalDate, isNull);
      });

      test('toJson round-trip', () {
        final sub = SubscriptionInfo.fromJson(subscriptionJson);
        final str = jsonEncode(sub.toJson());
        final sub2 = SubscriptionInfo.fromJson(
            jsonDecode(str) as Map<String, dynamic>);
        expect(sub2.plan, sub.plan);
        expect(sub2.status, sub.status);
      });
    });

    group('User', () {
      test('fromJson parses correctly', () {
        final u = User.fromJson(userJson);
        expect(u.uid, 'uid-123');
        expect(u.email, 'parent@example.com');
        expect(u.displayName, '保護者 太郎');
        expect(u.childrenIds, ['child-1', 'child-2']);
        expect(u.role, 'parent');
        expect(u.subscription.plan, 'plus_980');
        expect(u.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      });

      test('role defaults to "parent" when missing', () {
        final json = Map<String, dynamic>.from(userJson)..remove('role');
        final u = User.fromJson(json);
        expect(u.role, 'parent');
      });

      test('fromJson with empty childrenIds', () {
        final json = Map<String, dynamic>.from(userJson)
          ..['childrenIds'] = <String>[];
        final u = User.fromJson(json);
        expect(u.childrenIds, isEmpty);
      });

      test('toJson / fromJson round-trip', () {
        final u = User.fromJson(userJson);
        final str = jsonEncode(u.toJson());
        final u2 = User.fromJson(jsonDecode(str) as Map<String, dynamic>);
        expect(u2.uid, u.uid);
        expect(u2.email, u.email);
        expect(u2.childrenIds.length, u.childrenIds.length);
        expect(u2.subscription.plan, u.subscription.plan);
      });
    });
  });
}
