import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/report_provider.dart';
import 'package:shougaku_kore_doutoku/screens/report/report_screen.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'こうた',
  grade: 3,
  avatarEmoji: '🏆',
  createdAt: DateTime(2024, 1, 1),
);

MonthlyReport _makeReport({
  String? highlightComment,
  String? growthComment,
  String? adviceComment,
  String? parentMessage,
  int storiesCompleted = 5,
  int totalStudyMinutes = 90,
  int totalPointsEarned = 150,
}) {
  return MonthlyReport.fromJson({
    'id': 'report-1',
    'childId': 'child-1',
    'month': 3,
    'year': 2024,
    'storiesCompleted': storiesCompleted,
    'totalStudyMinutes': totalStudyMinutes,
    'totalPointsEarned': totalPointsEarned,
    'kindnessScore': 70.0,
    'honestyScore': 65.0,
    'responsibilityScore': 80.0,
    'courageScore': 60.0,
    'respectScore': 75.0,
    'cooperationScore': 68.0,
    'highlightComment': highlightComment,
    'growthComment': growthComment,
    'adviceComment': adviceComment,
    'parentMessage': parentMessage,
    'generatedAt': '2024-04-01T00:00:00.000Z',
    'topImpressions': <dynamic>[],
  });
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({
  ChildProfile? child,
  MonthlyReport? report,
  bool reportNull = false,
}) {
  return ProviderScope(
    overrides: [
      selectedChildProvider.overrideWith((ref) => Future.value(child)),
      monthlyReportProvider.overrideWith((ref, param) {
        if (reportNull) return Future.value(null);
        return Future.value(report);
      }),
    ],
    child: const MaterialApp(home: ReportScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ReportScreen', () {
    testWidgets('shows loading indicator while child loads', (tester) async {
      final completer = Completer<ChildProfile?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => completer.future),
            monthlyReportProvider.overrideWith(
                (ref, _) => Future.value(null)),
          ],
          child: const MaterialApp(home: ReportScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('shows message when no child is selected', (tester) async {
      await tester.pumpWidget(_wrap(child: null));
      await tester.pumpAndSettle();
      expect(find.text('子供プロフィールを作成してください'), findsOneWidget);
    });

    testWidgets('shows AppBar title 月次成長レポート when child is present',
        (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.text('月次成長レポート'), findsOneWidget);
    });

    testWidgets('shows month selector navigation buttons', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows empty report card when report is null', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('レポートはまだありません'), findsOneWidget);
      expect(find.text('レポートを確認する'), findsOneWidget);
      expect(find.text('AIレポートを生成する'), findsOneWidget);
    });

    testWidgets('shows summary card stat labels when report exists',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(
            storiesCompleted: 8,
            totalStudyMinutes: 120,
            totalPointsEarned: 200,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Labels are plain Text widgets — always reliable to test
      expect(find.text('完了ストーリー'), findsOneWidget);
      expect(find.text('学習時間'), findsOneWidget);
      expect(find.text('獲得ポイント'), findsOneWidget);
    });

    testWidgets('shows AI comment card with highlight', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(highlightComment: '今月はよく頑張りました！'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('✨ 今月の頑張り'), findsOneWidget);
      expect(find.text('今月はよく頑張りました！'), findsOneWidget);
    });

    testWidgets('shows radar chart section header', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('🌈 徳目バランス'), findsOneWidget);
    });

    testWidgets('shows parent message card when parentMessage is set',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(parentMessage: '毎日コツコツ続けましょう。'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('保護者の方へ'), findsOneWidget);
      expect(find.text('毎日コツコツ続けましょう。'), findsOneWidget);
    });

    testWidgets('does NOT show parent message card when parentMessage is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('保護者の方へ'), findsNothing);
    });

    testWidgets('month selector previous button is tappable', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      // After tap, nav buttons are still present (navigated to prev month)
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });
  });
}
