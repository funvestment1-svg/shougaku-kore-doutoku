from fastapi import APIRouter, HTTPException
from datetime import datetime
from ..models.ai_features import ReasonAnalysis, CreationFeedback

router = APIRouter(prefix="/users", tags=["ai-features"])


@router.get("/{user_id}/reason-analysis/{month}", response_model=ReasonAnalysis)
async def get_reason_analysis(user_id: str, month: str):
    """
    ③ 月次りゆう記録分析を取得

    抽出対象外のユーザーは 404 を返す（フロントでテンプレートに切替）
    TODO: Firestore から reason_analyses を取得
    """
    try:
        # TODO: Firestore から取得
        # 抽出対象外は None → 404 を返す
        analysis = None  # 実際はDBから検索

        if analysis is None:
            raise HTTPException(status_code=404, detail="Analysis not found")

        return analysis
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/creations")
async def submit_creation(
    user_id: str,
    story_id: str,
    story_title: str,
    user_created_ending: str,
):
    """
    ⑤ 創作を記録（AI処理は月末バッチで行う）
    TODO: Firestore の creations コレクションに保存
    """
    try:
        # TODO: Firestore に保存
        return {"recorded": True, "message": "つきの おわりに コメントが とどくよ"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/creation-feedback/{month}", response_model=CreationFeedback)
async def get_creation_feedback(user_id: str, month: str):
    """
    ⑤ 月次創作フィードバックを取得（月末バッチ生成済み分）
    TODO: Firestore から creation_feedbacks を取得
    """
    try:
        # TODO: Firestore から取得
        feedback = None  # 実際はDBから検索

        if feedback is None:
            raise HTTPException(status_code=404, detail="Feedback not found")

        return feedback
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
