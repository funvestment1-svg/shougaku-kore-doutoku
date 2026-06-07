import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/notification_preferences.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';

/// Firestore データアクセス層。
/// 設計書指定のスキーマパスに準拠:
///   /users/{uid}/children/{childId}
///   /users/{uid}/children/{childId}/questHistory/{id}
///   /users/{uid}/children/{childId}/learning
///   /users/{uid}/children/{childId}/achievements
///   /users/{uid}/children/{childId}/learningHistory/{date}
///   /users/{uid}/preferences
///   /stories/{storyId}
class FirestoreService {
  // ── 道徳アプリ固定のサブジェクトキー ──────────────────────────────────
  static const String _subject = 'doutoku';

  // ── Lazy getter（Firebase 未初期化対策）─────────────────────────────
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════
  // パスヘルパー
  // ══════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _childrenRef(String uid) =>
      _db.collection('users').doc(uid).collection('children');

  DocumentReference<Map<String, dynamic>> _childRef(
          String uid, String childId) =>
      _childrenRef(uid).doc(childId);

  CollectionReference<Map<String, dynamic>> _questHistoryRef(
          String uid, String childId) =>
      _childRef(uid, childId).collection('questHistory');

  DocumentReference<Map<String, dynamic>> _learningRef(
          String uid, String childId) =>
      _childRef(uid, childId).collection('stats').doc('learning');

  DocumentReference<Map<String, dynamic>> _achievementsRef(
          String uid, String childId) =>
      _childRef(uid, childId).collection('stats').doc('achievements');

  DocumentReference<Map<String, dynamic>> _preferencesRef(String uid) =>
      _db.collection('users').doc(uid).collection('prefs').doc('preferences');

  CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _db.collection('stories');

  // ══════════════════════════════════════════════════════════════════════
  // Children
  // ══════════════════════════════════════════════════════════════════════

  /// 子どもプロフィール一覧をリアルタイムで監視するストリーム。
  Stream<List<ChildProfile>> childrenStream(String uid) {
    return _childrenRef(uid).orderBy('createdAt').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return ChildProfile.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// 単一の子どもプロフィールを取得する。存在しない場合は null を返す。
  Future<ChildProfile?> getChild(String uid, String childId) async {
    try {
      final doc = await _childRef(uid, childId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ChildProfile.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e, st) {
      debugPrint('[FirestoreService.getChild] error: $e\n$st');
      rethrow;
    }
  }

  /// 子どもプロフィールを新規作成し、生成されたドキュメント ID を返す。
  Future<String> createChild(
    String uid, {
    required String name,
    required int grade,
    required String avatarEmoji,
  }) async {
    try {
      final ref = _childrenRef(uid).doc(); // 自動 ID
      final now = FieldValue.serverTimestamp();
      await ref.set({
        'parentId': uid,
        'name': name,
        'grade': grade,
        'avatarEmoji': avatarEmoji,
        'level': 1,
        'totalPoints': 0,
        'kindnessScore': 50.0,
        'honestyScore': 50.0,
        'responsibilityScore': 50.0,
        'courageScore': 50.0,
        'respectScore': 50.0,
        'cooperationScore': 50.0,
        'createdAt': now,
        'updatedAt': now,
      });
      return ref.id;
    } catch (e, st) {
      debugPrint('[FirestoreService.createChild] error: $e\n$st');
      rethrow;
    }
  }

  /// API から取得した既存の [ChildProfile] を指定 ID で Firestore に保存する。
  /// すでに存在するドキュメントは上書きしない（merge: false を意図的に使用）。
  Future<void> createChildWithId(String uid, ChildProfile profile) async {
    try {
      final ref = _childRef(uid, profile.id);
      // ドキュメントが既に存在する場合は何もしない
      final snap = await ref.get();
      if (snap.exists) return;
      final now = FieldValue.serverTimestamp();
      await ref.set({
        'parentId': uid,
        'name': profile.name,
        'grade': profile.grade,
        'avatarEmoji': profile.avatarEmoji,
        'level': profile.level,
        'totalPoints': profile.totalPoints,
        'kindnessScore': profile.kindnessScore,
        'honestyScore': profile.honestyScore,
        'responsibilityScore': profile.responsibilityScore,
        'courageScore': profile.courageScore,
        'respectScore': profile.respectScore,
        'cooperationScore': profile.cooperationScore,
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e, st) {
      debugPrint('[FirestoreService.createChildWithId] error: $e\n$st');
      rethrow;
    }
  }

  /// 子どもプロフィールの指定フィールドを更新する。
  Future<void> updateChild(
    String uid,
    String childId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _childRef(uid, childId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('[FirestoreService.updateChild] error: $e\n$st');
      rethrow;
    }
  }

  /// 子どもプロフィールドキュメントを削除する。
  Future<void> deleteChild(String uid, String childId) async {
    try {
      await _childRef(uid, childId).delete();
    } catch (e, st) {
      debugPrint('[FirestoreService.deleteChild] error: $e\n$st');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Quest History (Progress)
  // ══════════════════════════════════════════════════════════════════════

  /// クエスト完了を記録する。
  /// - /questHistory への write
  /// - /learning の stats 更新
  /// を WriteBatch でアトミックに実行する。
  Future<void> recordQuestCompletion({
    required String uid,
    required String childId,
    required String storyId,
    required int pointsDelta,
    required String chosenVirtue,
    required int timeSpentSeconds,
  }) async {
    try {
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();

      // 1) questHistory ドキュメントを追加
      final questRef = _questHistoryRef(uid, childId).doc();
      batch.set(questRef, {
        'storyId': storyId,
        'action': 'story_completed',
        'pointsDelta': pointsDelta,
        'chosenVirtue': chosenVirtue,
        'timeSpentSeconds': timeSpentSeconds,
        'childId': childId,
        'recordedAt': now,
      });

      // 2) learning stats をインクリメント
      final learningRef = _learningRef(uid, childId);
      batch.set(
        learningRef,
        {
          'subjects': {
            _subject: {
              'totalTime': FieldValue.increment(timeSpentSeconds),
              'stagesCleared': FieldValue.increment(1),
              'correctAnswers': FieldValue.increment(1),
              'totalQuestions': FieldValue.increment(1),
              'lastAccessTime': now,
            },
          },
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      // 3) 子どもの totalPoints を更新
      batch.update(_childRef(uid, childId), {
        'totalPoints': FieldValue.increment(pointsDelta),
        'updatedAt': now,
      });

      await batch.commit();
    } catch (e, st) {
      debugPrint('[FirestoreService.recordQuestCompletion] error: $e\n$st');
      rethrow;
    }
  }

  /// クエスト履歴（Progress リスト）を取得する。
  Future<List<Progress>> getQuestHistory(
    String uid,
    String childId, {
    int limit = 100,
  }) async {
    try {
      final snap = await _questHistoryRef(uid, childId)
          .orderBy('recordedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return Progress.fromJson({
          'id': doc.id,
          'childId': data['childId'] as String? ?? childId,
          'storyId': data['storyId'],
          'action': data['action'] as String? ?? 'story_completed',
          'pointsDelta': (data['pointsDelta'] as num?)?.toInt() ?? 0,
          'recordedAt': _tsToIso(data['recordedAt']),
        });
      }).toList();
    } catch (e, st) {
      debugPrint('[FirestoreService.getQuestHistory] error: $e\n$st');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Learning Stats
  // ══════════════════════════════════════════════════════════════════════

  /// 学習統計ドキュメントを取得する。
  /// ドキュメントが存在しない場合はデフォルト値を返す。
  Future<Map<String, dynamic>> getLearningStats(
      String uid, String childId) async {
    try {
      final doc = await _learningRef(uid, childId).get();
      if (!doc.exists || doc.data() == null) {
        return _defaultLearningStats();
      }
      final data = doc.data()!;
      // subjects マップが欠損している場合のフォールバック
      if (data['subjects'] == null) {
        return _defaultLearningStats();
      }
      return data;
    } catch (e, st) {
      debugPrint('[FirestoreService.getLearningStats] error: $e\n$st');
      rethrow;
    }
  }

  /// 学習統計を更新する。merge で既存フィールドを保持する。
  Future<void> updateLearningStats(
    String uid,
    String childId, {
    required int addTimeSeconds,
    required bool storyCompleted,
    required int addPoints,
  }) async {
    try {
      await _learningRef(uid, childId).set(
        {
          'subjects': {
            _subject: {
              'totalTime': FieldValue.increment(addTimeSeconds),
              if (storyCompleted)
                'stagesCleared': FieldValue.increment(1),
              'lastAccessTime': FieldValue.serverTimestamp(),
            },
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('[FirestoreService.updateLearningStats] error: $e\n$st');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultLearningStats() => {
        'subjects': {
          _subject: {
            'totalTime': 0,
            'stagesCleared': 0,
            'currentStage': 1,
            'badges': <String>[],
            'correctAnswers': 0,
            'totalQuestions': 0,
            'correctRate': 0.0,
            'lastAccessTime': null,
          },
        },
      };

  // ══════════════════════════════════════════════════════════════════════
  // Achievements
  // ══════════════════════════════════════════════════════════════════════

  /// アチーブメントドキュメントを取得する。存在しない場合は空マップを返す。
  Future<Map<String, dynamic>> getAchievements(
      String uid, String childId) async {
    try {
      final doc = await _achievementsRef(uid, childId).get();
      if (!doc.exists || doc.data() == null) return {};
      return doc.data()!;
    } catch (e, st) {
      debugPrint('[FirestoreService.getAchievements] error: $e\n$st');
      rethrow;
    }
  }

  /// バッジを付与する。既存のバッジリストに追加（重複なし）。
  Future<void> awardBadge(String uid, String childId, String badgeId) async {
    try {
      await _achievementsRef(uid, childId).set(
        {
          'badges': FieldValue.arrayUnion([badgeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('[FirestoreService.awardBadge] error: $e\n$st');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Stories
  // ══════════════════════════════════════════════════════════════════════

  /// ストーリー一覧を取得する。theme / gradeLevel / isPremium でフィルタ可能。
  Future<List<Story>> getStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _storiesRef.orderBy('createdAt', descending: false);

      if (theme != null) {
        query = query.where('theme', isEqualTo: theme);
      }
      if (gradeLevel != null) {
        query = query.where('gradeLevel', isEqualTo: gradeLevel);
      }
      if (isPremium != null) {
        query = query.where('isPremium', isEqualTo: isPremium);
      }

      // offset エミュレーション: Firestore は skip をサポートしないので
      // startAfter を使う前提で、ここでは limit だけ適用
      query = query.limit(limit);

      final snap = await query.get();
      return snap.docs.map((doc) {
        return Story.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e, st) {
      debugPrint('[FirestoreService.getStories] error: $e\n$st');
      rethrow;
    }
  }

  /// 単一ストーリーを取得する。存在しない場合は null を返す。
  Future<Story?> getStory(String storyId) async {
    try {
      final doc = await _storiesRef.doc(storyId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Story.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e, st) {
      debugPrint('[FirestoreService.getStory] error: $e\n$st');
      rethrow;
    }
  }

  /// シードストーリーを投入する。コレクションが空の場合のみ書き込む。
  Future<void> seedStories(List<Story> stories) async {
    try {
      final existing = await _storiesRef.limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint(
            '[FirestoreService.seedStories] stories already seeded, skip.');
        return;
      }
      final batch = _db.batch();
      for (final story in stories) {
        final ref = _storiesRef.doc(story.id);
        final json = story.toJson();
        // DateTime を Firestore Timestamp に変換
        batch.set(ref, {
          ...json,
          'createdAt': story.createdAt,
          'updatedAt': story.updatedAt,
        });
      }
      await batch.commit();
      debugPrint(
          '[FirestoreService.seedStories] seeded ${stories.length} stories.');
    } catch (e, st) {
      debugPrint('[FirestoreService.seedStories] error: $e\n$st');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Preferences
  // ══════════════════════════════════════════════════════════════════════

  /// ユーザー設定を取得する。ドキュメントが存在しない場合はデフォルト値を返す。
  Future<Map<String, dynamic>> getPreferences(String uid) async {
    try {
      final doc = await _preferencesRef(uid).get();
      if (!doc.exists || doc.data() == null) {
        return _defaultPreferences();
      }
      return doc.data()!;
    } catch (e, st) {
      debugPrint('[FirestoreService.getPreferences] error: $e\n$st');
      rethrow;
    }
  }

  /// ユーザー設定を更新する（merge）。
  Future<void> updatePreferences(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _preferencesRef(uid).set(
        {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('[FirestoreService.updatePreferences] error: $e\n$st');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultPreferences() => {
        'notificationsEnabled': true,
        'soundEnabled': true,
        'ttsEnabled': false,
        'language': 'ja',
        'theme': 'light',
      };

  // ══════════════════════════════════════════════════════════════════════
  // Notification Preferences
  // ══════════════════════════════════════════════════════════════════════

  /// 親向け通知設定を取得する。ドキュメントが存在しない場合はデフォルト値を返す。
  Future<NotificationPreferences> getNotificationPreferences(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('prefs')
          .doc('notificationPreferences')
          .get();
      if (!doc.exists || doc.data() == null) {
        // デフォルト値を返す
        return NotificationPreferences(updatedAt: DateTime.now());
      }
      return NotificationPreferences.fromJson(doc.data()!);
    } catch (e, st) {
      debugPrint('[FirestoreService.getNotificationPreferences] error: $e\n$st');
      rethrow;
    }
  }

  /// 親向け通知設定を保存する。
  Future<void> saveNotificationPreferences(
    String uid,
    NotificationPreferences prefs,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('prefs')
          .doc('notificationPreferences')
          .set(
            {
              ...prefs.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e, st) {
      debugPrint('[FirestoreService.saveNotificationPreferences] error: $e\n$st');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // ユーティリティ
  // ══════════════════════════════════════════════════════════════════════

  /// Firestore Timestamp / String / null を ISO 8601 文字列に変換する。
  String _tsToIso(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return DateTime.now().toIso8601String();
  }
}
