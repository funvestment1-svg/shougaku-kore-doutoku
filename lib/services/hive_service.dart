import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/story.dart';
import '../models/progress.dart';
import '../models/report.dart';

class HiveService {
  static const String storiesBox = 'stories';
  static const String progressBox = 'progress';
  static const String userBox = 'user';
  static const String reportsBox = 'reports';
  static const String pendingSyncBox = 'pending_sync';
  static const String settingsBox = 'settings';

  Future<void> initialize() async {
    await Hive.initFlutter();
  }

  // Stories cache
  Future<void> cacheStories(List<Story> stories) async {
    final box = await Hive.openBox<String>(storiesBox);
    for (final story in stories) {
      await box.put(story.id, jsonEncode(story.toJson()));
    }
  }

  Future<Story?> getCachedStory(String storyId) async {
    final box = await Hive.openBox<String>(storiesBox);
    final jsonString = box.get(storyId);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Story.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// キャッシュ済みストーリー一覧を返す。theme / gradeLevel / isPremium でフィルタ可。
  Future<List<Story>> getCachedStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    final box = await Hive.openBox<String>(storiesBox);
    final stories = <Story>[];
    for (final jsonString in box.values) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final story = Story.fromJson(json);
        if (theme != null && story.theme != theme) continue;
        if (gradeLevel != null && story.gradeLevel != gradeLevel) continue;
        if (isPremium != null && story.isPremium != isPremium) continue;
        stories.add(story);
      } catch (_) {
        // 壊れたエントリはスキップ
      }
    }
    // 更新日時降順
    stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return stories;
  }

  Future<void> clearStoriesCache() async {
    final box = await Hive.openBox<String>(storiesBox);
    await box.clear();
  }

  // Progress cache
  Future<void> cacheProgress(Progress progress) async {
    final box = await Hive.openBox<String>(progressBox);
    await box.put(progress.id, jsonEncode(progress.toJson()));
  }

  /// 進捗リストをまとめてキャッシュ
  Future<void> cacheProgressList(List<Progress> items) async {
    if (items.isEmpty) return;
    final box = await Hive.openBox<String>(progressBox);
    for (final p in items) {
      await box.put(p.id, jsonEncode(p.toJson()));
    }
  }

  Future<List<Progress>> getCachedProgress(String childId) async {
    final box = await Hive.openBox<String>(progressBox);
    final progressList = <Progress>[];

    for (final entry in box.values) {
      try {
        final json = jsonDecode(entry) as Map<String, dynamic>;
        final progress = Progress.fromJson(json);
        if (progress.childId == childId) {
          progressList.add(progress);
        }
      } catch (e) {
        // Skip corrupted entries
      }
    }

    return progressList;
  }

  Future<void> clearProgressCache() async {
    final box = await Hive.openBox<String>(progressBox);
    await box.clear();
  }

  // User cache
  Future<void> cacheUserId(String userId) async {
    final box = await Hive.openBox<String>(userBox);
    await box.put('currentUserId', userId);
  }

  Future<String?> getCachedUserId() async {
    final box = await Hive.openBox<String>(userBox);
    return box.get('currentUserId');
  }

  Future<void> clearUserCache() async {
    final box = await Hive.openBox<String>(userBox);
    await box.clear();
  }

  // ============ レポートキャッシュ ============

  Future<void> cacheMonthlyReport(MonthlyReport report) async {
    final box = await Hive.openBox<String>(reportsBox);
    final key = '${report.childId}_${report.year}_${report.month}';
    await box.put(key, jsonEncode(report.toJson()));
    developer.log('Report cached: $key', name: 'HiveService');
  }

  Future<MonthlyReport?> getCachedMonthlyReport(
    String childId,
    int year,
    int month,
  ) async {
    final box = await Hive.openBox<String>(reportsBox);
    final key = '${childId}_${year}_$month';
    final jsonString = box.get(key);
    if (jsonString == null) return null;
    try {
      return MonthlyReport.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (e) {
      developer.log('Report cache parse error: $e', name: 'HiveService', error: e);
      return null;
    }
  }

  // ============ オフライン同期キュー ============

  /// オフライン時に完了したクイズを同期キューに追加
  Future<void> enqueuePendingQuizCompletion(Map<String, dynamic> data) async {
    final box = await Hive.openBox<String>(pendingSyncBox);
    final key = 'quiz_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, jsonEncode({'type': 'quiz_completion', 'data': data}));
    developer.log('Pending quiz enqueued: $key', name: 'HiveService');
  }

  /// 同期待ちアイテムをすべて取得
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final box = await Hive.openBox<String>(pendingSyncBox);
    final items = <Map<String, dynamic>>[];
    for (final entry in box.toMap().entries) {
      try {
        final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
        items.add({'key': entry.key, ...decoded});
      } catch (_) {}
    }
    return items;
  }

  /// 同期完了したアイテムを削除
  Future<void> removePendingSyncItem(String key) async {
    final box = await Hive.openBox<String>(pendingSyncBox);
    await box.delete(key);
  }

  Future<int> getPendingSyncCount() async {
    final box = await Hive.openBox<String>(pendingSyncBox);
    return box.length;
  }

  // ============ 設定 ============

  Future<void> saveSetting(String key, dynamic value) async {
    final box = await Hive.openBox<dynamic>(settingsBox);
    await box.put(key, value);
  }

  Future<T?> getSetting<T>(String key) async {
    final box = await Hive.openBox<dynamic>(settingsBox);
    final value = box.get(key);
    if (value is T) return value;
    return null;
  }

  // ============ 全クリア ============

  Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(storiesBox);
    await Hive.deleteBoxFromDisk(progressBox);
    await Hive.deleteBoxFromDisk(reportsBox);
    await Hive.deleteBoxFromDisk(userBox);
    await Hive.deleteBoxFromDisk(settingsBox);
    developer.log('All Hive data cleared', name: 'HiveService');
  }
}
