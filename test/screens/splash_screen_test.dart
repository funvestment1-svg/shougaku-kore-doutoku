import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/providers/auth_provider.dart';
import 'package:shougaku_kore_doutoku/screens/splash_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => ProviderScope(
      overrides: [
        // Return null (not signed in) immediately — no Firebase required
        userAuthStateProvider.overrideWith((_) => Stream.value(null)),
      ],
      child: MaterialApp(
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('LoginPage')),
          '/home': (_) => const Scaffold(body: Text('HomePage')),
          '/child-registration': (_) =>
              const Scaffold(body: Text('RegisterPage')),
        },
      ),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('SplashScreen', () {
    // ── Static UI (before the 1.5s startup timer fires) ───────────────────

    testWidgets('shows logo emoji', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('📖'), findsOneWidget);
      // Drain the 1.5s pending timer so the test ends cleanly
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    });

    testWidgets('shows app title 小学コレ！道徳', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('小学コレ！道徳'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    });

    testWidgets('shows subtitle かっこいい大人になるために', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('かっこいい大人になるために'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    });

    testWidgets('shows loading CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    });

    // ── Navigation (after the 1.5s delay) ─────────────────────────────────

    testWidgets('navigates to /login when auth user is null', (tester) async {
      await tester.pumpWidget(_wrap());
      // Advance fake clock past the 1 500 ms delay
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text('LoginPage'), findsOneWidget);
    });
  });
}
