import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../helpers/fake_path_provider.dart';

Story _makeStory({
  required String id,
  required String theme,
  int gradeLevel = 3,
  bool isPremium = false,
}) {
  return Story(
    id: id,
    title: 'タイトル $id',
    theme: theme,
    gradeLevel: gradeLevel,
    isPremium: isPremium,
    durationSeconds: 300,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  late HiveService hiveService;
  late Directory testDir;

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    // Use a unique directory per test run to avoid stale data
    testDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(testDir.path);
    hiveService = HiveService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('HiveService', () {
    test('saveSetting and getSetting round-trip', () async {
      await hiveService.saveSetting('test_key', 'test_value');
      final value = await hiveService.getSetting<String>('test_key');
      expect(value, 'test_value');
    });

    test('getSetting returns null for missing key', () async {
      final value = await hiveService.getSetting<String>('missing_key');
      expect(value, isNull);
    });

    test('cacheUserId and getCachedUserId', () async {
      await hiveService.cacheUserId('user-123');
      final userId = await hiveService.getCachedUserId();
      expect(userId, 'user-123');
    });

    test('pending sync enqueue and count', () async {
      await hiveService.enqueuePendingQuizCompletion({'sessionId': 'q1'});
      await hiveService.enqueuePendingQuizCompletion({'sessionId': 'q2'});
      final count = await hiveService.getPendingSyncCount();
      expect(count, 2);
    });

    test('getPendingSyncItems returns all items', () async {
      await hiveService.enqueuePendingQuizCompletion({'sessionId': 'q1'});
      final items = await hiveService.getPendingSyncItems();
      expect(items.length, 1);
      expect(items.first['type'], 'quiz_completion');
    });

    test('removePendingSyncItem decrements count', () async {
      await hiveService.enqueuePendingQuizCompletion({'sessionId': 'q1'});
      final items = await hiveService.getPendingSyncItems();
      final key = items.first['key'] as String;
      await hiveService.removePendingSyncItem(key);
      final count = await hiveService.getPendingSyncCount();
      expect(count, 0);
    });

    // ── ストーリーキャッシュ ────────────────────────────────────────
    group('story cache', () {
      test('cacheStories and getCachedStory round-trip', () async {
        final story = _makeStory(id: 's1', theme: 'kindness');
        await hiveService.cacheStories([story]);
        final fetched = await hiveService.getCachedStory('s1');
        expect(fetched, isNotNull);
        expect(fetched!.id, 's1');
        expect(fetched.theme, 'kindness');
      });

      test('getCachedStory returns null for unknown id', () async {
        final fetched = await hiveService.getCachedStory('unknown');
        expect(fetched, isNull);
      });

      test('getCachedStories returns all when no filter', () async {
        await hiveService.cacheStories([
          _makeStory(id: 's1', theme: 'kindness'),
          _makeStory(id: 's2', theme: 'honesty'),
        ]);
        final all = await hiveService.getCachedStories();
        expect(all.length, 2);
      });

      test('getCachedStories filters by theme', () async {
        await hiveService.cacheStories([
          _makeStory(id: 's1', theme: 'kindness'),
          _makeStory(id: 's2', theme: 'honesty'),
          _makeStory(id: 's3', theme: 'kindness'),
        ]);
        final kindness = await hiveService.getCachedStories(theme: 'kindness');
        expect(kindness.length, 2);
        expect(kindness.every((s) => s.theme == 'kindness'), isTrue);
      });

      test('getCachedStories filters by isPremium', () async {
        await hiveService.cacheStories([
          _makeStory(id: 's1', theme: 'kindness', isPremium: false),
          _makeStory(id: 's2', theme: 'honesty', isPremium: true),
        ]);
        final premium = await hiveService.getCachedStories(isPremium: true);
        expect(premium.length, 1);
        expect(premium.first.id, 's2');
      });

      test('getCachedStories returns empty list when cache is empty', () async {
        final result = await hiveService.getCachedStories(theme: 'kindness');
        expect(result, isEmpty);
      });

      test('clearStoriesCache empties the box', () async {
        await hiveService.cacheStories([_makeStory(id: 's1', theme: 'kindness')]);
        await hiveService.clearStoriesCache();
        final all = await hiveService.getCachedStories();
        expect(all, isEmpty);
      });
    });

    // ── 進捗キャッシュ ─────────────────────────────────────────────────
    group('progress cache', () {
      Progress _makeProgress({
        required String id,
        required String childId,
        String action = 'story_completed',
        int pointsDelta = 10,
      }) =>
          Progress(
            id: id,
            childId: childId,
            action: action,
            pointsDelta: pointsDelta,
            recordedAt: DateTime(2024, 6, 1),
          );

      test('cacheProgress and getCachedProgress round-trip', () async {
        final p = _makeProgress(id: 'p1', childId: 'child-a');
        await hiveService.cacheProgress(p);
        final list = await hiveService.getCachedProgress('child-a');
        expect(list.length, 1);
        expect(list.first.id, 'p1');
        expect(list.first.pointsDelta, 10);
      });

      test('cacheProgressList stores all items', () async {
        final items = [
          _makeProgress(id: 'p1', childId: 'child-a'),
          _makeProgress(id: 'p2', childId: 'child-a', pointsDelta: 15),
          _makeProgress(id: 'p3', childId: 'child-b'),
        ];
        await hiveService.cacheProgressList(items);
        final forA = await hiveService.getCachedProgress('child-a');
        expect(forA.length, 2);
        final forB = await hiveService.getCachedProgress('child-b');
        expect(forB.length, 1);
      });

      test('cacheProgressList with empty list is a no-op', () async {
        await hiveService.cacheProgressList([]);
        final list = await hiveService.getCachedProgress('child-x');
        expect(list, isEmpty);
      });

      test('getCachedProgress returns only matching childId', () async {
        await hiveService.cacheProgressList([
          _makeProgress(id: 'p1', childId: 'child-1'),
          _makeProgress(id: 'p2', childId: 'child-2'),
        ]);
        final result = await hiveService.getCachedProgress('child-1');
        expect(result.length, 1);
        expect(result.first.id, 'p1');
      });

      test('getCachedProgress returns empty list when nothing cached', () async {
        final list = await hiveService.getCachedProgress('nobody');
        expect(list, isEmpty);
      });

      test('clearProgressCache removes all progress entries', () async {
        await hiveService.cacheProgress(
          _makeProgress(id: 'p1', childId: 'child-a'),
        );
        await hiveService.clearProgressCache();
        final list = await hiveService.getCachedProgress('child-a');
        expect(list, isEmpty);
      });
    });

    // ── レポートキャッシュ ─────────────────────────────────────────────
    group('report cache', () {
      MonthlyReport _makeReport({
        required String childId,
        int year = 2024,
        int month = 6,
        int storiesCompleted = 3,
      }) =>
          MonthlyReport(
            id: '${childId}_${year}_$month',
            childId: childId,
            year: year,
            month: month,
            storiesCompleted: storiesCompleted,
            generatedAt: DateTime(2024, 6, 30),
          );

      test('cacheMonthlyReport and getCachedMonthlyReport round-trip', () async {
        final report = _makeReport(childId: 'child-a');
        await hiveService.cacheMonthlyReport(report);
        final fetched = await hiveService.getCachedMonthlyReport('child-a', 2024, 6);
        expect(fetched, isNotNull);
        expect(fetched!.childId, 'child-a');
        expect(fetched.storiesCompleted, 3);
      });

      test('getCachedMonthlyReport returns null for missing key', () async {
        final result = await hiveService.getCachedMonthlyReport('child-x', 2024, 1);
        expect(result, isNull);
      });

      test('cacheMonthlyReport overwrites previous entry for same period', () async {
        await hiveService.cacheMonthlyReport(_makeReport(childId: 'child-a', storiesCompleted: 1));
        await hiveService.cacheMonthlyReport(_makeReport(childId: 'child-a', storiesCompleted: 5));
        final fetched = await hiveService.getCachedMonthlyReport('child-a', 2024, 6);
        expect(fetched!.storiesCompleted, 5);
      });
    });
  });
}
