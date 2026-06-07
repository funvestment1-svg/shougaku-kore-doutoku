import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/quiz_session.dart';

void main() {
  group('QuizSession model', () {
    final answerJson = {
      'questionId': 'q-1',
      'selectedOptionId': 'opt-A',
      'isCorrect': true,
      'timeSpentSeconds': 15,
      'answeredAt': '2024-03-15T10:05:00.000Z',
    };

    final sessionJson = {
      'id': 'session-1',
      'storyId': 'story-1',
      'childId': 'child-1',
      'answers': [answerJson],
      'startedAt': '2024-03-15T10:00:00.000Z',
      'completedAt': '2024-03-15T10:10:00.000Z',
      'totalTimeSeconds': 600,
      'pointsEarned': 15,
      'reflectionNotes': '友達を助けることが大切だと学んだ。',
    };

    group('QuizAnswer', () {
      test('fromJson parses correctly', () {
        final a = QuizAnswer.fromJson(answerJson);
        expect(a.questionId, 'q-1');
        expect(a.selectedOptionId, 'opt-A');
        expect(a.isCorrect, isTrue);
        expect(a.timeSpentSeconds, 15);
        expect(a.answeredAt, DateTime.parse('2024-03-15T10:05:00.000Z'));
      });

      test('toJson round-trip', () {
        final a = QuizAnswer.fromJson(answerJson);
        final str = jsonEncode(a.toJson());
        final a2 = QuizAnswer.fromJson(jsonDecode(str) as Map<String, dynamic>);
        expect(a2.questionId, a.questionId);
        expect(a2.isCorrect, a.isCorrect);
      });
    });

    group('QuizSession', () {
      test('fromJson parses correctly', () {
        final s = QuizSession.fromJson(sessionJson);
        expect(s.id, 'session-1');
        expect(s.storyId, 'story-1');
        expect(s.childId, 'child-1');
        expect(s.answers.length, 1);
        expect(s.completedAt, isNotNull);
        expect(s.totalTimeSeconds, 600);
        expect(s.pointsEarned, 15);
        expect(s.reflectionNotes, '友達を助けることが大切だと学んだ。');
      });

      test('fromJson with null completedAt', () {
        final json = Map<String, dynamic>.from(sessionJson)
          ..['completedAt'] = null;
        final s = QuizSession.fromJson(json);
        expect(s.completedAt, isNull);
        expect(s.isCompleted, isFalse);
      });

      test('isCompleted returns true when completedAt is set', () {
        final s = QuizSession.fromJson(sessionJson);
        expect(s.isCompleted, isTrue);
      });

      test('score is 100 when all answers correct', () {
        final json = Map<String, dynamic>.from(sessionJson)
          ..['answers'] = [
            answerJson,
            {
              'questionId': 'q-2',
              'selectedOptionId': 'opt-B',
              'isCorrect': true,
              'timeSpentSeconds': 20,
              'answeredAt': '2024-03-15T10:06:00.000Z',
            },
          ];
        final s = QuizSession.fromJson(json);
        expect(s.score, 100);
      });

      test('score is 50 when half answers correct', () {
        final json = Map<String, dynamic>.from(sessionJson)
          ..['answers'] = [
            answerJson, // isCorrect: true
            {
              'questionId': 'q-2',
              'selectedOptionId': 'opt-B',
              'isCorrect': false,
              'timeSpentSeconds': 20,
              'answeredAt': '2024-03-15T10:06:00.000Z',
            },
          ];
        final s = QuizSession.fromJson(json);
        expect(s.score, 50);
      });

      test('score is 0 when answers list is empty', () {
        final json = Map<String, dynamic>.from(sessionJson)
          ..['answers'] = <dynamic>[];
        final s = QuizSession.fromJson(json);
        expect(s.score, 0);
      });

      test('score is 0 when all answers wrong', () {
        final json = Map<String, dynamic>.from(sessionJson)
          ..['answers'] = [
            {
              'questionId': 'q-1',
              'selectedOptionId': 'opt-B',
              'isCorrect': false,
              'timeSpentSeconds': 10,
              'answeredAt': '2024-03-15T10:05:00.000Z',
            },
          ];
        final s = QuizSession.fromJson(json);
        expect(s.score, 0);
      });

      test('toJson / fromJson round-trip', () {
        final s = QuizSession.fromJson(sessionJson);
        final str = jsonEncode(s.toJson());
        final s2 = QuizSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
        expect(s2.id, s.id);
        expect(s2.pointsEarned, s.pointsEarned);
        expect(s2.answers.length, s.answers.length);
        expect(s2.score, s.score);
      });
    });
  });
}
