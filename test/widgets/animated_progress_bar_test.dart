import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/widgets/animated_progress_bar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AnimatedProgressBar', () {
    testWidgets('renders LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.5)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows percentage text after animation', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.75)),
      );
      await tester.pumpAndSettle();
      // After animation completes the text shows the final percentage
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows 0% for value 0.0', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.0)),
      );
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows 100% for value 1.0', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 1.0)),
      );
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('does NOT show label when label is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.5)),
      );
      await tester.pumpAndSettle();
      // Only the percentage text should appear, no label
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows label when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.5, label: '進捗')),
      );
      await tester.pumpAndSettle();
      expect(find.text('進捗'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('custom height is applied', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.3, height: 16.0)),
      );
      await tester.pumpAndSettle();
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 16.0);
    });

    testWidgets('updates animation when value changes', (tester) async {
      // Start at 0.4
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.4)),
      );
      await tester.pumpAndSettle();
      expect(find.text('40%'), findsOneWidget);

      // Update to 0.8
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(value: 0.8)),
      );
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('custom labelStyle is applied', (tester) async {
      const style = TextStyle(fontSize: 18, color: Colors.red);
      await tester.pumpWidget(
        _wrap(const AnimatedProgressBar(
          value: 0.5,
          label: 'テスト',
          labelStyle: style,
        )),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('テスト'));
      expect(text.style?.fontSize, 18);
      expect(text.style?.color, Colors.red);
    });
  });
}
