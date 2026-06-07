import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/auth/child_registration_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: ChildRegistrationScreen()),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ChildRegistrationScreen', () {
    // ── Static UI ──────────────────────────────────────────────────────────

    testWidgets('shows AppBar title お子さんの情報登録', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('お子さんの情報登録'), findsOneWidget);
    });

    testWidgets('shows header emoji and description', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('👶'), findsOneWidget);
      expect(find.textContaining('お子さんのプロフィールを作成しましょう'), findsOneWidget);
    });

    testWidgets('shows ニックネーム label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('ニックネーム'), findsOneWidget);
    });

    testWidgets('shows nickname TextField', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows 学年 label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('学年'), findsOneWidget);
    });

    testWidgets('shows grade selector with 3年生 and 4年生', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('3年生'), findsOneWidget);
      expect(find.text('4年生'), findsOneWidget);
    });

    testWidgets('shows アバターを選択 label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('アバターを選択'), findsOneWidget);
    });

    testWidgets('shows all 8 avatar emojis', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      for (final emoji in ['🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨']) {
        expect(find.text(emoji), findsOneWidget, reason: '$emoji not found');
      }
    });

    testWidgets('shows 登録して始める button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // The button is below the fold in a long ListView — scroll down to build it
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('登録して始める'), findsOneWidget);
    });

    // ── Interactions ───────────────────────────────────────────────────────

    testWidgets('shows SnackBar when nickname is empty and button tapped',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Scroll down to reveal the button (below the fold)
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      // Do NOT enter nickname — tap complete button
      await tester.tap(find.text('登録して始める'));
      await tester.pumpAndSettle();
      expect(find.text('ニックネームを入力してください'), findsOneWidget);
    });

    testWidgets('can type a nickname', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'たろう');
      expect(find.text('たろう'), findsOneWidget);
    });

    testWidgets('can select 4年生 in grade selector', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('4年生'));
      await tester.pumpAndSettle();
      // SegmentedButton selection changed — button is still present
      expect(find.text('4年生'), findsOneWidget);
    });

    testWidgets('can tap a different avatar emoji to select it', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Tap the 🐶 avatar (index 2)
      await tester.tap(find.text('🐶'));
      await tester.pumpAndSettle();
      // No crash expected; avatar grid is still visible
      expect(find.text('🐶'), findsOneWidget);
    });
  });
}
