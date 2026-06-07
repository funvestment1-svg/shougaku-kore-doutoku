import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_child(client: AsyncClient, auth_headers: dict):
    response = await client.post(
        "/api/v1/children",
        json={"name": "花子", "grade": 4, "avatar_emoji": "🌸"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "花子"
    assert data["grade"] == 4
    assert data["level"] == 1
    assert data["totalPoints"] == 0


@pytest.mark.asyncio
async def test_list_children(client: AsyncClient, auth_headers: dict, test_child: dict):
    response = await client.get("/api/v1/children", headers=auth_headers)
    assert response.status_code == 200
    children = response.json()
    assert len(children) >= 1
    assert any(c["id"] == test_child["id"] for c in children)


@pytest.mark.asyncio
async def test_get_child(client: AsyncClient, auth_headers: dict, test_child: dict):
    child_id = test_child["id"]
    response = await client.get(f"/api/v1/children/{child_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["id"] == child_id


@pytest.mark.asyncio
async def test_update_child(client: AsyncClient, auth_headers: dict, test_child: dict):
    child_id = test_child["id"]
    response = await client.put(
        f"/api/v1/children/{child_id}",
        json={"name": "更新太郎"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["name"] == "更新太郎"


@pytest.mark.asyncio
async def test_delete_child(client: AsyncClient, auth_headers: dict, test_child: dict):
    child_id = test_child["id"]
    response = await client.delete(f"/api/v1/children/{child_id}", headers=auth_headers)
    assert response.status_code == 204

    # 削除後は404
    response = await client.get(f"/api/v1/children/{child_id}", headers=auth_headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_child_invalid_grade(client: AsyncClient, auth_headers: dict):
    """学年バリデーション (3-4年生のみ)"""
    response = await client.post(
        "/api/v1/children",
        json={"name": "太郎", "grade": 5},
        headers=auth_headers,
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_unauthorized_child_access(client: AsyncClient):
    """未認証アクセス"""
    response = await client.get("/api/v1/children")
    assert response.status_code == 401  # Starlette 1.x HTTPBearer returns 401 for missing credentials


@pytest.mark.asyncio
async def test_update_child_all_fields(client: AsyncClient, auth_headers: dict, test_child: dict):
    """update with name + avatarEmoji + grade covers all conditional branches."""
    child_id = test_child["id"]
    r = await client.put(
        f"/api/v1/children/{child_id}",
        json={"name": "新太郎", "avatarEmoji": "🌟", "grade": 4},
        headers=auth_headers,
    )
    assert r.status_code == 200
    data = r.json()
    assert data["name"] == "新太郎"
    assert data["avatarEmoji"] == "🌟"
    assert data["grade"] == 4


@pytest.mark.asyncio
async def test_update_child_not_found(client: AsyncClient, auth_headers: dict):
    """Update a non-existent child returns 404."""
    r = await client.put(
        "/api/v1/children/00000000-0000-0000-0000-000000000000",
        json={"name": "Ghost"},
        headers=auth_headers,
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_delete_child_not_found(client: AsyncClient, auth_headers: dict):
    """Delete a non-existent child returns 404."""
    r = await client.delete(
        "/api/v1/children/00000000-0000-0000-0000-000000000000",
        headers=auth_headers,
    )
    assert r.status_code == 404
