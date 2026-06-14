from fastapi import APIRouter, HTTPException
from datetime import datetime
from ..models.parent_child import ParentChildComparison, ParentAnswerResponse

router = APIRouter(prefix="/parent-child", tags=["parent-child"])

@router.post("/{parent_id}/{child_id}/answer", response_model=ParentAnswerResponse)
async def answer_parent_child_story(
    parent_id: str,
    child_id: str,
    story_id: str,
    answer_choice: str,
):
    """
    親が子どもと同じジレンマに回答
    
    TODO: 回答を Firestore に保存
    TODO: 子どもの回答と比較
    TODO: 両方が回答したら対話ガイドを生成
    """
    try:
        child_choice = "B"  # TODO: Firestore から取得
        
        guidance = (
            "親子で違う選択をしました。\n"
            "お子さんに「どうしてそう思ったの？」と聞き出してから、\n"
            "パパ・ママの理由を話すのがコツです。"
        )
        
        return ParentAnswerResponse(
            parent_choice=answer_choice,
            child_choice=child_choice,
            is_both_answered=True,
            guidance=guidance,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{parent_id}/{child_id}/dialogue-history", response_model=dict)
async def get_dialogue_history(parent_id: str, child_id: str):
    """
    過去の親子比較履歴を取得（最新12件）
    
    TODO: Firestore から parent_answers を取得
    """
    try:
        histories = [
            ParentChildComparison(
                story_id="story_001",
                story_title="友達とケンカした",
                child_choice_letter="A",
                child_choice_text="だまっておく",
                parent_choice_letter="B",
                parent_choice_text="本人に話す",
                guidance="親子で選択が異なります。対話のチャンスです。",
                answered_at=datetime.utcnow(),
            ),
        ]
        return {"histories": [h.dict() for h in histories]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
