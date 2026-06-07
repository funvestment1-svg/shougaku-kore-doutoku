import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';

void main() {
  group('Story model', () {
    final storyJson = {
      'id': 'story-1',
      'title': 'テストストーリー',
      'description': 'ストーリーの説明',
      'theme': 'kindness',
      'gradeLevel': 3,
      'difficulty': 2,
      'isPremium': false,
      'content': {
        'introduction': 'ストーリーの始まり',
        'mainNarrative': ['第一段落', '第二段落'],
        'dilemmaScene': 'どうすれば良いでしょう？',
        'choices': [
          {
            'id': 'A',
            'text': '選択肢A',
            'value': 'kindness',
            'branchContent': 'Aの展開',
            'reflection': 'Aについての考え',
          },
        ],
      },
      'durationSeconds': 300,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final story = Story.fromJson(storyJson);
      expect(story.id, 'story-1');
      expect(story.title, 'テストストーリー');
      expect(story.description, 'ストーリーの説明');
      expect(story.theme, 'kindness');
      expect(story.isPremium, false);
      expect(story.gradeLevel, 3);
      expect(story.difficulty, 2);
      expect(story.content!.introduction, 'ストーリーの始まり');
      expect(story.content!.mainNarrative.length, 2);
      expect(story.content!.choices.length, 1);
      expect(story.content!.choices.first.id, 'A');
    });

    test('toJson / fromJson round-trip via JSON string', () {
      final story = Story.fromJson(storyJson);
      // Full round-trip via JSON string (handles nested object serialization)
      final jsonStr = jsonEncode(story.toJson());
      final json2 = jsonDecode(jsonStr) as Map<String, dynamic>;
      final story2 = Story.fromJson(json2);
      expect(story2.id, story.id);
      expect(story2.title, story.title);
      expect(story2.theme, story.theme);
    });
  });
}
