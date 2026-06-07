import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/providers/audio_provider.dart';
import 'package:shougaku_kore_doutoku/services/audio_service.dart';
import '../helpers/fake_path_provider.dart';

// ── Fake AudioService ──────────────────────────────────────────────────────
// Override all platform-specific methods to avoid FlutterTts I/O in tests.

class _FakeAudioService extends AudioService {
  final List<String> soundsPlayed = [];
  final List<String> textsSpoken = [];
  bool stopped = false;
  double? lastVolume;

  @override
  Future<void> playSoundEffect(String soundName, {double volume = 0.8}) async {
    soundsPlayed.add(soundName);
  }

  @override
  Future<void> speak(
      String text, {double speed = 1.0, double volume = 0.8}) async {
    textsSpoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }
}

/// Pump the event loop once to allow fire-and-forget _load calls
/// (_BoolSettingNotifier, _DoubleSettingNotifier) to complete.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAudioService audioService;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('audio_provider_test_');
    Hive.init(testDir.path);
    // Pre-open settings box so _BoolSettingNotifier/_DoubleSettingNotifier
    // fire-and-forget _load completes in a single microtask turn.
    await Hive.openBox<dynamic>('settings');
    audioService = _FakeAudioService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  ProviderContainer _makeContainer() => ProviderContainer(overrides: [
        audioServiceProvider.overrideWithValue(audioService),
      ]);

  // ── AudioControllerNotifier ───────────────────────────────────────────────

  group('AudioControllerNotifier', () {
    test('playSoundEffect calls AudioService when sound is enabled', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump(); // let settings notifiers initialize

      // isSoundEnabled defaults to true
      final controller = container.read(audioControllerProvider.notifier);
      await controller.playSoundEffect('correct');

      expect(audioService.soundsPlayed, contains('correct'));
    });

    test('playSoundEffect is skipped when sound is disabled', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      // Disable sound
      container.read(isSoundEnabledProvider.notifier).state = false;

      final controller = container.read(audioControllerProvider.notifier);
      await controller.playSoundEffect('correct');

      expect(audioService.soundsPlayed, isEmpty);
    });

    test('speakText calls AudioService when narration is enabled', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      final controller = container.read(audioControllerProvider.notifier);
      await controller.speakText('こんにちは');

      expect(audioService.textsSpoken, contains('こんにちは'));
    });

    test('speakText is skipped when narration is disabled', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      container.read(isNarrationEnabledProvider.notifier).state = false;

      final controller = container.read(audioControllerProvider.notifier);
      await controller.speakText('hello');

      expect(audioService.textsSpoken, isEmpty);
    });

    test('speakText sets currentlyPlayingAudioProvider when audioId provided',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      final controller = container.read(audioControllerProvider.notifier);
      await controller.speakText('テキスト', audioId: 'audio-123');

      expect(container.read(currentlyPlayingAudioProvider), 'audio-123');
    });

    test('stop calls AudioService.stop and clears currentlyPlayingAudio',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      // Set a playing audio first
      container.read(currentlyPlayingAudioProvider.notifier).state = 'audio-xyz';

      final controller = container.read(audioControllerProvider.notifier);
      await controller.stop();

      expect(audioService.stopped, isTrue);
      expect(container.read(currentlyPlayingAudioProvider), isNull);
    });

    test('setVolume updates volumeLevelProvider and AudioService', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      final controller = container.read(audioControllerProvider.notifier);
      controller.setVolume(0.5);

      expect(container.read(volumeLevelProvider), 0.5);
      expect(audioService.lastVolume, 0.5);
    });

    test('setNarrationSpeed updates narrationSpeedProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      final controller = container.read(audioControllerProvider.notifier);
      controller.setNarrationSpeed(1.5);

      expect(container.read(narrationSpeedProvider), 1.5);
    });

    test('toggleSoundEnabled flips isSoundEnabledProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      // Default is true
      expect(container.read(isSoundEnabledProvider), isTrue);

      final controller = container.read(audioControllerProvider.notifier);
      controller.toggleSoundEnabled();
      expect(container.read(isSoundEnabledProvider), isFalse);

      controller.toggleSoundEnabled();
      expect(container.read(isSoundEnabledProvider), isTrue);
    });

    test('toggleNarrationEnabled flips isNarrationEnabledProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();

      expect(container.read(isNarrationEnabledProvider), isTrue);

      final controller = container.read(audioControllerProvider.notifier);
      controller.toggleNarrationEnabled();
      expect(container.read(isNarrationEnabledProvider), isFalse);
    });
  });

  // ── Default provider values ───────────────────────────────────────────────

  group('default provider values', () {
    test('isSoundEnabledProvider defaults to true', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();
      expect(container.read(isSoundEnabledProvider), isTrue);
    });

    test('isNarrationEnabledProvider defaults to true', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();
      expect(container.read(isNarrationEnabledProvider), isTrue);
    });

    test('volumeLevelProvider defaults to 0.8', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();
      expect(container.read(volumeLevelProvider), 0.8);
    });

    test('narrationSpeedProvider defaults to 1.0', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      await _pump();
      expect(container.read(narrationSpeedProvider), 1.0);
    });

    test('currentlyPlayingAudioProvider defaults to null', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(currentlyPlayingAudioProvider), isNull);
    });
  });
}
