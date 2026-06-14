import 'package:dio/dio.dart';
import '../models/distribution_response.dart';
import '../models/revisit_schedule.dart';
import '../models/parent_child_comparison.dart';
import '../models/kindness_mission.dart';
import '../models/ai_features.dart';

class ApiService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.shougaku-kore.jp/api/v1';

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Future<DistributionResponse> getDistribution(String storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/distribution');
      return DistributionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch distribution: ${e.message}');
    }
  }

  Future<List<RevisitStory>> getRevisitStories(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/revisit-stories');
      final List<dynamic> data = response.data['revisits'] ?? [];
      return data.map((item) => RevisitStory.fromJson(item)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch revisit stories: ${e.message}');
    }
  }

  Future<RevisitResult> answerRevisitStory(
    String revisitId,
    String answerChoice,
  ) async {
    try {
      final response = await _dio.post(
        '/revisit-stories/$revisitId/answer',
        data: {'answer_choice': answerChoice},
      );
      return RevisitResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to answer revisit story: ${e.message}');
    }
  }

  Future<ParentAnswerResponse> answerParentChildStory(
    String parentId,
    String childId,
    String storyId,
    String answerChoice,
  ) async {
    try {
      final response = await _dio.post(
        '/parent-child/$parentId/$childId/answer',
        data: {
          'story_id': storyId,
          'answer_choice': answerChoice,
        },
      );
      return ParentAnswerResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to answer parent-child story: ${e.message}');
    }
  }

  Future<List<ParentChildComparison>> getParentChildDialogueHistory(
    String parentId,
    String childId,
  ) async {
    try {
      final response = await _dio.get(
        '/parent-child/$parentId/$childId/dialogue-history',
      );
      final List<dynamic> data = response.data['histories'] ?? [];
      return data.map((item) => ParentChildComparison.fromJson(item)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch dialogue history: ${e.message}');
    }
  }

  Future<ParentChildComparison?> getLatestParentChildComparison(
    String parentId,
    String childId,
  ) async {
    try {
      final histories = await getParentChildDialogueHistory(parentId, childId);
      return histories.isNotEmpty ? histories.first : null;
    } on DioException catch (e) {
      throw Exception('Failed to fetch latest comparison: ${e.message}');
    }
  }

  Future<KindnessMission> getCurrentMission(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/kindness/mission');
      return KindnessMission.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch mission: ${e.message}');
    }
  }

  Future<KindnessRecordResponse> recordKindness(
    String userId,
    String description,
    String? person,
    String? context,
  ) async {
    try {
      final response = await _dio.post(
        '/users/$userId/kindness-records',
        data: {
          'kindness_description': description,
          'person_involved': person,
          'context': context,
        },
      );
      return KindnessRecordResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to record kindness: ${e.message}');
    }
  }

  Future<KindnessMap> getKindnessMap(String userId, String month) async {
    try {
      final response = await _dio.get(
        '/users/$userId/kindness-map/$month',
      );
      return KindnessMap.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch kindness map: ${e.message}');
    }
  }

  // ③ りゆう記録分析（月50人抽出版）
  Future<ReasonAnalysis?> getReasonAnalysis(String userId, String month) async {
    try {
      final response = await _dio.get(
        '/users/$userId/reason-analysis/$month',
      );
      if (response.statusCode == 204) return null;
      return ReasonAnalysis.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to fetch reason analysis: ${e.message}');
    }
  }

  // ⑤ 創作フィード — 記録
  Future<void> submitCreation(
    String userId,
    String storyId,
    String storyTitle,
    String userCreatedEnding,
  ) async {
    try {
      await _dio.post(
        '/users/$userId/creations',
        data: {
          'story_id': storyId,
          'story_title': storyTitle,
          'user_created_ending': userCreatedEnding,
        },
      );
    } on DioException catch (e) {
      throw Exception('Failed to submit creation: ${e.message}');
    }
  }

  // ⑤ 創作フィード — 月次フィードバック取得
  Future<CreationFeedback?> getCreationFeedback(
    String userId,
    String month,
  ) async {
    try {
      final response = await _dio.get(
        '/users/$userId/creation-feedback/$month',
      );
      if (response.statusCode == 204) return null;
      return CreationFeedback.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to fetch creation feedback: ${e.message}');
    }
  }
}
