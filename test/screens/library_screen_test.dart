import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'; // weeklyThemeProvider
import 'package:shougaku_kore_doutoku/providers/story_provider_fs.dart'; // storiesFsProvider
import 'package:shougaku_kore_doutoku/screens/library/library_screen.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'はなこ',
  grade: 4,
  avatarEmoji: '🌸',
  createdAt: DateTime(2024, 1, 1),
);

Story _makeStory({
  String id = 'story-1',
  String title = 'テストストーリー',
  String theme = 'kindness',
  bool isPremium = false,
}) {
  return Story.fromJson({
    'id': id,
    'title': title,
    'description': '説明',
    'theme': theme,
    'gradeLevel': 3,
    'difficulty': 1,
    'isPremium': isPremium,
    'content': null,
    'durationSeconds': 300,
    'createdAt': '2024-01-01T00:00:00.000Z',
    'updatedAt': '2024-01-01T00:00:00.000Z',
  });
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({
  ChildProfile? child,
  List<Story>? weeklyStories,
  List<Story>? allStories,
  List<Story>? completedStories,
}) {
  return ProviderScope(
    overrides: [
      selectedChildProvider.overrideWith(
        (ref) => Future.value(child),
      ),
      weeklyThemeProvider.overrideWith(
        (ref, _) => Future.value(weeklyStories ?? []),
      ),
      storiesFsProvider.overrideWith(
        (ref, _) => Future.value(allStories ?? []),
      ),
      completedStoriesProvider.overrideWith(
        (ref, _) => Future.value(completedStories ?? []),
      ),
    ],
    child: const MaterialApp(
      home: LibraryScreen(),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('LibraryScreen', () {
    testWidgets('shows AppBar with title "ライブラリ"', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('ライブラリ'), findsOneWidget);
    });

    testWidgets('shows three tabs: 今週 / テーマ / 完了済み', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('今週'), findsOneWidget);
      expect(find.text('テーマ'), findsOneWidget);
      expect(find.text('完了済み'), findsOneWidget);
    });

    group('Weekly tab', () {
      testWidgets('shows empty view when no weekly stories', (tester) async {
        await tester.pumpWidget(_wrap(weeklyStories: []));
        await tester.pumpAndSettle();
        expect(find.text('今週のストーリーはまだありません'), findsOneWidget);
      });

      testWidgets('shows stories when weeklyThemeProvider has data', (tester) async {
        final stories = [_makeStory(title: '友情の話'), _makeStory(id: 'story-2', title: '勇気の話')];
        await tester.pumpWidget(_wrap(weeklyStories: stories));
        await tester.pumpAndSettle();
        expect(find.text('友情の話'), findsOneWidget);
        expect(find.text('勇気の話'), findsOneWidget);
      });

      testWidgets('premium story shows Premium tag', (tester) async {
        final story = _makeStory(isPremium: true);
        await tester.pumpWidget(_wrap(weeklyStories: [story]));
        await tester.pumpAndSettle();
        expect(find.text('Premium'), findsOneWidget);
      });
    });

    group('Theme tab', () {
      testWidgets('shows theme filter chips', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        // Tap the テーマ tab
        await tester.tap(find.text('テーマ'));
        await tester.pumpAndSettle();

        expect(find.text('すべて'), findsOneWidget);
        expect(find.text('思いやり'), findsOneWidget);
        expect(find.text('正直さ'), findsOneWidget);
        expect(find.text('責任感'), findsOneWidget);
        expect(find.text('勇気'), findsOneWidget);
      });

      testWidgets('shows empty view when no themed stories', (tester) async {
        await tester.pumpWidget(_wrap(allStories: []));
        await tester.pumpAndSettle();
        await tester.tap(find.text('テーマ'));
        await tester.pumpAndSettle();
        expect(find.text('このテーマのストーリーはありません'), findsOneWidget);
      });

      testWidgets('shows stories in theme tab', (tester) async {
        final stories = [_makeStory(title: '思いやりのストーリー', theme: 'kindness')];
        await tester.pumpWidget(_wrap(allStories: stories));
        await tester.pumpAndSettle();
        await tester.tap(find.text('テーマ'));
        await tester.pumpAndSettle();
        expect(find.text('思いやりのストーリー'), findsOneWidget);
      });
    });

    group('Completed tab', () {
      testWidgets('shows no-child message when child is null', (tester) async {
        await tester.pumpWidget(_wrap(child: null));
        await tester.pumpAndSettle();
        await tester.tap(find.text('完了済み'));
        await tester.pumpAndSettle();
        expect(find.text('お子さんを選択してください'), findsOneWidget);
      });

      testWidgets('shows empty state when no completed stories', (tester) async {
        await tester.pumpWidget(
          _wrap(child: _testChild, completedStories: []),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('完了済み'));
        await tester.pumpAndSettle();
        expect(find.textContaining('まだ完了したストーリーはありません'), findsOneWidget);
      });

      testWidgets('shows completed stories list', (tester) async {
        final completed = [
          _makeStory(id: 'story-done', title: '完了済みストーリー'),
        ];
        await tester.pumpWidget(
          _wrap(child: _testChild, completedStories: completed),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('完了済み'));
        await tester.pumpAndSettle();
        expect(find.text('完了済みストーリー'), findsOneWidget);
      });
    });
  });
}
