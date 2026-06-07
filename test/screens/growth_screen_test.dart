import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/screens/growth/growth_screen.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'たろう',
  grade: 3,
  avatarEmoji: '⭐',
  createdAt: DateTime(2024, 1, 1),
  level: 3,
  totalPoints: 250,
  kindnessScore: 75.0,
  honestyScore: 60.0,
  responsibilityScore: 80.0,
  courageScore: 55.0,
  respectScore: 70.0,
  cooperationScore: 65.0,
);

final _weeklyData = [1, 2, 0, 3, 1, 0, 2];

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({
  ChildProfile? child,
  bool childLoading = false,
  Object? childError,
  List<int>? weekly,
}) {
  return ProviderScope(
    overrides: [
      selectedChildProvider.overrideWith((ref) {
        if (childLoading) return Future.delayed(const Duration(days: 1));
        if (childError != null) return Future.error(childError);
        return Future.value(child);
      }),
      weeklyActivityProvider.overrideWith(
        (ref, _) => Future.value(weekly ?? List<int>.filled(7, 0)),
      ),
    ],
    child: const MaterialApp(home: GrowthScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('GrowthScreen', () {
    testWidgets('shows loading indicator while child is loading', (tester) async {
      // Use a Completer so no timer is created and tearDown stays clean
      final completer = Completer<ChildProfile?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => completer.future),
            weeklyActivityProvider.overrideWith((ref, _) => Future.value([])),
          ],
          child: const MaterialApp(home: GrowthScreen()),
        ),
      );
      await tester.pump(); // one frame — future unresolved → AsyncLoading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(null); // avoid pending future warning
      await tester.pumpAndSettle();
    });

    testWidgets('shows error text on selectedChildProvider error', (tester) async {
      await tester.pumpWidget(_wrap(childError: Exception('network error')));
      await tester.pumpAndSettle();
      expect(find.textContaining('エラー'), findsOneWidget);
    });

    testWidgets('shows no-child view when child is null', (tester) async {
      await tester.pumpWidget(_wrap(child: null));
      await tester.pumpAndSettle();
      expect(find.text('子供プロフィールを作成してください'), findsOneWidget);
      expect(find.text('👶'), findsOneWidget);
    });

    testWidgets('shows child name in AppBar when child is present', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('たろうの成長'), findsOneWidget);
    });

    testWidgets('shows avatar emoji in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('⭐'), findsOneWidget);
    });

    testWidgets('shows level card with level and points', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('現在のレベル'), findsOneWidget);
      expect(find.text('レベル 3'), findsOneWidget);
      expect(find.text('250pt'), findsOneWidget);
    });

    testWidgets('shows virtue radar chart section header', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('🌈 徳目レーダーチャート'), findsOneWidget);
    });

    testWidgets('shows virtue detail list with all six virtues', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('📊 徳目スコア詳細'), findsOneWidget);
      expect(find.text('思いやり'), findsOneWidget);
      expect(find.text('正直さ'), findsOneWidget);
      expect(find.text('責任感'), findsOneWidget);
      expect(find.text('勇気'), findsOneWidget);
      expect(find.text('礼儀'), findsOneWidget);
      expect(find.text('協調性'), findsOneWidget);
    });

    testWidgets('shows weekly activity card section header', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, weekly: _weeklyData));
      await tester.pumpAndSettle();
      expect(find.text('📅 今週の学習状況'), findsOneWidget);
    });

    testWidgets('shows correct total in weekly activity summary', (tester) async {
      // sum of [1,2,0,3,1,0,2] = 9
      await tester.pumpWidget(_wrap(child: _testChild, weekly: _weeklyData));
      await tester.pumpAndSettle();
      expect(find.textContaining('9 ストーリー'), findsOneWidget);
    });

    testWidgets('shows 0 stories for empty weekly data', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, weekly: List<int>.filled(7, 0)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('0 ストーリー'), findsOneWidget);
    });
  });
}
