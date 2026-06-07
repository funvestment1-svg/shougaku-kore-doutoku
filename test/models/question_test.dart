import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/question.dart';

void main() {
  group('Question model', () {
    final optionJson = {
      'id': 'opt-A',
      'label': 'A',
      'text': '選択肢Aのテキスト',
    };

    final questionJson = {
      'id': 'q-1',
      'storyId': 'story-1',
      'questionNumber': 1,
      'text': '問題文テキスト',
      'options': [optionJson],
      'correctAnswerId': 'opt-A',
      'explanation': '説明テキスト',
      'keywords': ['友情', '思いやり'],
    };

    group('QuestionOption', () {
      test('fromJson parses correctly', () {
        final opt = QuestionOption.fromJson(optionJson);
        expect(opt.id, 'opt-A');
        expect(opt.label, 'A');
        expect(opt.text, '選択肢Aのテキスト');
      });

      test('toJson produces expected keys', () {
        final opt = QuestionOption.fromJson(optionJson);
        final json = opt.toJson();
        expect(json['id'], 'opt-A');
        expect(json['label'], 'A');
        expect(json['text'], '選択肢Aのテキスト');
      });
    });

    group('Question', () {
      test('fromJson parses correctly', () {
        final q = Question.fromJson(questionJson);
        expect(q.id, 'q-1');
        expect(q.storyId, 'story-1');
        expect(q.questionNumber, 1);
        expect(q.text, '問題文テキスト');
        expect(q.options.length, 1);
        expect(q.options.first.id, 'opt-A');
        expect(q.correctAnswerId, 'opt-A');
        expect(q.explanation, '説明テキスト');
        expect(q.keywords, ['友情', '思いやり']);
      });

      test('fromJson with multiple options', () {
        final json = Map<String, dynamic>.from(questionJson)
          ..['options'] = [
            optionJson,
            {'id': 'opt-B', 'label': 'B', 'text': '選択肢B'},
            {'id': 'opt-C', 'label': 'C', 'text': '選択肢C'},
          ];
        final q = Question.fromJson(json);
        expect(q.options.length, 3);
        expect(q.options[1].label, 'B');
      });

      test('fromJson with empty keywords', () {
        final json = Map<String, dynamic>.from(questionJson)
          ..['keywords'] = <String>[];
        final q = Question.fromJson(json);
        expect(q.keywords, isEmpty);
      });

      test('toJson / fromJson round-trip', () {
        final q = Question.fromJson(questionJson);
        final str = jsonEncode(q.toJson());
        final q2 = Question.fromJson(jsonDecode(str) as Map<String, dynamic>);
        expect(q2.id, q.id);
        expect(q2.text, q.text);
        expect(q2.options.length, q.options.length);
        expect(q2.keywords, q.keywords);
      });
    });
  });
}
