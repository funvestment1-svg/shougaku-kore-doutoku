from fastapi import APIRouter, HTTPException
from datetime import datetime
from ..models.distribution import DistributionResponse, DistributionOption

router = APIRouter(prefix="/stories", tags=["stories"])

@router.get("/{story_id}/distribution", response_model=DistributionResponse)
async def get_answer_distribution(story_id: str):
    """
    全国選択分布を取得
    
    TODO: Firestore から answer_statistics を取得して返す
    """
    try:
        options = [
            DistributionOption(
                option="A",
                text="だまっておく",
                count=1050,
                percentage=42.0,
                color="blue"
            ),
            DistributionOption(
                option="B",
                text="本人に直接話す",
                count=775,
                percentage=31.0,
                color="green"
            ),
            DistributionOption(
                option="C",
                text="先生に相談する",
                count=675,
                percentage=27.0,
                color="yellow"
            ),
        ]
        
        return DistributionResponse(
            story_id=story_id,
            title="友達のヒミツ",
            options=options,
            total_responses=2500,
            last_updated=datetime.utcnow(),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
