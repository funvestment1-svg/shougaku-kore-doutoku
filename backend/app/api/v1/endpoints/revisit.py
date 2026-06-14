from fastapi import APIRouter, HTTPException
from datetime import datetime
from ..models.revisit import RevisitStory, RevisitResult

router = APIRouter(prefix="/users", tags=["revisit"])

@router.get("/{user_id}/revisit-stories", response_model=dict)
async def get_revisit_stories(user_id: str):
    """
    当月の再訪ストーリー一覧を取得
    
    TODO: Firestore から revisit_schedules を取得して返す
    """
    try:
        revisits = [
            RevisitStory(
                revisit_id="revisit_123",
                story_id="story_001",
                title="友達とケンカした",
                original_answer="A",
                preview="友達と意見が違ったときに、どうしますか？"
            ),
        ]
        return {"revisits": [r.dict() for r in revisits]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/revisit-stories/{revisit_id}/answer", response_model=RevisitResult)
async def answer_revisit_story(
    revisit_id: str,
    answer_choice: str,
):
    """
    再訪ストーリーに回答
    
    TODO: 回答を Firestore に保存
    TODO: 元の回答と比較して is_changed を計算
    """
    try:
        original_choice = "A"
        is_changed = original_choice != answer_choice
        
        message = (
            "きみの かんがえは どんどん 成長しているね！"
            if is_changed
            else "きみの かんがえは とても 一貫しているね。"
        )
        
        return RevisitResult(
            original_choice=original_choice,
            current_choice=answer_choice,
            is_changed=is_changed,
            message=message,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
