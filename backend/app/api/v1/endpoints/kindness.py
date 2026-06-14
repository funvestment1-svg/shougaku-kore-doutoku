from fastapi import APIRouter, HTTPException
from datetime import datetime
from ..models.kindness import (
    KindnessMission,
    KindnessRecordResponse,
    KindnessMap,
    KindnessFinding,
)

router = APIRouter(prefix="/users", tags=["kindness"])

@router.get("/{user_id}/kindness/mission", response_model=KindnessMission)
async def get_current_mission(user_id: str):
    """
    今週のやさしさ探しミッションを取得
    
    TODO: Firestore から kindness_missions を取得して返す
    """
    try:
        return KindnessMission(
            mission_id="mission_123",
            target_count=3,
            completed_count=1,
            is_completed=False,
            created_at=datetime.utcnow(),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{user_id}/kindness-records", response_model=KindnessRecordResponse)
async def record_kindness(
    user_id: str,
    kindness_description: str,
    person_involved: str | None = None,
    context: str | None = None,
):
    """
    やさしさを記録
    
    TODO: Firestore に kindness_records を保存
    TODO: kindness_missions の completed_count をインクリメント
    """
    try:
        return KindnessRecordResponse(
            recorded=True,
            progress="2/3",
            is_mission_complete=False,
            reward_points=10,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{user_id}/kindness-map/{month}", response_model=KindnessMap)
async def get_kindness_map(user_id: str, month: str):
    """
    月次「やさしさマップ」を取得
    
    TODO: Firestore から kindness_records を集計
    TODO: カテゴリ別に分類して返す
    """
    try:
        return KindnessMap(
            month=month,
            total_findings=12,
            by_category={
                "family": [
                    KindnessFinding(
                        description="お兄ちゃんが ぼくの分も おかし のこしてくれた",
                        person="お兄ちゃん",
                    ),
                ],
                "school": [
                    KindnessFinding(
                        description="先生が 困ってる子に ていねいに おしえてくれた",
                        person="先生",
                    ),
                ],
                "community": [],
            },
            message="これだけのやさしさを さがしました！",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
