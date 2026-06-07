"""Tests for GET /api/v1/progress/{child_id}"""
import pytest
import uuid
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_progress_empty(client: AsyncClient, auth_headers: dict, test_child: dict):
    """子どもの進捗が空リストで返る"""
    child_id = test_child["id"]
    r = await client.get(f"/api/v1/progress/{child_id}", headers=auth_headers)
    assert r.status_code == 200
    assert isinstance(r.json(), list)


@pytest.mark.asyncio
async def test_get_progress_after_quiz_completion(
    client: AsyncClient, auth_headers: dict, test_child: dict
):
    """クイズ完了後に進捗レコードが含まれる"""
    child_id = test_child["id"]
    story_id = str(uuid.uuid4())

    # クイズセッション開始
    start_r = await client.post(
        "/api/v1/quizzes",
        json={"childId": child_id, "storyId": story_id},
        headers=auth_headers,
    )
    assert start_r.status_code == 201
    session_id = start_r.json()["id"]

    # クイズ完了
    await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={
            "chosenChoiceId": str(uuid.uuid4()),  # unknown → fallback 10pt
            "timeSpentSeconds": 120,
        },
        headers=auth_headers,
    )

    # 進捗取得
    r = await client.get(f"/api/v1/progress/{child_id}", headers=auth_headers)
    assert r.status_code == 200
    items = r.json()
    assert len(items) >= 1
    # action フィールドが含まれる
    completed = [i for i in items if i["action"] == "story_completed"]
    assert len(completed) >= 1
    assert "recordedAt" in completed[0]
    assert "childId" in completed[0]


@pytest.mark.asyncio
async def test_get_progress_forbidden_other_child(client: AsyncClient, auth_headers: dict):
    """他のユーザーの子どもの進捗は取得できない"""
    r = await client.get(
        f"/api/v1/progress/{uuid.uuid4()}", headers=auth_headers
    )
    assert r.status_code == 403
