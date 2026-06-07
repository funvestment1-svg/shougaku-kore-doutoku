import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../models/child_profile.dart';
import '../models/story.dart';
import '../models/progress.dart';
import '../models/report.dart';
import '../config/api_config.dart';

/// Central HTTP client for the backend API.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: apiTimeoutSeconds),
        receiveTimeout: const Duration(seconds: apiTimeoutSeconds),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(LoggingInterceptor());
  }

  // ── Auth token ────────────────────────────────────────────────────────────

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final r = await _dio.post('$authEndpoint/register',
        data: {'email': email, 'password': password, 'name': name});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await _dio.post('$authEndpoint/login',
        data: {'email': email, 'password': password});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithFirebase(String idToken) async {
    final r = await _dio.post('$authEndpoint/firebase',
        data: {'idToken': idToken});
    return r.data as Map<String, dynamic>;
  }

  // ── Users ────────────────────────────────────────────────────────────────

  /// 自分のプロフィールを更新する (name / fcmToken)
  Future<Map<String, dynamic>> updateUser({
    String? name,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{
      // ignore: use_null_aware_elements
      if (name != null) 'name': name,
      // ignore: use_null_aware_elements
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
    final r = await _dio.put('$usersEndpoint/me', data: body);
    return r.data as Map<String, dynamic>;
  }

  // ── Children ──────────────────────────────────────────────────────────────

  Future<List<ChildProfile>> fetchChildrenProfiles() async {
    final r = await _dio.get(childrenEndpoint);
    final list = r.data as List<dynamic>;
    return list
        .map((j) => ChildProfile.fromApiJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ChildProfile> fetchChildProfile(String childId) async {
    final r = await _dio.get('$childrenEndpoint/$childId');
    return ChildProfile.fromApiJson(r.data as Map<String, dynamic>);
  }

  Future<ChildProfile> createChild({
    required String name,
    required int grade,
    required String avatarEmoji,
  }) async {
    final r = await _dio.post(childrenEndpoint,
        data: {'name': name, 'grade': grade, 'avatarEmoji': avatarEmoji});
    return ChildProfile.fromApiJson(r.data as Map<String, dynamic>);
  }

  Future<ChildProfile> updateChild(
      String childId, Map<String, dynamic> updates) async {
    final r = await _dio.put('$childrenEndpoint/$childId', data: updates);
    return ChildProfile.fromApiJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteChild(String childId) async {
    await _dio.delete('$childrenEndpoint/$childId');
  }

  // ── Stories ───────────────────────────────────────────────────────────────

  Future<List<Story>> fetchStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
    int offset = 0,
    int limit = 20,
  }) async {
    final r = await _dio.get(
      storiesEndpoint,
      queryParameters: {
        // ignore: use_null_aware_elements
        if (theme != null) 'theme': theme,
        // ignore: use_null_aware_elements
        if (gradeLevel != null) 'gradeLevel': gradeLevel,
        // ignore: use_null_aware_elements
        if (isPremium != null) 'isPremium': isPremium,
        'offset': offset,
        'limit': limit,
      },
    );
    final list = r.data as List<dynamic>;
    return list.map((j) => Story.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Story> fetchStoryDetail(String storyId) async {
    final r = await _dio.get('$storiesEndpoint/$storyId');
    return Story.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Story>> fetchWeeklyTheme(int weekNumber) async {
    final r = await _dio.get('$storiesEndpoint/weekly/$weekNumber');
    final list = r.data as List<dynamic>;
    return list.map((j) => Story.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Quizzes ───────────────────────────────────────────────────────────────

  /// Start a quiz session. Returns session data including sessionId.
  Future<Map<String, dynamic>> startQuizSession({
    required String childId,
    required String storyId,
  }) async {
    final r = await _dio.post(quizzesEndpoint,
        data: {'childId': childId, 'storyId': storyId});
    return r.data as Map<String, dynamic>;
  }

  /// Complete a quiz session with the chosen choice.
  Future<Map<String, dynamic>> completeQuizSession({
    required String sessionId,
    required String chosenChoiceId,
    required int timeSpentSeconds,
    String? reflectionText,
  }) async {
    final r = await _dio.post(
      '$quizzesEndpoint/$sessionId/complete',
      data: {
        'chosenChoiceId': chosenChoiceId,
        'timeSpentSeconds': timeSpentSeconds,
        // ignore: use_null_aware_elements
        if (reflectionText != null) 'reflectionText': reflectionText,
      },
    );
    return r.data as Map<String, dynamic>;
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  Future<List<Progress>> fetchProgress(String childId, {int limit = 100}) async {
    final r = await _dio.get(
      '$progressEndpoint/$childId',
      queryParameters: {'limit': limit},
    );
    final list = r.data as List<dynamic>;
    return list
        .map((j) => Progress.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProgress(Progress progress) async {
    await _dio.post(progressEndpoint, data: progress.toJson());
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<MonthlyReport?> fetchMonthlyReport({
    required String childId,
    required int year,
    required int month,
  }) async {
    try {
      final r = await _dio.get(
        '$reportsEndpoint/$childId/monthly',
        queryParameters: {'year': year, 'month': month},
      );
      if (r.data == null) return null;
      return MonthlyReport.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<MonthlyReport> generateMonthlyReport({
    required String childId,
    required int year,
    required int month,
  }) async {
    final r = await _dio.post(
      '$reportsEndpoint/$childId/monthly/generate',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthlyReport.fromJson(r.data as Map<String, dynamic>);
  }
}

// ── Logging interceptor ────────────────────────────────────────────────────

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('→ ${options.method} ${options.uri}', name: 'API');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log('← ${response.statusCode} ${response.requestOptions.path}', name: 'API');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.response?.statusCode ?? "?"} ${err.requestOptions.path}: ${err.message}',
      name: 'API',
      error: err,
    );
    handler.next(err);
  }
}
