import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/widgets/animated_option_card.dart';

void main() {
  group('AnimatedOptionCard', () {
    testWidgets('displays label and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionCard(
              label: 'A',
              text: '友達に正直に話す',
              isSelected: false,
              isCorrect: false,
              showFeedback: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('友達に正直に話す'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped and enabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionCard(
              label: 'B',
              text: '黙って帰る',
              isSelected: false,
              isCorrect: false,
              showFeedback: false,
              isEnabled: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(AnimatedOptionCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionCard(
              label: 'C',
              text: '先生に相談する',
              isSelected: false,
              isCorrect: false,
              showFeedback: true,
              isEnabled: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(AnimatedOptionCard), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('shows check icon when correct and feedback shown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionCard(
              label: 'A',
              text: '正解の選択肢',
              isSelected: true,
              isCorrect: true,
              showFeedback: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
