import 'dart:developer' as developer;
import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics ラッパー
/// 全てのイベントをここで集中管理
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ============ 認証イベント ============

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    _log('login', {'method': method});
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    _log('sign_up', {'method': method});
  }

  // ============ ストーリーイベント ============

  Future<void> logStoryStarted({
    required String storyId,
    required String storyTitle,
    required String theme,
  }) async {
    await _analytics.logEvent(
      name: 'story_started',
      parameters: {
        'story_id': storyId,
        'story_title': storyTitle,
        'theme': theme,
      },
    );
    _log('story_started', {'story_id': storyId, 'theme': theme});
  }

  Future<void> logStoryCompleted({
    required String storyId,
    required String theme,
    required int pointsEarned,
    required int timeSpentSeconds,
    required String chosenVirtue,
  }) async {
    await _analytics.logEvent(
      name: 'story_completed',
      parameters: {
        'story_id': storyId,
        'theme': theme,
        'points_earned': pointsEarned,
        'time_spent_seconds': timeSpentSeconds,
        'chosen_virtue': chosenVirtue,
      },
    );
    _log('story_completed', {
      'story_id': storyId,
      'points_earned': pointsEarned,
    });
  }

  Future<void> logChoiceMade({
    required String storyId,
    required int choiceOrder,
    required bool isRecommended,
  }) async {
    await _analytics.logEvent(
      name: 'choice_made',
      parameters: {
        'story_id': storyId,
        'choice_order': choiceOrder,
        'is_recommended': isRecommended ? 1 : 0,
      },
    );
  }

  // ============ レポートイベント ============

  Future<void> logReportViewed({
    required String childId,
    required int year,
    required int month,
  }) async {
    await _analytics.logEvent(
      name: 'report_viewed',
      parameters: {
        'child_id': childId,
        'year': year,
        'month': month,
      },
    );
  }

  Future<void> logReportGenerated({
    required String childId,
    required int storiesCompleted,
  }) async {
    await _analytics.logEvent(
      name: 'report_generated',
      parameters: {
        'child_id': childId,
        'stories_completed': storiesCompleted,
      },
    );
  }

  // ============ 子供プロフィールイベント ============

  Future<void> logChildProfileCreated({required int grade}) async {
    await _analytics.logEvent(
      name: 'child_profile_created',
      parameters: {'grade': grade},
    );
  }

  // ============ スクリーンビュー ============

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // ============ ユーティリティ ============

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  void _log(String event, Map<String, dynamic> params) {
    developer.log(
      'Analytics: $event $params',
      name: 'AnalyticsService',
    );
  }

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
}
