import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/providers/offline_sync_provider.dart';
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import '../helpers/fake_path_provider.dart';

/// Fake ApiService that intercepts completeQuizSession without touching the
/// network. All other methods remain unoverridden (and should never be called).
class _FakeApiService extends ApiService {
  int completeCalls = 0;
  bool shouldFail = false;
  String? lastSessionId;

  @override
  Future<Map<String, dynamic>> completeQuizSession({
    required String sessionId,
    required String chosenChoiceId,
    required int timeSpentSeconds,
    String? reflectionText,
  }) async {
    if (shouldFail) throw Exception('simulated offline failure');
    completeCalls++;
    lastSessionId = sessionId;
    return {
      'id': sessionId,
      'isCompleted': true,
      'pointsEarned': 10,
      'newLevel': 1,
      'newTotalPoints': 10,
      'scoreDeltas': <String, dynamic>{},
    };
  }
}

void main() {
  late HiveService hive;
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    // Initialize dotenv with an empty map so ApiService constructor succeeds.
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('sync_provider_test_');
    Hive.init(testDir.path);
    hive = HiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('OfflineSyncNotifier', () {
    test('initial pendingCount loads from Hive', () async {
      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'q1',
        'chosenChoiceId': 'c1',
        'timeSpentSeconds': 30,
      });
      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'q2',
        'chosenChoiceId': 'c2',
        'timeSpentSeconds': 60,
      });

      final notifier = OfflineSyncNotifier(hive, api);
      // _loadPendingCount is async — pump the microtask queue
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.pendingCount, 2);
      expect(notifier.state.status, SyncStatus.idle);
    });

    test('syncPendingItems sends each item to the API and removes it', () async {
      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'session-abc',
        'chosenChoiceId': 'choice-xyz',
        'timeSpentSeconds': 90,
        'reflectionText': '頑張りました',
      });

      final notifier = OfflineSyncNotifier(hive, api);
      await notifier.syncPendingItems();

      expect(api.completeCalls, 1);
      expect(api.lastSessionId, 'session-abc');
      expect(notifier.state.status, SyncStatus.success);
      expect(notifier.state.pendingCount, 0);

      final remaining = await hive.getPendingSyncCount();
      expect(remaining, 0);
    });

    test('syncPendingItems on empty queue transitions to success', () async {
      final notifier = OfflineSyncNotifier(hive, api);
      await notifier.syncPendingItems();

      expect(notifier.state.status, SyncStatus.success);
      expect(api.completeCalls, 0);
    });

    test('syncPendingItems: failed item is kept in queue; state transitions to success', () async {
      api.shouldFail = true;
      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'q-fail',
        'chosenChoiceId': 'c-fail',
        'timeSpentSeconds': 15,
      });

      final notifier = OfflineSyncNotifier(hive, api);
      await notifier.syncPendingItems();

      // Per-item errors are swallowed; outer loop still reaches success state
      expect(notifier.state.status, SyncStatus.success);
      // Failed item must stay in the queue for the next sync attempt
      final remaining = await hive.getPendingSyncCount();
      expect(remaining, 1);
    });

    test('syncPendingItems skips second concurrent call', () async {
      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'q1',
        'chosenChoiceId': 'c1',
        'timeSpentSeconds': 20,
      });

      final notifier = OfflineSyncNotifier(hive, api);

      // Start first sync without awaiting — state immediately becomes syncing
      final firstSync = notifier.syncPendingItems();

      // Second call while first is in-flight should be a no-op
      await notifier.syncPendingItems();

      await firstSync;
      // Only one API call should have been made (second invocation was skipped)
      expect(api.completeCalls, 1);
    });

    test('refresh reloads pendingCount and resets status to idle', () async {
      final notifier = OfflineSyncNotifier(hive, api);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.pendingCount, 0);

      await hive.enqueuePendingQuizCompletion({
        'sessionId': 'q1',
        'chosenChoiceId': 'c1',
        'timeSpentSeconds': 10,
      });

      await notifier.refresh();
      expect(notifier.state.pendingCount, 1);
      expect(notifier.state.status, SyncStatus.idle);
    });

    test('OfflineSyncState.copyWith replaces only specified fields', () {
      const original = OfflineSyncState(
        status: SyncStatus.idle,
        pendingCount: 3,
        lastError: null,
      );

      final updated = original.copyWith(status: SyncStatus.error, lastError: 'oops');
      expect(updated.status, SyncStatus.error);
      expect(updated.pendingCount, 3); // unchanged
      expect(updated.lastError, 'oops');
    });
  });
}
