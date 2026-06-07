import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/screens/profile/profile_edit_screen.dart';

// ─── Fixture ─────────────────────────────────────────────────────────────────

final _testProfile = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'たろう',
  grade: 3,
  avatarEmoji: '🦁',
  createdAt: DateTime(2024, 1, 1),
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({ChildProfile? profile}) => ProviderScope(
      child: MaterialApp(home: ProfileEditScreen(profile: profile)),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ProfileEditScreen', () {
    // ── Create mode ────────────────────────────────────────────────────────

    group('create mode (no profile)', () {
      testWidgets('shows AppBar title プロフィール作成', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('プロフィール作成'), findsOneWidget);
      });

      testWidgets('shows アバターを選択 label', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('アバターを選択'), findsOneWidget);
      });

      testWidgets('shows all 16 avatar emojis in grid', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        for (final emoji in [
          '🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨',
          '🐸', '🦋', '⭐', '🌟', '🌈', '🎵', '🎨', '🚀',
        ]) {
          expect(find.text(emoji), findsOneWidget, reason: '$emoji not found');
        }
      });

      testWidgets('shows お子様の名前 label', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('お子様の名前'), findsOneWidget);
      });

      testWidgets('shows one TextField for name', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('shows 学年 label and grade selector', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('学年'), findsOneWidget);
        expect(find.text('3年生'), findsOneWidget);
        expect(find.text('4年生'), findsOneWidget);
      });

      testWidgets('shows 作成する button', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('作成する'), findsOneWidget);
      });

      testWidgets('shows SnackBar when name is empty on button tap',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        // Scroll to the button in case it is below the fold
        await tester.ensureVisible(find.text('作成する'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('作成する'));
        await tester.pumpAndSettle();
        expect(find.text('お子様の名前を入力してください'), findsOneWidget);
      });

      testWidgets('can tap avatar to select it', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.text('🐶'));
        await tester.pumpAndSettle();
        expect(find.text('🐶'), findsOneWidget);
      });

      testWidgets('can change grade to 4年生', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.text('4年生'));
        await tester.pumpAndSettle();
        expect(find.text('4年生'), findsOneWidget);
      });
    });

    // ── Edit mode ──────────────────────────────────────────────────────────

    group('edit mode (with profile)', () {
      testWidgets('shows AppBar title プロフィール編集', (tester) async {
        await tester.pumpWidget(_wrap(profile: _testProfile));
        await tester.pumpAndSettle();
        expect(find.text('プロフィール編集'), findsOneWidget);
      });

      testWidgets('pre-fills the name field', (tester) async {
        await tester.pumpWidget(_wrap(profile: _testProfile));
        await tester.pumpAndSettle();
        expect(find.text('たろう'), findsOneWidget);
      });

      testWidgets('shows 変更を保存 button', (tester) async {
        await tester.pumpWidget(_wrap(profile: _testProfile));
        await tester.pumpAndSettle();
        expect(find.text('変更を保存'), findsOneWidget);
      });

      testWidgets('shows SnackBar when name is cleared and button tapped',
          (tester) async {
        await tester.pumpWidget(_wrap(profile: _testProfile));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '');
        // Scroll to the button in case it is below the fold
        await tester.ensureVisible(find.text('変更を保存'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('変更を保存'));
        await tester.pumpAndSettle();
        expect(find.text('お子様の名前を入力してください'), findsOneWidget);
      });
    });
  });
}
