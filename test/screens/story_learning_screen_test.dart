import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/audio_provider.dart';
import 'package:shougaku_kore_doutoku/providers/auth_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';
import 'package:shougaku_kore_doutoku/screens/story/story_learning_screen.dart';
import 'package:shougaku_kore_doutoku/services/audio_service.dart';
import '../helpers/fake_path_provider.dart';

// ─── No-op AudioService ──────────────────────────────────────────────────────

class _NoOpAudioService extends AudioService {
  @override
  Future<void> speak(
    String text, {
    double speed = 1.0,
    double volume = 0.8,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> playSoundEffect(
    String soundName, {
    double volume = 0.8,
  }) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> dispose() async {}
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _choice1 = StoryChoice(
  id: 'c1',
  text: '正直に話す',
  value: 'honesty',
  branchContent: '友達に正直に話した結果、仲直りできました。',
  reflection: '正直に話すことは大切ですね。',
);

final _choice2 = StoryChoice(
  id: 'c2',
  text: '黙っていた',
  value: 'kindness',
  branchContent: '黙っていたら友達は悲しそうでした。',
  reflection: '相手の気持ちを考えることが大切ですね。',
);

final _testStory = Story(
  id: 'story-1',
  title: '友達との約束',
  theme: 'honesty',
  gradeLevel: 3,
  isPremium: false,
  durationSeconds: 300,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  content: StoryContent(
    introduction: 'ある日、たろうは友達との約束を忘れてしまいました。',
    mainNarrative: ['友達のはなこがたろうを待っていました。'],
    dilemmaScene: 'さて、たろうはどうすればよいでしょうか？',
    choices: [_choice1, _choice2],
  ),
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({Story? storyOverride, bool storyError = false}) {
  return ProviderScope(
    overrides: [
      userAuthStateProvider.overrideWith((_) => Stream.value(null)),
      audioServiceProvider.overrideWith((ref) => _NoOpAudioService()),
      storyDetailProvider.overrideWith((ref, storyId) {
        if (storyError) return Future.error(Exception('network error'));
        return Future.value(storyOverride ?? _testStory);
      }),
    ],
    child: MaterialApp(
      home: StoryLearningScreen(storyId: 'story-1', childId: 'child-1'),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    try {
      await Hive.close();
    } catch (_) {}
  });

  group('StoryLearningScreen', () {
    testWidgets('shows loading indicator while story loads', (tester) async {
      // Completer<Story> never completes — no pending timers, correctly typed
      final completer = Completer<Story>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAuthStateProvider.overrideWith((_) => Stream.value(null)),
            audioServiceProvider.overrideWith((ref) => _NoOpAudioService()),
            storyDetailProvider.overrideWith(
              (ref, _) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: StoryLearningScreen(storyId: 's1', childId: 'c1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text when story fails to load', (tester) async {
      await tester.pumpWidget(_wrap(storyError: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('エラー'), findsOneWidget);
    });

    testWidgets('shows story title in header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('友達との約束'), findsOneWidget);
    });

    testWidgets('shows close button in header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows audio volume icon button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // either volume_up or volume_off depending on narration state
      final hasVolumeUp = find.byIcon(Icons.volume_up).evaluate().isNotEmpty;
      final hasVolumeOff = find.byIcon(Icons.volume_off).evaluate().isNotEmpty;
      expect(hasVolumeUp || hasVolumeOff, isTrue);
    });

    testWidgets('shows introduction text on first page', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.textContaining('ある日'), findsOneWidget);
    });

    testWidgets('shows はじめに label on first page', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('はじめに'), findsOneWidget);
    });

    testWidgets('shows 次のページへ navigation button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('次のページへ'), findsOneWidget);
    });

    testWidgets('shows page progress indicator text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.textContaining('1 / '), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator in header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping close shows exit dialog', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('ストーリーを中断しますか？'), findsOneWidget);
      expect(find.text('続ける'), findsOneWidget);
      expect(find.text('中断する'), findsOneWidget);
    });

    testWidgets('dismissing exit dialog with 続ける keeps the screen',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('続ける'));
      await tester.pumpAndSettle();
      // Dialog closed, story title still visible
      expect(find.text('友達との約束'), findsOneWidget);
    });
  });
}
