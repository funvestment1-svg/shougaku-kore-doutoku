import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/auth/login_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen', () {
    testWidgets('shows app title 小学コレ！道徳', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('小学コレ！道徳'), findsOneWidget);
    });

    testWidgets('shows subtitle かっこいい大人になるために', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('かっこいい大人になるために'), findsOneWidget);
    });

    testWidgets('shows book emoji logo', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('shows Google login button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Google でログイン'), findsOneWidget);
    });

    testWidgets('shows email login button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('メールアドレスでログイン'), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('新規登録（無料）'), findsOneWidget);
    });

    testWidgets('shows COPPA compliance text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('COPPA'), findsOneWidget);
    });

    testWidgets('shows catchphrase panel', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('お子さんの成長を一緒に見守ろう'), findsOneWidget);
    });

    testWidgets('shows target grade description', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('小学3-4年生対象'), findsOneWidget);
    });

    testWidgets('three auth buttons are ElevatedButtons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Google / メールアドレス / 新規登録 = 3 ElevatedButtons
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });
  });
}
