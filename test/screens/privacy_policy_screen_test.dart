import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/screens/settings/privacy_policy_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('PrivacyPolicyScreen', () {
    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(_wrap(const PrivacyPolicyScreen()));
      expect(find.text('プライバシーポリシー'), findsWidgets); // AppBar + heading
    });

    testWidgets('renders all required policy sections', (tester) async {
      await tester.pumpWidget(_wrap(const PrivacyPolicyScreen()));

      // SingleChildScrollView + Column puts all children in the tree at once —
      // no scrolling required to find off-screen text.
      expect(find.text('1. 収集する情報'), findsOneWidget);
      expect(find.text('2. 情報の利用目的'), findsOneWidget);
      expect(find.text('3. 情報の共有'), findsOneWidget);
      expect(find.text('4. 子どものプライバシー（COPPA対応）'), findsOneWidget);
    });

    testWidgets('renders footer with policy date', (tester) async {
      await tester.pumpWidget(_wrap(const PrivacyPolicyScreen()));
      expect(find.textContaining('制定日'), findsOneWidget);
    });

    testWidgets('bullet list items are rendered', (tester) async {
      await tester.pumpWidget(_wrap(const PrivacyPolicyScreen()));
      expect(find.textContaining('保護者のメールアドレス'), findsOneWidget);
    });
  });
}
