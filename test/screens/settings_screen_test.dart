import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/providers/auth_provider.dart';
import 'package:shougaku_kore_doutoku/screens/settings/settings_screen.dart';
import '../helpers/fake_path_provider.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap() => ProviderScope(
      overrides: [
        // Prevent Firebase initialisation — no signed-in user
        userAuthStateProvider.overrideWith((_) => Stream.value(null)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );

/// Set a tall viewport so the ListView renders all settings items at once,
/// avoiding lazy-rendering clipping on items below the fold.
void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    try {
      await Hive.close();
    } catch (_) {}
  });

  group('SettingsScreen', () {
    // ── AppBar & sections ──────────────────────────────────────────────────

    testWidgets('shows AppBar title 設定', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('shows プロフィール section header', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('プロフィール'), findsOneWidget);
    });

    testWidgets('shows お子様のプロフィール list tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('お子様のプロフィール'), findsOneWidget);
    });

    testWidgets('shows 通知 section header', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('通知'), findsOneWidget);
    });

    testWidgets('shows デイリーリマインダー tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('デイリーリマインダー'), findsOneWidget);
    });

    testWidgets('shows レポート通知 tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('レポート通知'), findsOneWidget);
    });

    testWidgets('shows 音声設定 section header', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('音声設定'), findsOneWidget);
    });

    testWidgets('shows 効果音 and ナレーション switch tiles', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('効果音'), findsOneWidget);
      expect(find.text('ナレーション'), findsOneWidget);
    });

    testWidgets('shows 音量 slider tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('音量'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows 表示設定 section header', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('表示設定'), findsOneWidget);
    });

    testWidgets('shows 言語 tile with DropdownButton', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('言語'), findsOneWidget);
      // DropdownButton<SupportedLocale> — match by predicate to avoid generic mismatch
      expect(
        find.byWidgetPredicate((w) => w is DropdownButton),
        findsOneWidget,
      );
    });

    testWidgets('shows アカウント・その他 section header', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('アカウント・その他'), findsOneWidget);
    });

    testWidgets('shows ヘルプ tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('ヘルプ'), findsOneWidget);
    });

    testWidgets('shows プライバシーポリシー tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });

    testWidgets('shows ログアウト tile', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('ログアウト'), findsOneWidget);
    });

    testWidgets('shows switch widgets for sound toggles', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // At minimum two Switch widgets: 効果音 and ナレーション (and デイリーリマインダー/レポート通知)
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('tapping ログアウト shows confirmation dialog', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();
      expect(find.text('ログアウトしますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });
}
