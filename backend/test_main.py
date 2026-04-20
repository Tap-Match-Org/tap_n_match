import pytest
from httpx import ASGITransport, AsyncClient
from backend.main import app, pending_codes
import sqlite3
import os
from unittest.mock import patch
from datetime import date

# Use a separate test database
TEST_DB = "test_users.db"
ORIGINAL_CONNECT = sqlite3.connect

def mock_connect(database, *args, **kwargs):
    # Always redirect to TEST_DB regardless of what is requested
    return ORIGINAL_CONNECT(TEST_DB, *args, **kwargs)

@pytest.fixture(autouse=True)
def setup_db():
    # Patch sqlite3.connect in backend.main to use our test database
    with patch("sqlite3.connect", side_effect=mock_connect):
        # Ensure clean state
        if os.path.exists(TEST_DB):
            os.remove(TEST_DB)
        
        # Initialize the test database schema using the real connect
        conn = ORIGINAL_CONNECT(TEST_DB)
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                unlocked_themes TEXT DEFAULT '',
                selected_theme TEXT DEFAULT '#A9A9A9',
                last_username_change_date TEXT,
                profile_picture TEXT DEFAULT '',
                streak INTEGER DEFAULT 0,
                last_challenge_date TEXT,
                daily_attempts INTEGER DEFAULT 0,
                last_attempt_date TEXT,
                created_at TEXT,
                total_score INTEGER DEFAULT 0,
                highest_score INTEGER DEFAULT 0,
                highest_level INTEGER DEFAULT 0,
                levels_cleared INTEGER DEFAULT 0,
                fast_finishes INTEGER DEFAULT 0,
                perfect_finishes INTEGER DEFAULT 0,
                boxes_tapped INTEGER DEFAULT 0,
                completed_daily_challenges INTEGER DEFAULT 0,
                extreme_clears INTEGER DEFAULT 0,
                banked_points INTEGER DEFAULT 0,
                lifetime_points INTEGER DEFAULT 0,
                unlocked_tap_sounds TEXT DEFAULT 'audio/tap_sounds/default_tapSounds.mp3',
                selected_tap_sound TEXT DEFAULT 'audio/tap_sounds/default_tapSounds.mp3',
                unlocked_bg_music TEXT DEFAULT 'audio/background_music/stal_default.mp3',
                selected_bg_music TEXT DEFAULT 'audio/background_music/stal_default.mp3',
                tap_sound_enabled INTEGER DEFAULT 1,
                bg_music_enabled INTEGER DEFAULT 1,
                tap_volume REAL DEFAULT 1.0,
                bg_volume REAL DEFAULT 0.5,
                colorblind_mode INTEGER DEFAULT 0,
                is_banned INTEGER DEFAULT 0,
                ban_reason TEXT,
                claimed_rewards TEXT DEFAULT '',
                seen_rewards TEXT DEFAULT '',
                tutorial_enabled INTEGER DEFAULT 0,
                completed_tutorials TEXT DEFAULT ''
            )
        """)
        conn.commit()
        conn.close()
        
        yield
        
        if os.path.exists(TEST_DB):
            os.remove(TEST_DB)

@pytest.mark.asyncio
async def test_register_success():
    # Mock verification code
    pending_codes["test@gmail.com"] = "123456"
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        with patch("sqlite3.connect", side_effect=mock_connect):
            response = await ac.post("/register", json={
                "username": "testuser",
                "email": "test@gmail.com",
                "password": "password123",
                "code": "123456"
            })
    
    assert response.status_code == 200
    assert response.json() == {"message": "User registered successfully."}

@pytest.mark.asyncio
async def test_login_success():
    # Pre-populate user
    conn = ORIGINAL_CONNECT(TEST_DB)
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO users (username, email, password, is_banned) VALUES (?, ?, ?, ?)",
        ("loginuser", "login@gmail.com", "secret", 0)
    )
    conn.commit()
    conn.close()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        with patch("sqlite3.connect", side_effect=mock_connect):
            response = await ac.post("/login", json={
                "username": "loginuser",
                "password": "secret"
            })
    
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "loginuser"
    assert "user_id" in data

@pytest.mark.asyncio
async def test_login_banned():
    # Pre-populate banned user
    conn = ORIGINAL_CONNECT(TEST_DB)
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO users (username, email, password, is_banned, ban_reason) VALUES (?, ?, ?, ?, ?)",
        ("banneduser", "banned@gmail.com", "secret", 1, "Testing ban")
    )
    conn.commit()
    conn.close()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        with patch("sqlite3.connect", side_effect=mock_connect):
            response = await ac.post("/login", json={
                "username": "banneduser",
                "password": "secret"
            })
    
    assert response.status_code == 403
    assert "Testing ban" in response.json()["detail"]["reason"]
