import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API base URL — reads from .env, falls back to production URL.
String get apiBaseUrl =>
    dotenv.env['API_BASE_URL'] ?? 'https://api.shougaku-kore.jp';

const int apiTimeoutSeconds = 10;

// API v1 path prefix
const String apiV1 = '/api/v1';

// API endpoints
const String storiesEndpoint = '$apiV1/stories';
const String progressEndpoint = '$apiV1/progress';
const String reportsEndpoint = '$apiV1/reports';
const String authEndpoint = '$apiV1/auth';
const String childrenEndpoint = '$apiV1/children';
const String quizzesEndpoint = '$apiV1/quizzes';
const String usersEndpoint = '$apiV1/users';
