import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';

void main() {
  group('MonthlyReport model', () {
    final impressionJson = {
      'storyId': 'story-1',
      'storyTitle': 'テストストーリー',
      'choiceMade': '友達を助けた',
      'valueReflected': '思いやり',
      'parentQuestion': '最近誰かを助けた経験はありますか？',
    };

    final patternJson = {
      'compassion': 75.0,
      'fairness': 60.0,
      'responsibility': 80.0,
      'challenge': 55.0,
    };

    final reportJson = {
      'id': 'report-1',
      'childId': 'child-1',
      'month': 3,
      'year': 2024,
      'storiesCompleted': 5,
      'totalStudyMinutes': 90,
      'totalPointsEarned': 150,
      'kindnessScore': 70.0,
      'honestyScore': 65.0,
      'responsibilityScore': 80.0,
      'courageScore': 60.0,
      'respectScore': 75.0,
      'cooperationScore': 68.0,
      'highlightComment': 'よく頑張りました',
      'growthComment': '思いやりが育っています',
      'adviceComment': '正直さを意識してみましょう',
      'parentMessage': '毎日の学習お疲れさまでした',
      'generatedAt': '2024-04-01T00:00:00.000Z',
      'patternScores': patternJson,
      'topImpressions': [impressionJson],
    };

    group('TopImpression', () {
      test('fromJson parses correctly', () {
        final imp = TopImpression.fromJson(impressionJson);
        expect(imp.storyId, 'story-1');
        expect(imp.storyTitle, 'テストストーリー');
        expect(imp.choiceMade, '友達を助けた');
        expect(imp.valueReflected, '思いやり');
        expect(imp.parentQuestion, '最近誰かを助けた経験はありますか？');
      });

      test('toJson round-trip', () {
        final imp = TopImpression.fromJson(impressionJson);
        final str = jsonEncode(imp.toJson());
        final imp2 = TopImpression.fromJson(
            jsonDecode(str) as Map<String, dynamic>);
        expect(imp2.storyId, imp.storyId);
        expect(imp2.valueReflected, imp.valueReflected);
      });
    });

    group('PatternScores', () {
      test('fromJson parses correctly', () {
        final ps = PatternScores.fromJson(patternJson);
        expect(ps.compassion, 75.0);
        expect(ps.fairness, 60.0);
        expect(ps.responsibility, 80.0);
        expect(ps.challenge, 55.0);
      });
    });

    group('MonthlyReport', () {
      test('fromJson parses correctly', () {
        final r = MonthlyReport.fromJson(reportJson);
        expect(r.id, 'report-1');
        expect(r.childId, 'child-1');
        expect(r.month, 3);
        expect(r.year, 2024);
        expect(r.storiesCompleted, 5);
        expect(r.totalStudyMinutes, 90);
        expect(r.totalPointsEarned, 150);
        expect(r.kindnessScore, 70.0);
        expect(r.honestyScore, 65.0);
        expect(r.responsibilityScore, 80.0);
        expect(r.courageScore, 60.0);
        expect(r.respectScore, 75.0);
        expect(r.cooperationScore, 68.0);
        expect(r.highlightComment, 'よく頑張りました');
        expect(r.topImpressions.length, 1);
        expect(r.patternScores, isNotNull);
        expect(r.patternScores!.compassion, 75.0);
      });

      test('fromJson with missing optional fields uses defaults', () {
        final json = {
          'id': 'r-2',
          'childId': 'c-1',
          'month': 1,
          'year': 2024,
          'generatedAt': '2024-02-01T00:00:00.000Z',
        };
        final r = MonthlyReport.fromJson(json);
        expect(r.storiesCompleted, 0);
        expect(r.totalStudyMinutes, 0);
        expect(r.totalPointsEarned, 0);
        expect(r.kindnessScore, 50.0);
        expect(r.honestyScore, 50.0);
        expect(r.responsibilityScore, 50.0);
        expect(r.courageScore, 50.0);
        expect(r.respectScore, 50.0);
        expect(r.cooperationScore, 50.0);
        expect(r.highlightComment, isNull);
        expect(r.patternScores, isNull);
        expect(r.topImpressions, isEmpty);
      });

      test('toJson / fromJson round-trip', () {
        final r = MonthlyReport.fromJson(reportJson);
        final str = jsonEncode(r.toJson());
        final r2 = MonthlyReport.fromJson(
            jsonDecode(str) as Map<String, dynamic>);
        expect(r2.id, r.id);
        expect(r2.month, r.month);
        expect(r2.year, r.year);
        expect(r2.kindnessScore, r.kindnessScore);
        expect(r2.topImpressions.length, r.topImpressions.length);
      });
    });
  });
}
