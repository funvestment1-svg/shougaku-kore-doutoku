"""Tests for user profile API (/api/v1/users/me)."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient, auth_headers: dict, test_user: dict):
    """Authenticated user can fetch their own profile."""
    response = await client.get("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert data["email"] == "test@example.com"
    assert data["name"] == "テストユーザー"
    assert data["isActive"] is True
    assert "createdAt" in data


@pytest.mark.asyncio
async def test_get_me_unauthorized(client: AsyncClient):
    """Unauthenticated request returns 401."""
    response = await client.get("/api/v1/users/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_update_name(client: AsyncClient, auth_headers: dict):
    """User can update their display name."""
    response = await client.put(
        "/api/v1/users/me",
        json={"name": "更新済みユーザー"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["name"] == "更新済みユーザー"


@pytest.mark.asyncio
async def test_update_fcm_token(client: AsyncClient, auth_headers: dict):
    """User can register an FCM push token."""
    token = "fcm-test-token-abc123"
    response = await client.put(
        "/api/v1/users/me",
        json={"fcmToken": token},
        headers=auth_headers,
    )
    assert response.status_code == 200
    # FCM token is stored internally — not exposed in response
    assert response.json()["isActive"] is True


@pytest.mark.asyncio
async def test_update_name_camelcase(client: AsyncClient, auth_headers: dict):
    """Update endpoint accepts camelCase body keys."""
    response = await client.put(
        "/api/v1/users/me",
        json={"name": "キャメルケースユーザー", "fcmToken": "token-xyz"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["name"] == "キャメルケースユーザー"


@pytest.mark.asyncio
async def test_update_partial(client: AsyncClient, auth_headers: dict):
    """Partial update (only one field) leaves other fields unchanged."""
    # First set a name
    await client.put(
        "/api/v1/users/me",
        json={"name": "初期名前"},
        headers=auth_headers,
    )
    # Update only fcm_token — name should be preserved
    r = await client.put(
        "/api/v1/users/me",
        json={"fcmToken": "new-token"},
        headers=auth_headers,
    )
    assert r.status_code == 200
    assert r.json()["name"] == "初期名前"


@pytest.mark.asyncio
async def test_delete_me(client: AsyncClient, auth_headers: dict):
    """User can delete their own account."""
    response = await client.delete("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 204

    # After deletion, the same token is invalid (user gone)
    r2 = await client.get("/api/v1/users/me", headers=auth_headers)
    assert r2.status_code == 404


@pytest.mark.asyncio
async def test_update_me_after_deletion(client: AsyncClient, auth_headers: dict):
    """PUT /me with a valid token for a deleted user returns 404."""
    await client.delete("/api/v1/users/me", headers=auth_headers)
    r = await client.put("/api/v1/users/me", json={"name": "Ghost"}, headers=auth_headers)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_delete_me_twice(client: AsyncClient, auth_headers: dict):
    """DELETE /me a second time (user already gone) returns 404."""
    await client.delete("/api/v1/users/me", headers=auth_headers)
    r = await client.delete("/api/v1/users/me", headers=auth_headers)
    assert r.status_code == 404
