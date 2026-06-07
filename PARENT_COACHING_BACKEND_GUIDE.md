# 親向けAIコーチング実装ガイド — バックエンド

## 概要

このドキュメントは、FastAPI バックエンド で親向けメール配信・AI コーチング機能を実装するための詳細ガイドです。

## 実装予定のアーキテクチャ

```
FastAPI Backend (Python)
├── Services/
│   ├── parent_analytics_service.py      # 週次分析生成
│   ├── gemini_coaching_service.py       # Gemini AI 統合
│   └── email_service.py                 # SendGrid 統合
├── API/
│   └── parent_coaching.py               # エンドポイント
├── Models/
│   └── notification_preferences.py      # Firestore スキーマ
├── Schemas/
│   └── coaching.py                      # リクエスト/レスポンス
└── Tasks/
    └── weekly_email_task.py             # 定期実行タスク
```

## 実装ステップ

### Step 1: 依存関係追加（requirements.txt）

```txt
google-cloud-vertexai>=1.0.0           # Gemini AI
sendgrid>=6.10.0                       # メール送信
google-cloud-scheduler>=3.0.0          # スケジューラー
google-cloud-tasks>=2.10.0             # タスク実行
python-dateutil>=2.8.0                 # 日時計算
```

### Step 2: Models - WeeklyCoachingData モデル

**ファイル**: `backend/app/models/weekly_coaching.py`

```python
from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.db.database import Base
import uuid
from datetime import datetime

class WeeklyCoachingData(Base):
    """週次AIコーチングデータ"""
    __tablename__ = "weekly_coaching"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id = Column(UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), nullable=False)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # 週次統計
    weekly_stories_completed = Column(Integer, default=0)
    weekly_study_minutes = Column(Integer, default=0)
    weekly_points_earned = Column(Integer, default=0)
    
    # 徳目分析
    strongest_virtue = Column(String(50), nullable=True)  # e.g. "kindness"
    weakest_virtue = Column(String(50), nullable=True)    # e.g. "courage"
    virtue_score_changes = Column(JSON)  # {"kindness": 5, "honesty": -2, ...}
    
    completion_streak = Column(Integer, default=0)  # 連続完了日数
    next_milestone = Column(String(200), nullable=True)  # e.g. "レベル5到達"
    trend_analysis = Column(String(500), nullable=True)  # 前週との比較
    
    # Gemini AI 生成コンテンツ
    highlight = Column(String(200), nullable=True)  # 🌟 この週の成長
    advice = Column(String(200), nullable=True)     # 💡 来週へのアドバイス
    parent_tip = Column(String(200), nullable=True) # 👨‍👩‍👧 親向けメッセージ
    
    # メタデータ
    week_number = Column(Integer)  # 1-52
    year = Column(Integer)
    generated_at = Column(DateTime, default=datetime.utcnow)
    email_sent_at = Column(DateTime, nullable=True)
```

### Step 3: Services - 週次分析サービス

**ファイル**: `backend/app/services/parent_analytics_service.py`

```python
from datetime import datetime, timedelta
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.child import Child
from app.models.quiz import QuizSession

class ParentAnalyticsService:
    @staticmethod
    async def generate_weekly_coaching_data(
        child_id: UUID,
        parent_id: UUID,
        week_start: datetime,
        db: AsyncSession
    ) -> dict:
        """
        週次コーチングデータを生成
        - 過去7日の完了ストーリー数
        - 週間学習時間
        - 徳目スコア変化
        - 連続完了日数
        """
        week_end = week_start + timedelta(days=7)
        
        # クイズセッション取得
        sessions_result = await db.execute(
            select(QuizSession).where(
                QuizSession.child_id == child_id,
                QuizSession.is_completed == True,
                QuizSession.completed_at >= week_start,
                QuizSession.completed_at < week_end,
            )
        )
        sessions = sessions_result.scalars().all()
        
        # 統計計算
        stories_completed = len(sessions)
        study_minutes = sum(s.time_spent_seconds for s in sessions) // 60
        points_earned = sum(s.points_earned for s in sessions)
        
        # 子どもプロフィール取得
        child_result = await db.execute(
            select(Child).where(Child.id == child_id)
        )
        child = child_result.scalar_one_or_none()
        if not child:
            raise ValueError(f"Child {child_id} not found")
        
        # 徳目スコア取得（前週との差分）
        # TODO: Firestore から virtue_scores を取得して差分計算
        virtue_changes = {
            'kindness': 5,      # ダミー値
            'honesty': -2,
            'responsibility': 3,
            'courage': 1,
            'respect': 2,
            'cooperation': 4,
        }
        
        strongest = max(virtue_changes, key=virtue_changes.get)
        weakest = min(virtue_changes, key=virtue_changes.get)
        
        return {
            'child_id': str(child_id),
            'parent_id': str(parent_id),
            'weekly_stories_completed': stories_completed,
            'weekly_study_minutes': study_minutes,
            'weekly_points_earned': points_earned,
            'strongest_virtue': strongest,
            'weakest_virtue': weakest,
            'virtue_score_changes': virtue_changes,
            'completion_streak': _calc_streak(sessions),
            'next_milestone': _calc_next_milestone(child.total_points),
            'trend_analysis': _calc_trend(child_id, week_start, db),
        }

def _calc_streak(sessions) -> int:
    """連続完了日数を計算"""
    if not sessions:
        return 0
    # TODO: 実装
    return len(set(s.completed_at.date() for s in sessions))

def _calc_next_milestone(total_points: int) -> str:
    """次のマイルストーンを計算"""
    current_level = total_points // 100 + 1
    next_level_points = (current_level + 1) * 100
    return f"レベル {current_level + 1} 到達（あと {next_level_points - total_points} ポイント）"

async def _calc_trend(child_id: UUID, week_start: datetime, db: AsyncSession) -> str:
    """前週との比較を計算"""
    # TODO: 前週データを取得して比較
    return "先週比で学習時間が30%増加しました"
```

### Step 4: Services - Gemini AI コーチング生成

**ファイル**: `backend/app/services/gemini_coaching_service.py`

```python
import os
import json
from typing import dict
from vertexai.generative_models import GenerativeModel

class GeminiCoachingService:
    def __init__(self):
        self.model = GenerativeModel("gemini-2.0-flash", 
                                      project=os.getenv("GCP_PROJECT_ID"),
                                      location="asia-northeast1")

    async def generate_coaching_message(
        self,
        child_data: dict,
        child_name: str,
        child_grade: int
    ) -> dict:
        """
        Gemini を使用してコーチングメッセージを生成
        """
        prompt = f"""
子どもの学習データに基づいて、親向けコーチングメッセージを生成してください。

【子どもの情報】
- 名前: {child_name}
- 学年: {child_grade}年生

【この週の学習成績】
- 完了ストーリー数: {child_data['weekly_stories_completed']}
- 学習時間: {child_data['weekly_study_minutes']}分
- 獲得ポイント: {child_data['weekly_points_earned']}
- 最も成長した徳目: {child_data['strongest_virtue']} (+{child_data['virtue_score_changes'][child_data['strongest_virtue']]})
- 改善が必要な徳目: {child_data['weakest_virtue']}
- 連続完了日数: {child_data['completion_streak']}日

【出力形式】
以下のJSON形式で出力してください（JSONのみ返却、説明は不要）:
{{
  "highlight": "🌟 この週の{child_name}の頑張り（30-50文字）",
  "advice": "💡 来週への推奨学習（{child_data['weakest_virtue']}を含むストーリーがお勧め、30-50文字）",
  "parent_tip": "👨‍👩‍👧 親向けメッセージ（励まし・褒める内容、30-50文字）"
}}

【トーン】
- 親に対して励ましと褒める
- 子の成長を認める
- 来週への期待感を高める
"""

        response = await self.model.generate_content_async(prompt)
        
        # JSON 抽出
        content = response.text
        # ``` json ... ``` ブロックを抽出
        if '```json' in content:
            json_str = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            json_str = content.split('```')[1].split('```')[0].strip()
        else:
            json_str = content.strip()
        
        coaching = json.loads(json_str)
        return coaching
```

### Step 5: Services - SendGrid メール送信

**ファイル**: `backend/app/services/email_service.py`

```python
import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content
from jinja2 import Template

class EmailService:
    def __init__(self):
        self.sg = SendGridAPIClient(os.getenv("SENDGRID_API_KEY"))
        self.from_email = os.getenv("PARENT_EMAIL_SENDER", "coaching@shougaku-kore.jp")

    async def send_weekly_coaching_email(
        self,
        parent_email: str,
        child_name: str,
        coaching_data: dict
    ) -> dict:
        """
        週次コーチングメール送信
        """
        html_content = self._render_email_template(child_name, coaching_data)

        message = Mail(
            from_email=Email(self.from_email),
            to_emails=[To(parent_email)],
            subject=f"[小学コレ！道徳] {child_name}の今週の学習レポート",
            html_content=html_content,
            reply_to_email=Email("support@shougaku-kore.jp"),
        )

        try:
            response = self.sg.send(message)
            return {
                "success": True,
                "message_id": response.headers.get('X-Message-ID'),
                "status_code": response.status_code,
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
            }

    def _render_email_template(self, child_name: str, data: dict) -> str:
        """
        メール HTML テンプレートをレンダリング
        """
        template_html = """
<html>
<body style="font-family: Arial, sans-serif; color: #333;">
    <h1>📧 {{ child_name }}の週間学習レポート</h1>
    
    <section>
        <h2>🌟 この週の頑張り</h2>
        <p>{{ highlight }}</p>
    </section>
    
    <section>
        <h2>📈 成長した徳目</h2>
        <p><strong>{{ strongest_virtue }}</strong>: +{{ virtue_score_changes[strongest_virtue] }} points</p>
        <p>学習時間: {{ weekly_study_minutes }}分 | 完了ストーリー: {{ weekly_stories_completed }}個</p>
    </section>
    
    <section>
        <h2>💡 来週へのアドバイス</h2>
        <p>{{ advice }}</p>
    </section>
    
    <section>
        <h2>👨‍👩‍👧 保護者へのメッセージ</h2>
        <p>{{ parent_tip }}</p>
    </section>
    
    <footer style="margin-top: 40px; color: #999; font-size: 12px;">
        <p><a href="app://reports">アプリで詳細を確認する</a></p>
        <p><a href="app://settings/notifications">通知設定を変更する</a></p>
    </footer>
</body>
</html>
"""
        t = Template(template_html)
        return t.render(
            child_name=child_name,
            highlight=data.get('highlight', ''),
            strongest_virtue=data.get('strongest_virtue', ''),
            weekly_study_minutes=data.get('weekly_study_minutes', 0),
            weekly_stories_completed=data.get('weekly_stories_completed', 0),
            advice=data.get('advice', ''),
            parent_tip=data.get('parent_tip', ''),
            virtue_score_changes=data.get('virtue_score_changes', {}),
        )
```

### Step 6: API エンドポイント

**ファイル**: `backend/app/api/parent_coaching.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.security import get_current_user_id
from app.services.parent_analytics_service import ParentAnalyticsService
from app.services.gemini_coaching_service import GeminiCoachingService

router = APIRouter()

@router.post("/children/{child_id}/weekly-coaching/generate")
async def generate_weekly_coaching(
    child_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """週次コーチングデータ生成"""
    analytics = ParentAnalyticsService()
    gemini = GeminiCoachingService()
    
    # 週次分析生成
    coaching_data = await analytics.generate_weekly_coaching_data(
        child_id=child_id,
        parent_id=user_id,
        week_start=datetime.now() - timedelta(days=7),
        db=db,
    )
    
    # AI コメント生成
    coaching_content = await gemini.generate_coaching_message(
        child_data=coaching_data,
        child_name="たろう",  # TODO: DB から取得
        child_grade=3,  # TODO: DB から取得
    )
    
    return {
        "success": True,
        "data": {**coaching_data, **coaching_content},
    }
```

### Step 7: 定期実行タスク

**ファイル**: `backend/app/tasks/weekly_email_task.py`

```python
# APScheduler または Google Cloud Tasks を使用
# 毎週日曜 18:00 JST にメール送信
# Cloud Run スケジューラーから呼び出し

import asyncio
from datetime import datetime
from app.services.email_service import EmailService
from app.db.database import get_db

async def send_weekly_emails():
    """全親にメール配信"""
    # TODO: Firestore から notificationPreferences を取得
    # TODO: 配信対象の親を判定
    # TODO: 各親のメールを送信
    
    email_service = EmailService()
    # for parent in target_parents:
    #     await email_service.send_weekly_coaching_email(...)
    pass
```

## テスト実装

### テストフレームワーク: pytest + asyncio

```python
# backend/tests/services/test_parent_analytics.py
import pytest
from datetime import datetime, timedelta
from app.services.parent_analytics_service import ParentAnalyticsService

@pytest.mark.asyncio
async def test_generate_weekly_coaching_data(db_session):
    """週次分析生成テスト"""
    service = ParentAnalyticsService()
    data = await service.generate_weekly_coaching_data(
        child_id=...,
        parent_id=...,
        week_start=datetime.now() - timedelta(days=7),
        db=db_session,
    )
    
    assert data['weekly_stories_completed'] >= 0
    assert data['strongest_virtue'] in ['kindness', 'honesty', ...]
```

## 依存関係インストール

```bash
pip install -r requirements.txt
```

## 環境変数設定

```.env
SENDGRID_API_KEY=SG.xxxxxxxxxxxxx
PARENT_EMAIL_SENDER=coaching@shougaku-kore.jp
GCP_PROJECT_ID=shougaku-kore-doutoku
```

## 次のステップ

1. ✅ フロントエンド実装（完了）
2. 📋 バックエンド Services 実装（本ガイド参照）
3. 📋 API エンドポイント実装
4. 📋 定期実行スケジューラー実装
5. 📋 テスト実装・実行
6. 📋 本番デプロイ

---

**注**: 本ガイドはテンプレートです。実装時にはプロジェクト固有の要件に応じて調整してください。
