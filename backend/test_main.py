import pytest
import sqlite3
import json
import os
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport
from backend.main import app, pending_codes, ACTIVITY_EVENT_LABELS, admin_sessions

# Use a shared in-memory database URI with cache=shared to keep the database alive 
# across multiple connections as long as at least one connection is open.
TEST_DB_URI = "file:cached_test_db?mode=memory&cache=shared"

# Keep one connection open for the duration of the test session to prevent the DB from being wiped.
_KEEPALIVE_CONN = sqlite3.connect(TEST_DB_URI, uri=True)

def mock_get_db_connection():
    # Return a new connection to the shared in-memory database.
    # main.py can safely call conn.close() on this.
    conn = sqlite3.connect(TEST_DB_URI, uri=True)
    conn.row_factory = sqlite3.Row
    return conn

@pytest.fixture(autouse=True)
def setup_db():
    # Patch get_db_connection in backend.main
    with patch("backend.main.get_db_connection", side_effect=mock_get_db_connection):
        # Initialize/Reset the test database schema using the keepalive connection
        cursor = _KEEPALIVE_CONN.cursor()
        
        # Disable foreign keys temporarily if needed, though not used here
        cursor.execute("DROP TABLE IF EXISTS users")
        cursor.execute("DROP TABLE IF EXISTS player_activity_logs")
        cursor.execute("DROP TABLE IF EXISTS reports")
        cursor.execute("DROP TABLE IF EXISTS admin_activity_logs")
        
        # Create users table with all columns from main.py
        cursor.execute("""
            CREATE TABLE users (
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
                last_active_at TEXT,
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
                firebase_uid TEXT,
                claimed_rewards TEXT DEFAULT '',
                seen_rewards TEXT DEFAULT '',
                tutorial_enabled INTEGER DEFAULT 0,
                completed_tutorials TEXT DEFAULT ''
            )
        """)
        
        cursor.execute("""
            CREATE TABLE player_activity_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                event_type TEXT NOT NULL,
                summary TEXT NOT NULL,
                metadata TEXT DEFAULT '{}',
                created_at TEXT NOT NULL
            )
        """)
        
        cursor.execute("""
            CREATE TABLE reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                reporter_id INTEGER,
                reported_id INTEGER,
                reason TEXT,
                timestamp TEXT,
                status TEXT DEFAULT 'Pending'
            )
        """)

        cursor.execute("""
            CREATE TABLE admin_activity_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                admin_email TEXT NOT NULL,
                action TEXT NOT NULL,
                details TEXT DEFAULT '{}',
                target_user_id INTEGER,
                created_at TEXT NOT NULL
            )
        """)
        
        _KEEPALIVE_CONN.commit()

        yield
        
        pending_codes.clear()
        admin_sessions.clear()

@pytest.mark.asyncio
async def test_register_success():
    # Mock verification code
    pending_codes["test@gmail.com"] = "123456"

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/register", json={
            "username": "testuser",
            "email": "test@gmail.com",
            "password": "password123",
            "code": "123456"
        })
    
    assert response.status_code == 200
    assert response.json()["message"] == "User registered successfully."

@pytest.mark.asyncio
async def test_login_success():
    # Pre-populate user
    cursor = _KEEPALIVE_CONN.cursor()
    cursor.execute(
        "INSERT INTO users (username, email, password, is_banned) VALUES (?, ?, ?, ?)",
        ("loginuser", "login@gmail.com", "secret", 0)
    )
    _KEEPALIVE_CONN.commit()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/login", json={
            "username": "loginuser",
            "password": "secret"
        })
    
    assert response.status_code == 200
    assert response.json()["username"] == "loginuser"
    assert "user_id" in response.json()

@pytest.mark.asyncio
async def test_login_banned():
    # Pre-populate banned user
    cursor = _KEEPALIVE_CONN.cursor()
    cursor.execute(
        "INSERT INTO users (username, email, password, is_banned, ban_reason) VALUES (?, ?, ?, ?, ?)",
        ("banneduser", "banned@gmail.com", "secret", 1, "Cheating")
    )
    _KEEPALIVE_CONN.commit()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/login", json={
            "username": "banneduser",
            "password": "secret"
        })
    
    assert response.status_code == 403
    assert "suspended" in response.json()["detail"]["message"].lower()
    assert response.json()["detail"]["reason"] == "Cheating"


@pytest.mark.asyncio
async def test_ban_user_creates_admin_activity_log():
    cursor = _KEEPALIVE_CONN.cursor()
    cursor.execute(
        "INSERT INTO users (username, email, password, is_banned) VALUES (?, ?, ?, ?)",
        ("targetuser", "target@gmail.com", "secret", 0)
    )
    user_id = cursor.lastrowid
    _KEEPALIVE_CONN.commit()

    admin_sessions["test-admin-token"] = {
        "email": "admin@example.com",
        "expires_at": datetime.now() + timedelta(hours=1),
    }

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.put(
            f"/admin/users/{user_id}/ban",
            json={"reason": "Cheating"},
            headers={"Authorization": "Bearer test-admin-token"},
        )

    assert response.status_code == 200

    row = cursor.execute(
        "SELECT admin_email, action, target_user_id, details FROM admin_activity_logs"
    ).fetchone()
    assert row is not None
    assert row[0] == "admin@example.com"
    assert row[1] == "ban_user"
    assert row[2] == user_id
    assert json.loads(row[3]) == {"reason": "Cheating"}
