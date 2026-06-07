import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/child_registration_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'providers/locale_provider.dart';
import 'providers/offline_sync_provider.dart';

/// グローバル Navigator キー — プッシュ通知タップ時のナビゲーションに使用
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeApp() async {
  // 環境変数ロード: デバッグ時は .env.local を優先、なければ .env にフォールバック
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env.local');
    } catch (_) {
      await dotenv.load(fileName: '.env');
    }
  } else {
    await dotenv.load(fileName: '.env');
  }

  // Firebase初期化 — google-services.json が未配置の環境でもクラッシュしない
  try {
    await Firebase.initializeApp();
    // バックグラウンドメッセージハンドラー登録 (Firebase初期化後に呼ぶ)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init failed (continuing without Firebase): $e');
  }

  // Hive (ローカルキャッシュ) 初期化
  final hiveService = HiveService();
  await hiveService.initialize();

  // プッシュ通知サービス初期化
  await NotificationService().initialize();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// アプリがフォアグラウンドに戻ったときに保留中の同期を実行する
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(offlineSyncProvider.notifier).syncPendingItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: '小学コレ！道徳',
      navigatorKey: navigatorKey,
      locale: locale,
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/child-registration': (context) => const ChildRegistrationScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }
}
