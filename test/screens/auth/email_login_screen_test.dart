import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/auth/email_login_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: EmailLoginScreen()),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('EmailLoginScreen', () {
    testWidgets('shows AppBar title メールでログイン', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('メールでログイン'), findsOneWidget);
    });

    testWidgets('shows email text field with label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('メールアドレス'), findsOneWidget);
    });

    testWidgets('shows password text field with label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('パスワード'), findsOneWidget);
    });

    testWidgets('shows login button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('shows register link', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('アカウントをお持ちでない方は登録'), findsOneWidget);
    });

    testWidgets('no error message shown initially', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // No error container on initial render
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('has two TextFields', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter password text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // password field is obscured so the text finder won't match,
      // but entering text should not throw
      await tester.enterText(find.byType(TextField).last, 'secret123');
    });

    testWidgets('login button is an ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'ログイン'), findsOneWidget);
    });

    testWidgets('register link is a TextButton', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextButton, 'アカウントをお持ちでない方は登録'),
        findsOneWidget,
      );
    });
  });
}
