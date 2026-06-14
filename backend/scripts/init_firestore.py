"""
Firestore 初期化スクリプト
firebase_admin を使用して必要なコレクションを作成
"""
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# TODO: サービスアカウントキーをダウンロード
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()


def initialize_collections():
    """すべてのコレクションを初期化"""
    print("Firestore コレクション初期化中...")

    # ① answer_statistics — 全国選択分布
    db.collection("answer_statistics").document("template").set(
        {
            "story_id": "story_template",
            "option_a_count": 0,
            "option_b_count": 0,
            "option_c_count": 0,
            "option_d_count": 0,
            "total_responses": 0,
            "calculated_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
    )
    print("✓ answer_statistics")

    # ② revisit_schedules — 3ヶ月再訪
    db.collection("revisit_schedules").document("template").set(
        {
            "user_id": "user_template",
            "story_id": "story_template",
            "original_answer_id": "answer_template",
            "original_answer_choice": "A",
            "revisit_answer_id": None,
            "scheduled_for": datetime.utcnow().date(),
            "is_completed": False,
            "completed_at": None,
            "created_at": datetime.utcnow(),
        }
    )
    print("✓ revisit_schedules")

    # ④ parent_answers — 親子くらべっこ
    db.collection("parent_answers").document("template").set(
        {
            "parent_id": "parent_template",
            "child_id": "child_template",
            "story_id": "story_template",
            "answer_choice": "A",
            "responded_at": datetime.utcnow(),
            "is_revealed": False,
            "revealed_at": None,
            "created_at": datetime.utcnow(),
        }
    )
    print("✓ parent_answers")

    # ⑥ kindness_records — やさしさミッション
    db.collection("kindness_records").document("template").set(
        {
            "user_id": "user_template",
            "mission_week": datetime.utcnow().date(),
            "kindness_description": "example",
            "person_involved": "example",
            "context": "example",
            "recorded_at": datetime.utcnow(),
            "created_at": datetime.utcnow(),
        }
    )
    print("✓ kindness_records")

    # kindness_missions テーブル
    db.collection("kindness_missions").document("template").set(
        {
            "user_id": "user_template",
            "mission_week": datetime.utcnow().date(),
            "target_count": 3,
            "completed_count": 0,
            "is_completed": False,
            "monthly_summary_generated": False,
            "created_at": datetime.utcnow(),
        }
    )
    print("✓ kindness_missions")

    print("\n✅ Firestore コレクション初期化完了")


if __name__ == "__main__":
    initialize_collections()
