from datetime import datetime
from typing import Optional, List, Any, Dict
from uuid import UUID
from pydantic import BaseModel, ConfigDict, model_validator
from pydantic.alias_generators import to_camel


class StoryChoiceResponse(BaseModel):
    """選択肢レスポンス — Flutter の StoryChoice に対応"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    text: str
    value: Optional[str] = None         # 関わる徳目 (kindness/honesty/etc)
    branch_content: str = ""            # 選択後の展開テキスト → branchContent
    reflection: str = ""               # 振り返りコメント
    points: int = 10
    is_recommended: bool = False


class StoryContentResponse(BaseModel):
    """ストーリー本文レスポンス — Flutter の StoryContent に対応"""
    introduction: str = ""
    main_narrative: List[str] = []     # → mainNarrative
    dilemma_scene: str = ""            # → dilemmaScene
    illustration_url: Optional[str] = None  # → illustrationUrl
    choices: List[StoryChoiceResponse] = []

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )


class StoryResponse(BaseModel):
    """ストーリー一覧レスポンス — Flutter の Story に対応"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    title: str
    description: Optional[str] = None    # → description (プレビュー用)
    theme: str
    grade_level: int = 3          # → gradeLevel (grade_min から)
    difficulty: int = 1           # → difficulty (1-3)
    is_premium: bool = False
    duration_seconds: int = 300   # → durationSeconds (estimated_minutes * 60)
    illustration_url: Optional[str] = None  # → illustrationUrl (image_url から)
    created_at: datetime
    updated_at: datetime
    version: int = 1

    @model_validator(mode="before")
    @classmethod
    def map_fields(cls, data: Any) -> Any:
        """DB モデルから Flutter 向けにフィールドをマッピング"""
        if hasattr(data, "__dict__"):
            # SQLAlchemy モデルから変換
            grade_level = getattr(data, "grade_min", 3)
            estimated = getattr(data, "estimated_minutes", 5)
            return {
                "id": data.id,
                "title": data.title,
                "description": getattr(data, "description", None),
                "theme": data.theme,
                "grade_level": grade_level,
                "difficulty": getattr(data, "difficulty", 1),
                "is_premium": data.is_premium,
                "duration_seconds": estimated * 60,
                "illustration_url": getattr(data, "image_url", None),
                "created_at": data.created_at,
                "updated_at": data.updated_at,
                "version": 1,
            }
        return data


class StoryDetailResponse(StoryResponse):
    """ストーリー詳細レスポンス — content + choices を含む"""
    content: StoryContentResponse

    @model_validator(mode="before")
    @classmethod
    def map_fields(cls, data: Any) -> Any:
        """DB モデルから Flutter 向けにフィールドをマッピング"""
        if hasattr(data, "__dict__"):
            grade_level = getattr(data, "grade_min", 3)
            estimated = getattr(data, "estimated_minutes", 5)
            raw_content = getattr(data, "content", {}) or {}

            # choices を StoryChoiceResponse に変換
            choices = []
            for c in getattr(data, "choices", []):
                choices.append(StoryChoiceResponse(
                    id=c.id,
                    text=c.text,
                    value=c.value,
                    branch_content=c.branch_content,
                    reflection=c.reflection,
                    points=c.points,
                    is_recommended=c.is_recommended,
                ))

            # content は DB に JSON として保存されている
            # choices を content に埋め込む (Flutter StoryContent 形式)
            content = StoryContentResponse(
                introduction=raw_content.get("introduction", ""),
                main_narrative=raw_content.get("mainNarrative", []),
                dilemma_scene=raw_content.get("dilemmaScene", ""),
                illustration_url=raw_content.get("illustrationUrl"),
                choices=choices,
            )

            return {
                "id": data.id,
                "title": data.title,
                "description": getattr(data, "description", None),
                "theme": data.theme,
                "grade_level": grade_level,
                "difficulty": getattr(data, "difficulty", 1),
                "is_premium": data.is_premium,
                "duration_seconds": estimated * 60,
                "illustration_url": getattr(data, "image_url", None),
                "created_at": data.created_at,
                "updated_at": data.updated_at,
                "version": 1,
                "content": content,
            }
        return data
