import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';

void main() {
  group('Progress model', () {
    final progressJson = {
      'id': 'prog-1',
      'childId': 'child-1',
      'storyId': 'story-1',
      'action': 'story_completed',
      'pointsDelta': 10,
      'recordedAt': '2024-03-15T10:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final p = Progress.fromJson(progressJson);
      expect(p.id, 'prog-1');
      expect(p.childId, 'child-1');
      expect(p.storyId, 'story-1');
      expect(p.action, 'story_completed');
      expect(p.pointsDelta, 10);
      expect(p.recordedAt, DateTime.parse('2024-03-15T10:00:00.000Z'));
    });

    test('fromJson with null storyId', () {
      final json = Map<String, dynamic>.from(progressJson)
        ..['storyId'] = null;
      final p = Progress.fromJson(json);
      expect(p.storyId, isNull);
    });

    test('fromJson with missing pointsDelta defaults to 0', () {
      final json = Map<String, dynamic>.from(progressJson)
        ..remove('pointsDelta');
      final p = Progress.fromJson(json);
      expect(p.pointsDelta, 0);
    });

    test('toJson produces expected keys', () {
      final p = Progress.fromJson(progressJson);
      final json = p.toJson();
      expect(json['id'], 'prog-1');
      expect(json['childId'], 'child-1');
      expect(json['storyId'], 'story-1');
      expect(json['action'], 'story_completed');
      expect(json['pointsDelta'], 10);
    });

    test('toJson / fromJson round-trip via JSON string', () {
      final p = Progress.fromJson(progressJson);
      final str = jsonEncode(p.toJson());
      final p2 = Progress.fromJson(jsonDecode(str) as Map<String, dynamic>);
      expect(p2.id, p.id);
      expect(p2.childId, p.childId);
      expect(p2.action, p.action);
      expect(p2.pointsDelta, p.pointsDelta);
    });

    test('constructor default pointsDelta is 0', () {
      final p = Progress(
        id: 'x',
        childId: 'c',
        action: 'test',
        recordedAt: DateTime(2024),
      );
      expect(p.pointsDelta, 0);
      expect(p.storyId, isNull);
    });
  });
}
