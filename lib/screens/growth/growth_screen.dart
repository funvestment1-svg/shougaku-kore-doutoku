import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/child_profile.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFF5F5F5);
const _cardColor = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (child) => child == null
            ? const _NoChildView()
            : _GrowthContent(child: child),
      ),
    );
  }
}

class _NoChildView extends StatelessWidget {
  const _NoChildView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👶', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text('子供プロフィールを作成してください', style: TextStyle(color: _textSecondary)),
        ],
      ),
    );
  }
}

class _GrowthContent extends ConsumerWidget {
  final ChildProfile child;
  const _GrowthContent({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ヘッダー
        SliverAppBar(
          pinned: true,
          backgroundColor: _primaryColor,
          title: Text(
            '${child.name}の成長',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                child.avatarEmoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // レベル・ポイントカード
                _LevelCard(child: child),
                const SizedBox(height: 16),

                // 徳目レーダーチャート
                _VirtueRadarCard(child: child),
                const SizedBox(height: 16),

                // 徳目詳細リスト
                _VirtueDetailList(child: child),
                const SizedBox(height: 16),

                // 週間活動グラフ
                _WeeklyActivityCard(childId: child.id),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ChildProfile child;
  const _LevelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final nextLevelPoints = child.level * 100;
    final currentLevelPoints = child.totalPoints % 100;
    final progress = currentLevelPoints / 100;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _primaryColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('現在のレベル', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    'レベル ${child.level}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('累計ポイント', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${child.totalPoints}pt',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '次のレベルまで: ${nextLevelPoints - currentLevelPoints}pt',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(60),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtueRadarCard extends StatelessWidget {
  final ChildProfile child;
  const _VirtueRadarCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌈 徳目レーダーチャート',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: _primaryColor.withAlpha(50),
                    borderColor: _primaryColor,
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries: [
                      RadarEntry(value: child.kindnessScore),
                      RadarEntry(value: child.honestyScore),
                      RadarEntry(value: child.responsibilityScore),
                      RadarEntry(value: child.courageScore),
                      RadarEntry(value: child.respectScore),
                      RadarEntry(value: child.cooperationScore),
                    ],
                  ),
                ],
                // radarMaxValue removed (not in fl_chart 0.68.0)
                tickCount: 5,
                ticksTextStyle: const TextStyle(fontSize: 8, color: _textSecondary),
                gridBorderData: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                titleTextStyle: const TextStyle(fontSize: 11, color: _textPrimary, fontWeight: FontWeight.w600),
                getTitle: (index, angle) {
                  const titles = ['思いやり', '正直さ', '責任感', '勇気', '礼儀', '協調性'];
                  return RadarChartTitle(text: titles[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtueDetailList extends StatelessWidget {
  final ChildProfile child;
  const _VirtueDetailList({required this.child});

  @override
  Widget build(BuildContext context) {
    final virtues = [
      _VirtueData('思いやり', '💜', child.kindnessScore),
      _VirtueData('正直さ', '💛', child.honestyScore),
      _VirtueData('責任感', '💙', child.responsibilityScore),
      _VirtueData('勇気', '❤️', child.courageScore),
      _VirtueData('礼儀', '💚', child.respectScore),
      _VirtueData('協調性', '🧡', child.cooperationScore),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 徳目スコア詳細',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 12),
          ...virtues.map((v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(v.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: Text(v.name, style: const TextStyle(fontSize: 13, color: _textPrimary)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: v.score / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation(_getBarColor(v.score)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${v.score.toInt()}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textPrimary),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getBarColor(double score) {
    if (score >= 80) return const Color(0xFF27AE60);
    if (score >= 60) return const Color(0xFF2ECC71);
    if (score >= 40) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }
}

class _WeeklyActivityCard extends ConsumerWidget {
  final String childId;
  const _WeeklyActivityCard({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(weeklyActivityProvider(childId));
    final weeklyData = activityAsync.maybeWhen(
      data: (data) => data,
      orElse: () => List<int>.filled(7, 0),
    );
    final days = ['月', '火', '水', '木', '金', '土', '日'];

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 今週の学習状況',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 6,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        return Text(days[idx], style: const TextStyle(fontSize: 11, color: _textSecondary));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weeklyData[i].toDouble(),
                      color: _primaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '今週の合計: ${weeklyData.reduce((a, b) => a + b)} ストーリー',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtueData {
  final String name;
  final String emoji;
  final double score;
  const _VirtueData(this.name, this.emoji, this.score);
}
