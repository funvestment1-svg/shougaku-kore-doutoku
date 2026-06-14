"""
Cloud Scheduler バッチジョブ
- ③ 毎月1日: りゆう記録分析（50人抽出 + Gemini）
- ⑤ 毎月末日: 創作フィード月次フィードバック生成
"""
from fastapi import APIRouter
from datetime import datetime
from ..services.ai_optimizer import (
    sample_users_for_analysis,
    compress_kindness_texts,
    analyze_with_gemini,
    build_reason_analysis_from_ai,
)

router = APIRouter(prefix="/jobs", tags=["batch-jobs"])


@router.post("/monthly-reason-analysis")
async def monthly_reason_analysis():
    """
    ③ 毎月1日実行: 前月のやさしさ記録を分析

    コスト: 月50人 × $0.0003/回 = $0.015 (¥2)
    """
    month = _get_last_month()

    # TODO: Firestore から前月にやさしさ記録があった全ユーザーIDを取得
    all_user_ids = _get_users_with_kindness_records(month)

    # 10%ランダム抽出（最大50人）
    sampled_ids = sample_users_for_analysis(all_user_ids, rate=0.1)

    results = []
    for user_id in sampled_ids:
        # TODO: Firestore からユーザーのやさしさ記録を取得
        records = _get_kindness_records(user_id, month)

        # テキスト圧縮（80%削減）
        compressed = compress_kindness_texts(records)

        # Gemini 分析（キャッシング有効）
        ai_result = await analyze_with_gemini(user_id, compressed)

        # 分析結果 + テンプレートで親向けフィードバック構築
        feedback = build_reason_analysis_from_ai(user_id, month, ai_result)

        # TODO: Firestore に保存
        _save_reason_analysis(user_id, month, feedback)

        results.append({"user_id": user_id, "status": "analyzed"})

    return {
        "month": month,
        "total_users": len(all_user_ids),
        "sampled_users": len(sampled_ids),
        "results": results,
    }


@router.post("/monthly-creation-feedback")
async def monthly_creation_feedback():
    """
    ⑤ 毎月末日実行: 当月の創作記録をバッチ分析

    コスト: 全ユーザー × $0.0001/回 = $0.05 (¥7)
    リアルタイムではなく月末1回のバッチで97%削減
    """
    month = _get_current_month()

    # TODO: 当月に創作記録があった全ユーザーIDを Firestore から取得
    all_user_ids = _get_users_with_creations(month)

    results = []
    for user_id in all_user_ids:
        # TODO: Firestore からユーザーの創作記録を取得
        creations = _get_creation_records(user_id, month)
        if not creations:
            continue

        # 創作テキストを圧縮（先頭50文字×5件）
        summaries = [
            f"{c.get('story_title', '')}: {c.get('user_created_ending', '')[:50]}..."
            for c in creations[:5]
        ]

        # Gemini 分析
        ai_result = await _analyze_creation_growth(user_id, summaries, len(creations))

        # TODO: Firestore に保存
        _save_creation_feedback(user_id, month, ai_result)

        results.append({"user_id": user_id, "creations": len(creations)})

    return {
        "month": month,
        "processed_users": len(results),
        "results": results,
    }


async def _analyze_creation_growth(
    user_id: str,
    summaries: list,
    count: int,
) -> dict:
    """創作の成長を Gemini で分析"""
    # TODO: 実際には Vertex AI Gemini 1.5 Flash を使用
    level_map = {
        1: "none",
        2: "none",
        3: "slight",
        4: "slight",
        5: "clear",
    }
    level = level_map.get(min(count, 5), "clear")

    return {
        "user_id": user_id,
        "creation_count": count,
        "headline": f"今月は {count}つの 創作に チャレンジしました",
        "observations": [
            "ストーリーの結末に 自分の気持ちを 反映させています",
            "登場人物への 共感が 感じられます",
        ],
        "parent_tip": (
            "お子さんに「この月の 創作について 聞かせてほしい」と "
            "話しかけてみてください。"
        ),
    }


# --- Firestore スタブ（TODO: 本番では実装） ---

def _get_last_month() -> str:
    from datetime import datetime, timedelta
    first_of_month = datetime.now().replace(day=1)
    last_month = first_of_month - timedelta(days=1)
    return last_month.strftime("%Y-%m")


def _get_current_month() -> str:
    return datetime.now().strftime("%Y-%m")


def _get_users_with_kindness_records(month: str):
    return ["user_001", "user_002"]  # TODO: Firestoreから取得


def _get_kindness_records(user_id: str, month: str):
    return [  # TODO: Firestoreから取得
        {"description": "先生が丁寧に教えてくれた", "person_involved": "先生"},
        {"description": "友達がノートを貸してくれた", "person_involved": "友達"},
    ]


def _save_reason_analysis(user_id: str, month: str, feedback: dict):
    pass  # TODO: Firestoreに保存


def _get_users_with_creations(month: str):
    return ["user_001"]  # TODO: Firestoreから取得


def _get_creation_records(user_id: str, month: str):
    return []  # TODO: Firestoreから取得


def _save_creation_feedback(user_id: str, month: str, feedback: dict):
    pass  # TODO: Firestoreに保存
