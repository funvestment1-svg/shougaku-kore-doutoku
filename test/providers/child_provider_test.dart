import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'
    show apiServiceProvider;
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import '../helpers/fake_path_provider.dart';

// ── Fake ApiService ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  List<ChildProfile> childrenResult = [];
  ChildProfile? singleChildResult;
  ChildProfile? createResult;
  ChildProfile? updateResult;
  bool shouldFail = false;

  @override
  Future<List<ChildProfile>> fetchChildrenProfiles() async {
    if (shouldFail) throw Exception('network error');
    return childrenResult;
  }

  @override
  Future<ChildProfile> fetchChildProfile(String childId) async {
    if (shouldFail) throw Exception('network error');
    if (singleChildResult == null) throw Exception('not found');
    return singleChildResult!;
  }

  @override
  Future<ChildProfile> createChild({
    required String name,
    required int grade,
    required String avatarEmoji,
  }) async {
    if (shouldFail) throw Exception('network error');
    if (createResult == null) throw Exception('createResult not set');
    return createResult!;
  }

  @override
  Future<ChildProfile> updateChild(
    String childId,
    Map<String, dynamic> updates,
  ) async {
    if (shouldFail) throw Exception('network error');
    if (updateResult == null) throw Exception('updateResult not set');
    return updateResult!;
  }

  @override
  Future<void> deleteChild(String childId) async {
    if (shouldFail) throw Exception('network error');
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

ChildProfile _makeProfile({
  required String id,
  String parentId = 'parent-1',
  String name = 'テスト太郎',
  int grade = 3,
}) =>
    ChildProfile(
      id: id,
      parentId: parentId,
      name: name,
      grade: grade,
      createdAt: DateTime(2024),
    );

ProviderContainer _makeContainer({required _FakeApiService api}) =>
    ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
    ]);

/// Pump the event loop once to allow fire-and-forget async operations
/// (e.g. _ChildIdNotifier._loadFromHive) to complete.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('child_provider_test_');
    Hive.init(testDir.path);
    // Pre-open the settings box so _ChildIdNotifier._loadFromHive
    // resolves in a single microtask turn (box.get is a sync lookup once open).
    await Hive.openBox<dynamic>('settings');
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  // ── childrenProfilesProvider ──────────────────────────────────────────────

  group('childrenProfilesProvider', () {
    test('returns list of child profiles on success', () async {
      api.childrenResult = [
        _makeProfile(id: 'c1', name: '太郎'),
        _makeProfile(id: 'c2', name: '花子'),
      ];
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final profiles = await container.read(childrenProfilesProvider.future);
      expect(profiles.length, 2);
      expect(profiles.first.id, 'c1');
    });

    test('returns empty list when no children', () async {
      api.childrenResult = [];
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final profiles = await container.read(childrenProfilesProvider.future);
      expect(profiles, isEmpty);
    });

    test('throws when API fails', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      await expectLater(
        container.read(childrenProfilesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── childProfileProvider ──────────────────────────────────────────────────

  group('childProfileProvider', () {
    test('returns child profile on success', () async {
      api.singleChildResult = _makeProfile(id: 'child-abc', name: '次郎');
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final profile =
          await container.read(childProfileProvider('child-abc').future);
      expect(profile.id, 'child-abc');
      expect(profile.name, '次郎');
    });

    test('throws when API fails', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      await expectLater(
        container.read(childProfileProvider('any-id').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── ChildProfileNotifier ──────────────────────────────────────────────────

  group('ChildProfileNotifier', () {
    test('createChildProfile returns new profile and invalidates list',
        () async {
      api.createResult = _makeProfile(id: 'new-child', name: '三郎');
      api.childrenResult = [api.createResult!];

      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      final profile = await notifier.createChildProfile(
        name: '三郎',
        grade: 3,
        avatarEmoji: '🐱',
      );

      expect(profile.id, 'new-child');
      expect(profile.name, '三郎');
      expect(
          container.read(childProfileNotifierProvider), isA<AsyncData<void>>());
    });

    test('createChildProfile sets error state when API fails', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await expectLater(
        notifier.createChildProfile(name: 'fail', grade: 3, avatarEmoji: '🐶'),
        throwsA(isA<Exception>()),
      );
      expect(
        container.read(childProfileNotifierProvider),
        isA<AsyncError<void>>(),
      );
    });

    test('updateChildProfile sets state to data(null) on success', () async {
      api.updateResult = _makeProfile(id: 'c1', name: '新名前');
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await notifier.updateChildProfile(childId: 'c1', name: '新名前');

      expect(
          container.read(childProfileNotifierProvider), isA<AsyncData<void>>());
    });

    test('updateChildProfile rethrows and sets error state when API fails',
        () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await expectLater(
        notifier.updateChildProfile(childId: 'c1', name: 'fail'),
        throwsA(isA<Exception>()),
      );
      expect(
        container.read(childProfileNotifierProvider),
        isA<AsyncError<void>>(),
      );
    });

    test('deleteChildProfile resets currentChildId when it matches', () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      // Trigger _ChildIdNotifier creation and let _loadFromHive complete
      container.read(currentChildIdProvider.notifier).state = 'c-selected';
      await _pump();

      expect(container.read(currentChildIdProvider), 'c-selected');

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await notifier.deleteChildProfile('c-selected');

      expect(container.read(currentChildIdProvider), isNull);
      expect(
          container.read(childProfileNotifierProvider), isA<AsyncData<void>>());
    });

    test('deleteChildProfile does not reset currentChildId for a different child',
        () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      container.read(currentChildIdProvider.notifier).state = 'other-child';
      await _pump();

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await notifier.deleteChildProfile('c-to-delete');

      expect(container.read(currentChildIdProvider), 'other-child');
    });

    test('deleteChildProfile throws and sets error state when API fails',
        () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      await expectLater(
        notifier.deleteChildProfile('any-id'),
        throwsA(isA<Exception>()),
      );
      expect(
        container.read(childProfileNotifierProvider),
        isA<AsyncError<void>>(),
      );
    });

    test('selectChild updates currentChildId', () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      notifier.selectChild('child-xyz');
      await _pump(); // let _ChildIdNotifier._loadFromHive finish
      expect(container.read(currentChildIdProvider), 'child-xyz');
    });

    test('deselectChild clears currentChildId', () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      final notifier = container.read(childProfileNotifierProvider.notifier);
      notifier.selectChild('child-abc');
      await _pump();
      notifier.deselectChild();
      expect(container.read(currentChildIdProvider), isNull);
    });
  });

  // ── currentChildIdProvider ────────────────────────────────────────────────

  group('currentChildIdProvider', () {
    test('initial state is null', () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      // Reading the provider triggers _ChildIdNotifier._loadFromHive
      container.read(currentChildIdProvider);
      await _pump(); // let _loadFromHive complete
      expect(container.read(currentChildIdProvider), isNull);
    });

    test('state is updated synchronously when set', () async {
      final container = _makeContainer(api: api);
      addTearDown(container.dispose);

      container.read(currentChildIdProvider.notifier).state = 'child-sync';
      await _pump();
      expect(container.read(currentChildIdProvider), 'child-sync');
    });

    test('state persists to Hive and is available to a new container',
        () async {
      // Container 1: write a value
      final container1 = _makeContainer(api: api);
      container1.read(currentChildIdProvider.notifier).state = 'persistent-id';
      // Let saveSetting and _loadFromHive both finish
      await _pump();
      await _pump();
      container1.dispose();

      // Container 2: should read the persisted value (settings box stays open)
      final container2 = _makeContainer(api: api);
      addTearDown(container2.dispose);
      container2.read(currentChildIdProvider); // trigger _loadFromHive
      await _pump();
      expect(container2.read(currentChildIdProvider), 'persistent-id');
    });
  });
}
