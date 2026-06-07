"""Tests for stories API."""
import pytest


@pytest.mark.asyncio
async def test_list_stories_empty(client, auth_headers):
    """List stories returns empty list when no stories seeded."""
    response = await client.get("/api/v1/stories", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_list_stories_unauthenticated(client):
    """Stories endpoint is publicly accessible (no auth required for browsing)."""
    response = await client.get("/api/v1/stories")
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_list_stories_theme_filter(client, auth_headers):
    """Filter stories by theme returns only matching."""
    response = await client.get(
        "/api/v1/stories",
        params={"theme": "kindness"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    for story in response.json():
        assert story["theme"] == "kindness"


@pytest.mark.asyncio
async def test_get_story_not_found(client, auth_headers):
    """Getting a non-existent story returns 404."""
    response = await client.get(
        "/api/v1/stories/00000000-0000-0000-0000-000000000000",
        headers=auth_headers,
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_weekly_stories(client, auth_headers):
    """Weekly stories endpoint is accessible."""
    response = await client.get("/api/v1/stories/weekly/1", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    for story in data:
        assert story["weekNumber"] == 1


@pytest.mark.asyncio
async def test_list_stories_with_seeded_data(client, auth_headers, test_story):
    """List endpoint returns story with description and difficulty."""
    response = await client.get("/api/v1/stories", headers=auth_headers)
    assert response.status_code == 200
    stories = response.json()
    assert len(stories) == 1
    s = stories[0]
    assert s["id"] == test_story["id"]
    assert s["title"] == "テスト道徳ストーリー"
    assert s["description"] == "テスト用の説明文"
    assert s["difficulty"] == 2
    assert s["theme"] == "kindness"
    assert s["gradeLevel"] == 3
    assert s["isPremium"] is False
    assert s["durationSeconds"] == 300  # 5 minutes * 60


@pytest.mark.asyncio
async def test_get_story_detail(client, auth_headers, test_story):
    """Detail endpoint returns content and choices."""
    response = await client.get(
        f"/api/v1/stories/{test_story['id']}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    s = response.json()
    assert s["id"] == test_story["id"]
    # content is included in detail
    assert "content" in s
    content = s["content"]
    assert content["introduction"] == "ある日、太郎は公園で…"
    assert content["mainNarrative"] == ["第一段落のテキスト"]
    assert content["dilemmaScene"] == "あなたならどうしますか？"
    # choices are embedded in content
    assert len(content["choices"]) == 1
    choice = content["choices"][0]
    assert choice["id"] == test_story["choice_id"]
    assert choice["text"] == "友達を助ける"
    assert choice["value"] == "kindness"


@pytest.mark.asyncio
async def test_list_stories_theme_filter_with_data(client, auth_headers, test_story):
    """Theme filter excludes non-matching stories."""
    resp_match = await client.get(
        "/api/v1/stories", params={"theme": "kindness"}, headers=auth_headers
    )
    assert len(resp_match.json()) == 1

    resp_no_match = await client.get(
        "/api/v1/stories", params={"theme": "honesty"}, headers=auth_headers
    )
    assert len(resp_no_match.json()) == 0


@pytest.mark.asyncio
async def test_list_stories_grade_filter(client, auth_headers, test_story):
    """grade filter: story with grade_min=3/grade_max=4 matches grade=3."""
    r = await client.get("/api/v1/stories", params={"grade": 3}, headers=auth_headers)
    assert r.status_code == 200
    ids = [s["id"] for s in r.json()]
    assert test_story["id"] in ids


@pytest.mark.asyncio
async def test_list_stories_is_premium_filter(client, auth_headers, test_story):
    """is_premium=false filter returns only free stories."""
    r = await client.get("/api/v1/stories", params={"is_premium": "false"}, headers=auth_headers)
    assert r.status_code == 200
    for s in r.json():
        assert s["isPremium"] is False
    # Seeded story is free → should be included
    ids = [s["id"] for s in r.json()]
    assert test_story["id"] in ids


@pytest.mark.asyncio
async def test_list_stories_week_filter(client, testing_db):
    """week filter returns only stories with matching week_number."""
    import uuid
    from app.models.story import Story

    story_id = uuid.uuid4()
    async with testing_db() as session:
        story = Story(
            id=story_id,
            title="Weekly Story",
            description="週次テスト",
            theme="responsibility",
            grade_min=3,
            difficulty=1,
            is_premium=False,
            content={"introduction": "…", "mainNarrative": [], "dilemmaScene": "？"},
            estimated_minutes=5,
            is_published=True,
            week_number=99,
        )
        session.add(story)
        await session.commit()

    r = await client.get("/api/v1/stories", params={"week": 99})
    assert r.status_code == 200
    ids = [s["id"] for s in r.json()]
    assert str(story_id) in ids
