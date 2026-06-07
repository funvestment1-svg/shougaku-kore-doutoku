import 'package:cloud_firestore/cloud_firestore.dart';

// ──────────────────────────────────────────────────────────────────────────────
// BadgeDefinition — アプリ内に静的に定義するバッジのマスタデータ
// ──────────────────────────────────────────────────────────────────────────────

/// バッジのマスタ定義。アプリバンドル内に保持し、Firestore には保存しない。
class BadgeDefinition {
  final String id;
  final String name;
  final String emoji;
  final String description;

  /// 対象の徳目テーマ ("kindness", "honesty", "courage", "respect", "all" など)
  final String theme;

  /// このバッジを獲得するために必要なストーリー完了数
  final int requiredCompletions;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.theme,
    required this.requiredCompletions,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// EarnedBadge — Firestore に保存する「取得済みバッジ」レコード
// ──────────────────────────────────────────────────────────────────────────────

/// 子どもが獲得したバッジの記録。
/// Firestore の achievements ドキュメント内の badges 配列に格納する。
class EarnedBadge {
  final String badgeId;
  final DateTime earnedAt;

  const EarnedBadge({
    required this.badgeId,
    required this.earnedAt,
  });

  factory EarnedBadge.fromJson(Map<String, dynamic> json) {
    final rawEarnedAt = json['earnedAt'];
    final DateTime earnedAt;
    if (rawEarnedAt is Timestamp) {
      earnedAt = rawEarnedAt.toDate();
    } else if (rawEarnedAt is String) {
      earnedAt = DateTime.tryParse(rawEarnedAt) ?? DateTime.now();
    } else {
      earnedAt = DateTime.now();
    }

    return EarnedBadge(
      badgeId: json['badgeId'] as String? ?? '',
      earnedAt: earnedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'badgeId': badgeId,
        'earnedAt': earnedAt.toIso8601String(),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// 道徳バッジ定義リスト
// ──────────────────────────────────────────────────────────────────────────────

/// 道徳アプリで使用するすべてのバッジ定義。
const List<BadgeDefinition> kDoutokuBadges = [
  // ── 思いやり ────────────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'kindness_1',
    name: 'やさしい心',
    emoji: '💖',
    description: '思いやりのストーリーを1本完了',
    theme: 'kindness',
    requiredCompletions: 1,
  ),
  BadgeDefinition(
    id: 'kindness_3',
    name: 'やさしさの達人',
    emoji: '💝',
    description: '思いやりのストーリーを3本完了',
    theme: 'kindness',
    requiredCompletions: 3,
  ),
  // ── 正直さ ──────────────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'honesty_1',
    name: '正直な心',
    emoji: '✨',
    description: '正直さのストーリーを1本完了',
    theme: 'honesty',
    requiredCompletions: 1,
  ),
  BadgeDefinition(
    id: 'honesty_3',
    name: '正直の達人',
    emoji: '🌟',
    description: '正直さのストーリーを3本完了',
    theme: 'honesty',
    requiredCompletions: 3,
  ),
  // ── 勇気 ────────────────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'courage_1',
    name: '勇気ある心',
    emoji: '🦁',
    description: '勇気のストーリーを1本完了',
    theme: 'courage',
    requiredCompletions: 1,
  ),
  BadgeDefinition(
    id: 'courage_3',
    name: '勇気の達人',
    emoji: '⚡',
    description: '勇気のストーリーを3本完了',
    theme: 'courage',
    requiredCompletions: 3,
  ),
  // ── 礼儀 ────────────────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'respect_1',
    name: '礼儀正しい心',
    emoji: '🙏',
    description: '礼儀のストーリーを1本完了',
    theme: 'respect',
    requiredCompletions: 1,
  ),
  // ── 全テーマ共通 ────────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'first_story',
    name: 'はじめの一歩',
    emoji: '🎯',
    description: '最初のストーリーを完了',
    theme: 'all',
    requiredCompletions: 1,
  ),
  BadgeDefinition(
    id: 'story_5',
    name: '5本クリア',
    emoji: '🌈',
    description: '5本のストーリーを完了',
    theme: 'all',
    requiredCompletions: 5,
  ),
  BadgeDefinition(
    id: 'story_10',
    name: '10本クリア',
    emoji: '🏆',
    description: '10本のストーリーを完了',
    theme: 'all',
    requiredCompletions: 10,
  ),
];

/// バッジ ID からマスタ定義を検索するヘルパー。見つからない場合は null を返す。
BadgeDefinition? findBadge(String badgeId) {
  try {
    return kDoutokuBadges.firstWhere((b) => b.id == badgeId);
  } catch (_) {
    return null;
  }
}
