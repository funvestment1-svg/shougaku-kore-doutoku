import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'
    show apiServiceProvider, hiveServiceProvider;
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import '../helpers/fake_path_provider.dart';

// ── Fake HiveService ──────────────────────────────────────────────────────
//
// Overrides cacheProgressList with a no-op so the fire-and-forget call inside
// userProgressProvider does not outlive tearDown and cause late test failures.
// All other methods (cacheProgress, getCachedProgress, …) delegate to the real
// Hive implementation and work normally.

class _NoOpCacheHiveService extends HiveService {
  @override
  Future<void> cacheProgressList(List<Progress> items) async {
    // Intentional no-op: avoids fire-and-forget Hive I/O racing tearDown.
  }
}

// ── Fake ApiService ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  List<Progress> progressResult = [];
  bool shouldFail = false;

  @override
  Future<List<Progress>> fetchProgress(String childId, {int limit = 100}) async {
    if (shouldFail) throw Exception('network error');
    return progressResult;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Progress _makeProgress({
  required String id,
  required String childId,
  String action = 'story_completed',
  String? storyId,
  DateTime? recordedAt,
}) =>
    Progress(
      id: id,
      childId: childId,
      action: action,
      storyId: storyId ?? 'story-$id',
      pointsDelta: 10,
      recordedAt: recordedAt ?? DateTime.now(),
    );

ProviderContainer _makeContainer({
  required _FakeApiService api,
  required HiveService hive,
  List<Override> extra = const [],
}) =>
    ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      hiveServiceProvider.overrideWithValue(hive),
      ...extra,
    ]);

void main() {
  late HiveService hive;
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('progress_provider_test_');
    Hive.init(testDir.path);
    hive = _NoOpCacheHiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  // ── userProgressProvider ─────────────────────────────────────────────────

  group('userProgressProvider', () {
    test('returns API data on success', () async {
      api.progressResult = [
        _makeProgress(id: 'p1', childId: 'child-1'),
        _makeProgress(id: 'p2', childId: 'child-1'),
      ];
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final items =
          await container.read(userProgressProvider('child-1').future);
      expect(items.length, 2);
      expect(items.first.id, 'p1');
    });

    test('returns cached data when API fails and cache is non-empty', () async {
      // Seed Hive first
      await hive.cacheProgress(_makeProgress(id: 'cached-p', childId: 'child-1'));

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final items =
          await container.read(userProgressProvider('child-1').future);
      expect(items.length, 1);
      expect(items.first.id, 'cached-p');
    });

    test('rethrows when API fails and cache is empty', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        container.read(userProgressProvider('child-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── weeklyActivityProvider ───────────────────────────────────────────────

  group('weeklyActivityProvider', () {
    test('counts story_completed events by weekday for past 7 days', () async {
      final now = DateTime.now();

      // 3 events today
      final today = now;
      final todayIdx = (today.weekday - 1) % 7;

      final items = [
        _makeProgress(id: 'p1', childId: 'c', recordedAt: today),
        _makeProgress(id: 'p2', childId: 'c', recordedAt: today),
        _makeProgress(id: 'p3', childId: 'c', recordedAt: today),
        // Non-story action — must be excluded
        _makeProgress(id: 'p4', childId: 'c', action: 'badge_earned', recordedAt: today),
        // More than 7 days ago — must be excluded
        _makeProgress(
            id: 'p5', childId: 'c', recordedAt: now.subtract(const Duration(days: 8))),
      ];

      final container = _makeContainer(
        api: api,
        hive: hive,
        extra: [
          userProgressProvider
              .overrideWith((ref, childId) async => items),
        ],
      );
      addTearDown(container.dispose);

      final counts =
          await container.read(weeklyActivityProvider('c').future);

      expect(counts.length, 7);
      expect(counts[todayIdx], 3);
      // Total across all days = 3 (badge_earned and old item excluded)
      expect(counts.reduce((a, b) => a + b), 3);
    });

    test('excludes events older than 7 days (boundary: exactly 7 days ago is excluded)', () async {
      final now = DateTime.now();
      final exactlySevenDaysAgo = now.subtract(const Duration(days: 7));
      // diff = 7; condition is `diff < 7` → must be excluded

      final items = [
        _makeProgress(id: 'p1', childId: 'c', recordedAt: exactlySevenDaysAgo),
      ];

      final container = _makeContainer(
        api: api,
        hive: hive,
        extra: [
          userProgressProvider.overrideWith((ref, childId) async => items),
        ],
      );
      addTearDown(container.dispose);

      final counts =
          await container.read(weeklyActivityProvider('c').future);
      expect(counts.reduce((a, b) => a + b), 0);
    });

    test('returns all-zeros when progress list is empty', () async {
      final container = _makeContainer(
        api: api,
        hive: hive,
        extra: [
          userProgressProvider.overrideWith((ref, childId) async => []),
        ],
      );
      addTearDown(container.dispose);

      final counts =
          await container.read(weeklyActivityProvider('c').future);
      expect(counts, List<int>.filled(7, 0));
    });

    test('returns all-zeros when userProgressProvider throws', () async {
      final container = _makeContainer(
        api: api,
        hive: hive,
        extra: [
          userProgressProvider
              .overrideWith((ref, childId) async => throw Exception('offline')),
        ],
      );
      addTearDown(container.dispose);

      final counts =
          await container.read(weeklyActivityProvider('c').future);
      expect(counts, List<int>.filled(7, 0));
    });

    test('counts items from 6 days ago (still within 7-day window)', () async {
      final now = DateTime.now();
      final sixDaysAgo = now.subtract(const Duration(days: 6));
      final sixDaysAgoIdx = (sixDaysAgo.weekday - 1) % 7;

      final items = [
        _makeProgress(id: 'p1', childId: 'c', recordedAt: sixDaysAgo),
        _makeProgress(id: 'p2', childId: 'c', recordedAt: sixDaysAgo),
      ];

      final container = _makeContainer(
        api: api,
        hive: hive,
        extra: [
          userProgressProvider.overrideWith((ref, childId) async => items),
        ],
      );
      addTearDown(container.dispose);

      final counts =
          await container.read(weeklyActivityProvider('c').future);
      expect(counts[sixDaysAgoIdx], 2);
    });
  });
}
