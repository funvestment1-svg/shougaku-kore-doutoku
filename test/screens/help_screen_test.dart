import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/settings/help_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('HelpScreen', () {
    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));
      expect(find.text('ヘルプ'), findsOneWidget);
    });

    testWidgets('renders all section headers', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));
      final scrollable = find.byType(Scrollable).first;

      // First section is visible without scrolling
      expect(find.text('🎯 アプリの使い方'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('📊 ポイントと徳目'), 300,
        scrollable: scrollable,
      );
      expect(find.text('📊 ポイントと徳目'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('👨‍👩‍👧 保護者向け機能'), 300,
        scrollable: scrollable,
      );
      expect(find.text('👨‍👩‍👧 保護者向け機能'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('🌐 オフライン・通信'), 300,
        scrollable: scrollable,
      );
      expect(find.text('🌐 オフライン・通信'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('🔒 アカウント・セキュリティ'), 300,
        scrollable: scrollable,
      );
      expect(find.text('🔒 アカウント・セキュリティ'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('📮 お問い合わせ'), 300,
        scrollable: scrollable,
      );
      expect(find.text('📮 お問い合わせ'), findsOneWidget);
    });

    testWidgets('FAQ tiles start collapsed', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));

      // Questions should be visible as titles
      expect(find.text('アプリの目的は何ですか？'), findsOneWidget);

      // Answers are hidden (collapsed) by default — text not rendered
      expect(find.textContaining('道徳的な判断力を楽しく育てる'), findsNothing);
    });

    testWidgets('tapping a FAQ tile expands to show the answer', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));
      await tester.pumpAndSettle();

      // Tap the first FAQ tile
      await tester.tap(find.text('アプリの目的は何ですか？'));
      await tester.pumpAndSettle();

      // Answer should now be visible
      expect(find.textContaining('道徳的な判断力'), findsOneWidget);
    });

    testWidgets('tapping an expanded FAQ tile collapses it again', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.text('アプリの目的は何ですか？'));
      await tester.pumpAndSettle();
      expect(find.textContaining('道徳的な判断力'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('アプリの目的は何ですか？'));
      await tester.pumpAndSettle();
      expect(find.textContaining('道徳的な判断力'), findsNothing);
    });

    testWidgets('contact tile is visible after scrolling', (tester) async {
      await tester.pumpWidget(_wrap(const HelpScreen()));
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('サポートへのお問い合わせ'),
        300,
        scrollable: scrollable,
      );
      expect(find.text('サポートへのお問い合わせ'), findsOneWidget);
    });
  });
}
