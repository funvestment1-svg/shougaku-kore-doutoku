import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/screens/profile/profile_management_screen.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

ChildProfile _makeProfile({
  String id = 'child-1',
  String name = 'たろう',
  int grade = 3,
  String avatarEmoji = '🦁',
}) {
  return ChildProfile(
    id: id,
    parentId: 'parent-1',
    name: name,
    grade: grade,
    avatarEmoji: avatarEmoji,
    createdAt: DateTime(2024, 1, 1),
  );
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({
  List<ChildProfile>? profiles,
  bool loading = false,
  Object? error,
}) {
  return ProviderScope(
    overrides: [
      childrenProfilesProvider.overrideWith((ref) {
        if (loading) return Future.delayed(const Duration(days: 1));
        if (error != null) return Future.error(error);
        return Future.value(profiles ?? []);
      }),
    ],
    child: const MaterialApp(home: ProfileManagementScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ProfileManagementScreen', () {
    testWidgets('shows loading indicator while profiles load', (tester) async {
      final completer = Completer<List<ChildProfile>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProfilesProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(home: ProfileManagementScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows AppBar title お子様のプロフィール', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('お子様のプロフィール'), findsOneWidget);
    });

    testWidgets('shows empty state when no profiles', (tester) async {
      await tester.pumpWidget(_wrap(profiles: []));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.text('プロフィールがありません'), findsOneWidget);
    });

    testWidgets('always shows 新しいプロフィールを作成 button', (tester) async {
      await tester.pumpWidget(_wrap(profiles: []));
      await tester.pumpAndSettle();
      expect(find.text('新しいプロフィールを作成'), findsOneWidget);
    });

    testWidgets('shows 新しいプロフィールを作成 button even with profiles',
        (tester) async {
      await tester.pumpWidget(_wrap(profiles: [_makeProfile()]));
      await tester.pumpAndSettle();
      expect(find.text('新しいプロフィールを作成'), findsOneWidget);
    });

    testWidgets('shows profile name when profiles exist', (tester) async {
      await tester.pumpWidget(_wrap(profiles: [_makeProfile(name: 'たろう')]));
      await tester.pumpAndSettle();
      expect(find.text('たろう'), findsOneWidget);
    });

    testWidgets('shows grade display name in profile card', (tester) async {
      await tester.pumpWidget(_wrap(profiles: [_makeProfile(grade: 3)]));
      await tester.pumpAndSettle();
      expect(find.text('小学3年生'), findsOneWidget);
    });

    testWidgets('shows avatar emoji in profile card', (tester) async {
      await tester.pumpWidget(
        _wrap(profiles: [_makeProfile(avatarEmoji: '🦁')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('🦁'), findsOneWidget);
    });

    testWidgets('shows multiple profile cards when multiple profiles exist',
        (tester) async {
      final profiles = [
        _makeProfile(id: 'c1', name: 'たろう', avatarEmoji: '🦁'),
        _makeProfile(id: 'c2', name: 'はなこ', grade: 4, avatarEmoji: '🐱'),
      ];
      await tester.pumpWidget(_wrap(profiles: profiles));
      await tester.pumpAndSettle();
      expect(find.text('たろう'), findsOneWidget);
      expect(find.text('はなこ'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows error text on provider error', (tester) async {
      await tester.pumpWidget(_wrap(error: Exception('network error')));
      await tester.pumpAndSettle();
      expect(find.textContaining('エラー'), findsOneWidget);
    });
  });
}
