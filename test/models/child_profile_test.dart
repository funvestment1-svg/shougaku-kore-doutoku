import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';

void main() {
  group('ChildProfile', () {
    late ChildProfile profile;

    setUp(() {
      profile = ChildProfile(
        id: 'test-id',
        parentId: 'parent-id',
        name: 'テスト太郎',
        grade: 3,
        avatarEmoji: '🦁',
        createdAt: DateTime(2026, 1, 1),
        level: 5,
        totalPoints: 450,
        kindnessScore: 75.0,
        honestyScore: 60.0,
        responsibilityScore: 80.0,
        courageScore: 55.0,
        respectScore: 70.0,
        cooperationScore: 65.0,
      );
    });

    test('gradeDisplayName returns correct string', () {
      expect(profile.gradeDisplayName, '小学3年生');
    });

    test('avatarEmoji is set correctly', () {
      expect(profile.avatarEmoji, '🦁');
    });

    test('virtue scores are accessible', () {
      expect(profile.kindnessScore, 75.0);
      expect(profile.responsibilityScore, 80.0);
    });

    test('level and totalPoints are set correctly', () {
      expect(profile.level, 5);
      expect(profile.totalPoints, 450);
    });

    test('JSON serialization round-trip', () {
      final json = profile.toJson();
      final restored = ChildProfile.fromJson(json);
      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.kindnessScore, profile.kindnessScore);
      expect(restored.level, profile.level);
      expect(restored.avatarEmoji, profile.avatarEmoji);
    });

    test('default virtue scores are 50.0', () {
      final minimal = ChildProfile(
        id: 'x',
        parentId: 'p',
        name: 'Test',
        grade: 4,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(minimal.kindnessScore, 50.0);
      expect(minimal.cooperationScore, 50.0);
      expect(minimal.level, 1);
      expect(minimal.totalPoints, 0);
      expect(minimal.avatarEmoji, '🌟'); // default
    });

    test('grade 4 display name', () {
      final grade4 = ChildProfile(
        id: 'x',
        parentId: 'p',
        name: 'Test',
        grade: 4,
        avatarEmoji: '🐯',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(grade4.gradeDisplayName, '小学4年生');
      expect(grade4.avatarEmoji, '🐯');
    });

    test('fromApiJson parses backend response with nested virtueScores', () {
      final apiJson = {
        'id': 'api-id',
        'parentId': 'parent-api',
        'name': 'API太郎',
        'grade': 3,
        'avatarEmoji': '🌟',
        'level': 2,
        'totalPoints': 120,
        'virtueScores': {
          'kindness': 65.0,
          'honesty': 70.0,
          'responsibility': 55.0,
          'courage': 80.0,
          'respect': 60.0,
          'cooperation': 75.0,
        },
        'createdAt': '2026-01-01T00:00:00',
      };
      final p = ChildProfile.fromApiJson(apiJson);
      expect(p.id, 'api-id');
      expect(p.kindnessScore, 65.0);
      expect(p.courageScore, 80.0);
      expect(p.level, 2);
      expect(p.totalPoints, 120);
    });
  });
}
