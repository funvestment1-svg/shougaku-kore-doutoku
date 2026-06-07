import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/story/story_result_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        home: child,
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );

StoryResultScreen _screen({
  String title = 'テストストーリー',
  int score = 85,
  int pointsEarned = 20,
  String childId = 'child-1',
}) =>
    StoryResultScreen(
      storyTitle: title,
      score: score,
      pointsEarned: pointsEarned,
      childId: childId,
    );

void main() {
  group('StoryResultScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pumpAndSettle();
    });

    testWidgets('shows story title', (tester) async {
      await tester.pumpWidget(_wrap(_screen(title: 'ともだちのなやみ')));
      await tester.pumpAndSettle();
      expect(find.text('ともだちのなやみ'), findsOneWidget);
    });

    testWidgets('shows final score percentage after animation', (tester) async {
      await tester.pumpWidget(_wrap(_screen(score: 85)));
      await tester.pumpAndSettle();
      // Score row shows static '${widget.score}%'; circle animates to same value
      expect(find.textContaining('85%'), findsWidgets);
    });

    testWidgets('shows home button and try-another button', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pumpAndSettle();
      expect(find.text('ホームへ戻る'), findsOneWidget);
      expect(find.text('別のレッスンに挑戦'), findsOneWidget);
    });

    testWidgets('score >= 90 shows パーフェクト！', (tester) async {
      await tester.pumpWidget(_wrap(_screen(score: 92)));
      await tester.pumpAndSettle();
      expect(find.text('パーフェクト！'), findsOneWidget);
    });

    testWidgets('score 80-89 shows エクセレント！', (tester) async {
      await tester.pumpWidget(_wrap(_screen(score: 80)));
      await tester.pumpAndSettle();
      expect(find.text('エクセレント！'), findsOneWidget);
    });

    testWidgets('score 70-79 shows グッド！', (tester) async {
      await tester.pumpWidget(_wrap(_screen(score: 70)));
      await tester.pumpAndSettle();
      expect(find.text('グッド！'), findsOneWidget);
    });

    testWidgets('score < 70 shows チャレンジ中', (tester) async {
      await tester.pumpWidget(_wrap(_screen(score: 65)));
      await tester.pumpAndSettle();
      expect(find.text('チャレンジ中'), findsOneWidget);
    });

    testWidgets('tapping "別のレッスンに挑戦" does not throw', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pumpAndSettle();
      // The screen is the root route so pop() silently fails — no crash expected
      await tester.tap(find.text('別のレッスンに挑戦'));
      await tester.pumpAndSettle();
    });
  });
}
