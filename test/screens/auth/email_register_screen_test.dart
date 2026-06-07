import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/auth/email_register_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: EmailRegisterScreen()),
    );

/// Enter values and tap 登録, then settle.
Future<void> _tapRegister(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
  await tester.pumpAndSettle();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('EmailRegisterScreen', () {
    // ── Static UI ──────────────────────────────────────────────────────────

    testWidgets('shows AppBar title 保護者登録', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('保護者登録'), findsOneWidget);
    });

    testWidgets('shows name field label お名前', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('お名前'), findsOneWidget);
    });

    testWidgets('shows email field label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('メールアドレス'), findsOneWidget);
    });

    testWidgets('shows password field labels', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('パスワード（確認）'), findsOneWidget);
    });

    testWidgets('shows 登録 button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, '登録'), findsOneWidget);
    });

    testWidgets('shows COPPA notice', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.textContaining('COPPA'), findsOneWidget);
    });

    testWidgets('has four TextFields', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // name / email / password / confirm password
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('no error shown initially', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('すべての項目を入力してください'), findsNothing);
      expect(find.text('パスワードが一致しません'), findsNothing);
      expect(find.text('パスワードは6文字以上である必要があります'), findsNothing);
    });

    // ── Validation ─────────────────────────────────────────────────────────

    testWidgets('shows error when all fields are empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _tapRegister(tester);
      expect(find.text('すべての項目を入力してください'), findsOneWidget);
    });

    testWidgets('shows error when name is missing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Leave name empty, fill others
      await tester.enterText(find.byType(TextField).at(1), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password1');
      await tester.enterText(find.byType(TextField).at(3), 'password1');
      await _tapRegister(tester);
      expect(find.text('すべての項目を入力してください'), findsOneWidget);
    });

    testWidgets('shows error when email is missing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'テスト');
      // Leave email empty
      await tester.enterText(find.byType(TextField).at(2), 'password1');
      await tester.enterText(find.byType(TextField).at(3), 'password1');
      await _tapRegister(tester);
      expect(find.text('すべての項目を入力してください'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // name=TextField[0], email=TextField[1], password=TextField[2], confirm=TextField[3]
      await tester.enterText(find.byType(TextField).at(0), 'テスト太郎');
      await tester.enterText(find.byType(TextField).at(1), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'different456');
      await _tapRegister(tester);
      expect(find.text('パスワードが一致しません'), findsOneWidget);
    });

    testWidgets('shows error when password is fewer than 6 chars', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'テスト太郎');
      await tester.enterText(find.byType(TextField).at(1), 'a@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'abc');
      await tester.enterText(find.byType(TextField).at(3), 'abc');
      await _tapRegister(tester);
      expect(find.text('パスワードは6文字以上である必要があります'), findsOneWidget);
    });

    testWidgets('error message for mismatch overrides empty-fields error',
        (tester) async {
      // Confirms validation order: empty check before mismatch check
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Only fill name — email is empty, so empty check fires first
      await tester.enterText(find.byType(TextField).at(0), 'テスト');
      await _tapRegister(tester);
      expect(find.text('すべての項目を入力してください'), findsOneWidget);
      expect(find.text('パスワードが一致しません'), findsNothing);
    });
  });
}
