import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_preferences.dart';
import '../../models/story.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart'; // currentChildIdProvider, selectedChildProvider, childrenProfilesProvider
import '../../providers/story_provider_fs.dart'; // Firestore 版ストーリープロバイダー
import '../../providers/firestore_provider.dart';
import '../../providers/notification_preferences_provider.dart';
import '../../data/seed_stories.dart';
import '../settings/settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../story/story_learning_screen.dart';
import '../growth/growth_screen.dart';
import '../report/report_screen.dart';
import '../library/library_screen.dart';

const _primaryColor = Color(0xFF9B59B6);
const _primaryDark = Color(0xFF8E44AD);
const _backgroundColor = Color(0xFFF5F5F5);
const _cardBackground = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _childInitDone = false;

  @override
  void initState() {
    super.initState();
    // 子どもが未選択の場合にバックエンドから読み込んでセットする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChildIfNeeded();
      _seedFirestoreStories();
    });
  }

  /// Firestore のストーリーコレクションが空の場合にシードデータを投入する。
  /// Firebase 未初期化やオフライン時はエラーを無視して続行する。
  Future<void> _seedFirestoreStories() async {
    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return; // 未ログインはスキップ
      await ref.read(firestoreServiceProvider).seedStories(buildSeedStories());
    } catch (_) {
      // Firebase 未初期化、オフライン、権限エラー等は無視
    }
  }

  Future<void> _initChildIfNeeded() async {
    if (!mounted) return;

    // すでに子どもが選択されていれば何もしない
    if (ref.read(currentChildIdProvider) != null) {
      setState(() => _childInitDone = true);
      return;
    }

    try {
      final children = await ref.read(childrenProfilesProvider.future);
      if (!mounted) return;
      if (children.isNotEmpty) {
        ref.read(currentChildIdProvider.notifier).state = children.first.id;
      } else {
        // 子どもが1人もいない → 登録画面へ
        Navigator.of(context).pushReplacementNamed('/child-registration');
        return;
      }
    } catch (_) {
      // API 失敗（オフライン等）→ ゲストモードで継続
    }

    if (mounted) setState(() => _childInitDone = true);
  }

  @override
  Widget build(BuildContext context) {
    // 子ども初期化が完了するまでスピナーを表示
    if (!_childInitDone) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(onNavigate: (i) => setState(() => _selectedIndex = i)),
          const LibraryScreen(),
          const GrowthScreen(),
          const ReportScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: '学習'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '成長'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'レポート'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondary,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ─── Home Tab (自分のウィジェットに分離してConsumerWidget化) ───────────────────

class _HomeTab extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);
    final storiesAsync = ref.watch(
      storiesFsProvider((theme: null, gradeLevel: null, isPremium: false)),
    );

    return childAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: Text('エラー: $e')),
      ),
      data: (child) => _buildContent(context, ref, child, storiesAsync),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic child,
    AsyncValue<List<Story>> storiesAsync,
  ) {
    final level = child?.level ?? 1;
    final totalPoints = child?.totalPoints ?? 0;
    final levelProgress = (totalPoints % 100) / 100.0;
    final nextLevelPoints = (level * 100) - totalPoints;
    final childName = child?.name ?? 'ゲスト';

    // 今週のテーマストーリーを1本推薦
    final recommendedStory = storiesAsync.asData?.value.isNotEmpty == true
        ? storiesAsync.asData!.value.first
        : null;

    return CustomScrollView(
      slivers: [
        // ─── ヘッダー ───
        SliverAppBar(
          pinned: false,
          elevation: 0,
          backgroundColor: _primaryColor,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor, _primaryDark],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$childNameの道徳',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(200),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '心のレッスン',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'レベル $level',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      Text(
                        '$totalPoints ポイント (次まで $nextLevelPoints)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withAlpha(77),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ─── コンテンツ ───
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // メール配信予定バナー
                _buildEmailSchedulingBanner(context, ref),
                const SizedBox(height: 16),

                // 推薦ストーリーカード
                if (recommendedStory != null) ...[
                  _RecommendedCard(
                    story: recommendedStory,
                    childId: child?.id ?? '',
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  _DailyMissionCard(
                    onTap: () => onNavigate(1),
                  ),
                  const SizedBox(height: 24),
                ],

                // ストーリー一覧へ誘導
                const Text(
                  'おすすめのストーリー',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                storiesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (stories) => stories.isEmpty
                      ? _buildNoStoriesCard(context)
                      : _StoryPreviewList(
                          stories: stories.take(3).toList(),
                          childId: child?.id ?? '',
                        ),
                ),
                const SizedBox(height: 20),

                // 全ストーリーへのCTA
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(Icons.library_books),
                    label: const Text('すべてのストーリーを見る'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: const BorderSide(color: _primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSchedulingBanner(BuildContext context, WidgetRef ref) {
    // 現在のユーザーIDを取得
    final authState = ref.read(userAuthStateProvider);
    final userId = authState.valueOrNull?.uid;

    // ゲスト環境ではバナーを表示しない
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final prefsAsync = ref.watch(notificationPreferencesProvider(userId));

    return prefsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (prefs) {
        // メール配信が無効な場合はバナーを表示しない
        if (!prefs.emailNotificationsEnabled) {
          return const SizedBox.shrink();
        }

        // 次のメール配信予定日時を計算
        final nextSendTime = _calculateNextEmailSendTime(prefs);
        final now = DateTime.now();
        final daysUntil = nextSendTime.difference(now).inDays;
        final hoursUntil = nextSendTime.difference(now).inHours;

        // 時刻表示
        final dateStr = nextSendTime.toString().split(' ')[0];

        return Container(
          decoration: BoxDecoration(
            color: _primaryColor.withAlpha(26),
            border: Border.all(color: _primaryColor.withAlpha(77)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.mail_outline, color: _primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📧 メール配信予定',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      daysUntil == 0 && hoursUntil > 0
                          ? '本日 ${nextSendTime.hour.toString().padLeft(2, '0')}:${nextSendTime.minute.toString().padLeft(2, '0')} に配信予定'
                          : '${daysUntil}日後（$dateStr）に配信予定',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
                child: const Text(
                  '設定',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 次のメール配信予定日時を計算する
  DateTime _calculateNextEmailSendTime(NotificationPreferences prefs) {
    final now = DateTime.now();
    final timeParts = prefs.emailTime.split(':');
    final targetHour = int.parse(timeParts[0]);
    final targetMinute = int.parse(timeParts[1]);

    DateTime nextSend;

    switch (prefs.emailFrequency) {
      case 'weekly':
        // 毎週日曜日（0=日）
        final daysUntilSunday = (7 - now.weekday) % 7;
        nextSend = now.add(Duration(days: daysUntilSunday));
        break;
      case 'biweekly':
        // 2週間ごと（初回は最初の日曜）
        final daysUntilSunday = (7 - now.weekday) % 7;
        nextSend = now.add(Duration(days: daysUntilSunday));
        break;
      case 'monthly':
        // 月1回（初回は翌月1日）
        nextSend =
            DateTime(now.year, now.month + 1, 1);
        break;
      case 'custom':
        // カスタム曜日（最初の該当曜日）
        if (prefs.customEmailDays.isEmpty) {
          return now.add(const Duration(days: 7)); // デフォルト
        }
        final sortedDays = List<int>.from(prefs.customEmailDays)..sort();
        var daysToAdd = 0;
        for (final day in sortedDays) {
          if (day > now.weekday) {
            daysToAdd = day - now.weekday;
            break;
          }
        }
        if (daysToAdd == 0) {
          daysToAdd = (7 - now.weekday) + sortedDays.first;
        }
        nextSend = now.add(Duration(days: daysToAdd));
        break;
      default:
        nextSend = now.add(const Duration(days: 7));
    }

    // 時刻を設定
    nextSend = DateTime(
      nextSend.year,
      nextSend.month,
      nextSend.day,
      targetHour,
      targetMinute,
    );

    // もし現在時刻がすでに過ぎていれば翌週に移動（週単位の場合）
    if (nextSend.isBefore(now) && prefs.emailFrequency != 'custom') {
      nextSend = nextSend.add(const Duration(days: 7));
    }

    return nextSend;
  }

  Widget _buildNoStoriesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Text('📖', style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'ストーリーを読み込んでいます...',
              style: TextStyle(color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 推薦ストーリーカード ───────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  final Story story;
  final String childId;

  static const _themeEmojis = <String, String>{
    'kindness': '💜',
    'honesty': '⭐',
    'responsibility': '💪',
    'courage': '🔥',
    'respect': '🌿',
    'cooperation': '🤝',
  };

  const _RecommendedCard({required this.story, required this.childId});

  @override
  Widget build(BuildContext context) {
    final emoji = _themeEmojis[story.theme] ?? '📖';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: childId.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryLearningScreen(
                        storyId: story.id,
                        childId: childId,
                      ),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日のおすすめ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${story.durationSeconds ~/ 60}分 · ${story.theme}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(emoji, style: const TextStyle(fontSize: 44)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── デイリーミッション (ストーリーなし時フォールバック) ──────────────────

class _DailyMissionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyMissionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日のテーマ',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ストーリーを探す',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text('📚', style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ストーリープレビューリスト ────────────────────────────────────────────

class _StoryPreviewList extends StatelessWidget {
  final List<Story> stories;
  final String childId;

  const _StoryPreviewList({required this.stories, required this.childId});

  static const _themeColors = <String, Color>{
    'kindness': Color(0xFF9B59B6),
    'honesty': Color(0xFFF1C40F),
    'responsibility': Color(0xFF3498DB),
    'courage': Color(0xFFE74C3C),
    'respect': Color(0xFF27AE60),
    'cooperation': Color(0xFFE67E22),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stories
          .map((s) => _buildStoryItem(context, s))
          .toList(),
    );
  }

  Widget _buildStoryItem(BuildContext context, Story story) {
    final color = _themeColors[story.theme] ?? _primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: childId.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryLearningScreen(
                        storyId: story.id,
                        childId: childId,
                      ),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.durationSeconds ~/ 60}分',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
