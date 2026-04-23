from fastapi import FastAPI, HTTPException, status, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import smtplib, random
from email.message import EmailMessage
import sqlite3
from datetime import date, timedelta

ADMIN_KEY = "tap_n_match_admin_2026" # Example hardcoded key

async def verify_admin(x_admin_key: str = Header(...)):
    if x_admin_key != ADMIN_KEY:
        raise HTTPException(status_code=401, detail="Invalid Admin Key")
    return x_admin_key

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SENDER_EMAIL = "jayshangodornes@gmail.com"
SENDER_PASSWORD = "pigp hsuz cawl rkqy"

pending_codes = {}

DEFAULT_THEME = "#A9A9A9"
DEFAULT_TAP_SOUND = "audio/tap_sounds/default_tapSounds.mp3"
DEFAULT_BG_MUSIC = "audio/background_music/stal_default.mp3"
MINECRAFT_BG_THEME = "asset:assets/background/minecraft_bgColor.jpg"
GENSHIN_TAP_SOUND = "audio/tap_sounds/genshin_tap_sound.mp3"
GENSHIN_BG_MUSIC = "audio/background_music/genshin_bgMusic.mp3"
MINECRAFT_TAP_SOUND = "audio/tap_sounds/minecraft_tap_sound.mp3"
MINECRAFT_BG_MUSIC = "audio/background_music/minecraft_bgMusic.mp3"
SNOWFALL_TAP_SOUND = "audio/tap_sounds/snowfall_tap_sound.mp3"
HARVEST_MOON_BG_MUSIC = "audio/background_music/harvestMoon.mp3"
SNOWFALL_BG_MUSIC = "audio/background_music/snowfall_bgMusic.mp3"
SNOWFALL_BG_THEME = "asset:assets/background/snowfall_background.jpeg"
WELCOME_TUTORIAL_ID = "welcome"
STANDARD_TUTORIAL_IDS = (
    "profile",
    "play",
    "daily_challenge",
    "shop",
    "leaderboards",
    "achievements",
    "themes",
    "support",
)
TUTORIAL_IDS = (WELCOME_TUTORIAL_ID, *STANDARD_TUTORIAL_IDS)

ACHIEVEMENT_CATALOG = [
    {
        "id": "first_match",
        "title": "First Match",
        "description": "Clear your first color pattern.",
        "metric": "levels_cleared",
        "target": 1,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Sky Blue",
        "reward_id": "#87CEEB",
        "icon": "emoji_events",
    },
    {
        "id": "getting_warmed_up",
        "title": "Getting Warmed Up",
        "description": "Clear 5 regular levels.",
        "metric": "levels_cleared",
        "target": 5,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Forest Green",
        "reward_id": "#228B22",
        "icon": "local_fire_department",
    },
    {
        "id": "pattern_pro",
        "title": "Pattern Pro",
        "description": "Clear 25 regular levels.",
        "metric": "levels_cleared",
        "target": 25,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Deep Purple",
        "reward_id": "#301934",
        "icon": "grid_view",
    },
    {
        "id": "quick_fingers",
        "title": "Quick Fingers",
        "description": "Beat a level with at least 5 seconds left.",
        "metric": "fast_finishes",
        "target": 1,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Bolt Yellow",
        "reward_id": "#FFD700",
        "icon": "bolt",
    },
    {
        "id": "daily_starter",
        "title": "Daily Starter",
        "description": "Complete your first daily challenge.",
        "metric": "completed_daily_challenges",
        "target": 1,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Sunset Orange",
        "reward_id": "#FF4500",
        "icon": "calendar_today",
    },
    {
        "id": "three_day_streak",
        "title": "3-Day Streak",
        "description": "Complete daily challenges on 3 straight days.",
        "metric": "streak",
        "target": 3,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Crimson Red",
        "reward_id": "#DC143C",
        "icon": "whatshot",
    },
    {
        "id": "seven_day_streak",
        "title": "7-Day Streak",
        "description": "Reach a 7-day daily challenge streak.",
        "metric": "streak",
        "target": 7,
        "reward_type": "tap_sound",
        "reward_label": "Tap Sound",
        "reward_name": "Genshin Tap",
        "reward_id": GENSHIN_TAP_SOUND,
        "icon": "workspace_premium",
    },
    {
        "id": "theme_hunter",
        "title": "Theme Hunter",
        "description": "Unlock 3 background themes.",
        "metric": "unlocked_themes_count",
        "target": 3,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Collector Cyan",
        "reward_id": "#00FFFF",
        "icon": "palette",
    },
    {
        "id": "palette_collector",
        "title": "Palette Collector",
        "description": "Unlock 7 background themes.",
        "metric": "unlocked_themes_count",
        "target": 7,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Royal Gold",
        "reward_id": "#FFD700",
        "icon": "color_lens",
    },
    {
        "id": "perfect_finish",
        "title": "Perfect Finish",
        "description": "Clear a level with a perfect run.",
        "metric": "perfect_finishes",
        "target": 1,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Perfect White",
        "reward_id": "#F8F8FF",
        "icon": "verified",
    },
    {
        "id": "normal_mode_complete",
        "title": "Normal Conqueror",
        "description": "Reach Level 50 and finish the Normal difficulty tier.",
        "metric": "highest_level",
        "target": 50,
        "reward_type": "theme",
        "reward_label": "Background",
        "reward_name": "Minecraft Grass",
        "reward_id": MINECRAFT_BG_THEME,
        "icon": "image",
    },
    {
        "id": "extreme_five",
        "title": "Extreme Crafter",
        "description": "Complete 5 Extreme difficulty levels.",
        "metric": "extreme_clears",
        "target": 5,
        "reward_type": "tap_sound",
        "reward_label": "Tap Sound",
        "reward_name": "Minecraft Tap",
        "reward_id": MINECRAFT_TAP_SOUND,
        "icon": "sports_esports",
    },
    {
        "id": "daily_challenge_complete",
        "title": "Daily Challenger",
        "description": "Complete all 7 newbie daily challenges.",
        "metric": "completed_daily_challenges",
        "target": 7,
        "reward_type": "bg_music",
        "reward_label": "Music",
        "reward_name": "Genshin BGM",
        "reward_id": GENSHIN_BG_MUSIC,
        "icon": "music_note",
    },
    {
        "id": "score_2500",
        "title": "Blockbuster Score",
        "description": "Reach 2500 total score.",
        "metric": "total_score",
        "target": 2500,
        "reward_type": "bg_music",
        "reward_label": "Music",
        "reward_name": "Minecraft BGM",
        "reward_id": MINECRAFT_BG_MUSIC,
        "icon": "album",
    },
    {
        "id": "score_5000",
        "title": "Elite Scorer",
        "description": "Reach a total score of 5000.",
        "metric": "total_score",
        "target": 5000,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Electric Purple",
        "reward_id": "#BF00FF",
        "icon": "auto_awesome",
    },
    {
        "id": "score_10000",
        "title": "Legendary Scorer",
        "description": "Reach a total score of 10,000.",
        "metric": "total_score",
        "target": 10000,
        "reward_type": "bg_music",
        "reward_label": "Music",
        "reward_name": "Harvest Moon BGM",
        "reward_id": HARVEST_MOON_BG_MUSIC,
        "icon": "stars",
    },
    {
        "id": "high_score_500",
        "title": "High Roller",
        "description": "Achieve a single-run high score of 500.",
        "metric": "highest_score",
        "target": 500,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Maroon Velvet",
        "reward_id": "#800000",
        "icon": "trending_up",
    },
    {
        "id": "high_score_1000",
        "title": "Grand Master",
        "description": "Achieve a single-run high score of 1000.",
        "metric": "highest_score",
        "target": 1000,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Midnight Blue",
        "reward_id": "#191970",
        "icon": "diamond",
    },
    {
        "id": "boxes_1000",
        "title": "Finger Workout",
        "description": "Tap a total of 1000 boxes.",
        "metric": "boxes_tapped",
        "target": 1000,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Coral Reef",
        "reward_id": "#FF7F50",
        "icon": "ads_click",
    },
    {
        "id": "boxes_5000",
        "title": "Master Tapper",
        "description": "Tap a total of 5000 boxes.",
        "metric": "boxes_tapped",
        "target": 5000,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Turquoise Dream",
        "reward_id": "#40E0D0",
        "icon": "touch_app",
    },
    {
        "id": "level_100",
        "title": "Century Club",
        "description": "Reach Level 100.",
        "metric": "highest_level",
        "target": 100,
        "reward_type": "bg_music",
        "reward_label": "Music",
        "reward_name": "Snowfall BGM",
        "reward_id": SNOWFALL_BG_MUSIC,
        "icon": "military_tech",
    },
    {
        "id": "extreme_15",
        "title": "Extreme Veteran",
        "description": "Complete 15 Extreme difficulty levels.",
        "metric": "extreme_clears",
        "target": 15,
        "reward_type": "theme",
        "reward_label": "Background",
        "reward_name": "Snowfall",
        "reward_id": SNOWFALL_BG_THEME,
        "icon": "ac_unit",
    },
    {
        "id": "streak_14",
        "title": "Two-Week Streak",
        "description": "Maintain a 14-day daily challenge streak.",
        "metric": "streak",
        "target": 14,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Emerald Green",
        "reward_id": "#50C878",
        "icon": "event_available",
    },
    {
        "id": "streak_30",
        "title": "Monthly Devotion",
        "description": "Maintain a 30-day daily challenge streak.",
        "metric": "streak",
        "target": 30,
        "reward_type": "tap_sound",
        "reward_label": "Tap Sound",
        "reward_name": "Snowfall Tap",
        "reward_id": SNOWFALL_TAP_SOUND,
        "icon": "history",
    },
    {
        "id": "daily_25",
        "title": "Challenge Pro",
        "description": "Complete 25 daily challenges.",
        "metric": "completed_daily_challenges",
        "target": 25,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Hot Pink",
        "reward_id": "#FF69B4",
        "icon": "task_alt",
    },
    {
        "id": "speed_demon_expert",
        "title": "Expert Speedster",
        "description": "Get 50 fast finish bonuses.",
        "metric": "fast_finishes",
        "target": 50,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Neon Green",
        "reward_id": "#39FF14",
        "icon": "speed",
    },
    {
        "id": "flawless_10",
        "title": "Flawless Ten",
        "description": "Complete 10 levels with a perfect run.",
        "metric": "perfect_finishes",
        "target": 10,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Pearl White",
        "reward_id": "#E0E0E0",
        "icon": "verified_user",
    },
    {
        "id": "theme_hoarder",
        "title": "Theme Hoarder",
        "description": "Unlock 15 different themes.",
        "metric": "unlocked_themes_count",
        "target": 15,
        "reward_type": "theme",
        "reward_label": "Theme",
        "reward_name": "Rainbow Prism",
        "reward_id": "#A020F0",
        "icon": "collections",
    },
]

# --- Updated Database Init ---
def init_db():
    conn = sqlite3.connect("users.db")
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

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reporter_id INTEGER,
            reported_id INTEGER,
            reason TEXT,
            timestamp TEXT,
            status TEXT DEFAULT 'Pending'
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS appeals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            appeal_text TEXT,
            status TEXT DEFAULT 'Pending',
            timestamp TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS support_tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            type TEXT,
            message TEXT,
            status TEXT DEFAULT 'Open',
            timestamp TEXT
        )
    """)
    
    # Try adding new columns to existing DBs safely
    columns_to_add = [
        ("unlocked_themes", "TEXT DEFAULT ''"),
        ("streak", "INTEGER DEFAULT 0"),
        ("last_challenge_date", "TEXT"),
        ("created_at", "TEXT"),
        ("daily_attempts", "INTEGER DEFAULT 0"),
        ("last_attempt_date", "TEXT"),
        ("selected_theme", "TEXT DEFAULT '#A9A9A9'"),
        ("last_username_change_date", "TEXT"),
        ("profile_picture", "TEXT DEFAULT ''"),
        ("total_score", "INTEGER DEFAULT 0"),
        ("highest_score", "INTEGER DEFAULT 0"),
        ("highest_level", "INTEGER DEFAULT 0"),
        ("levels_cleared", "INTEGER DEFAULT 0"),
        ("fast_finishes", "INTEGER DEFAULT 0"),
        ("perfect_finishes", "INTEGER DEFAULT 0"),
        ("boxes_tapped", "INTEGER DEFAULT 0"),
        ("completed_daily_challenges", "INTEGER DEFAULT 0"),
        ("extreme_clears", "INTEGER DEFAULT 0"),
        ("banked_points", "INTEGER DEFAULT 0"),
        ("lifetime_points", "INTEGER DEFAULT 0"),
        ("unlocked_tap_sounds", f"TEXT DEFAULT '{DEFAULT_TAP_SOUND}'"),
        ("selected_tap_sound", f"TEXT DEFAULT '{DEFAULT_TAP_SOUND}'"),
        ("unlocked_bg_music", f"TEXT DEFAULT '{DEFAULT_BG_MUSIC}'"),
        ("selected_bg_music", f"TEXT DEFAULT '{DEFAULT_BG_MUSIC}'"),
        ("tap_sound_enabled", "INTEGER DEFAULT 1"),
        ("bg_music_enabled", "INTEGER DEFAULT 1"),
        ("tap_volume", "REAL DEFAULT 1.0"),
        ("bg_volume", "REAL DEFAULT 0.5"),
        ("is_banned", "INTEGER DEFAULT 0"),
        ("ban_reason", "TEXT"),
        ("claimed_rewards", "TEXT DEFAULT ''"),
        ("seen_rewards", "TEXT DEFAULT ''"),
        ("tutorial_enabled", "INTEGER DEFAULT 0"),
        ("completed_tutorials", "TEXT DEFAULT ''"),
    ]
    for col_name, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
        except sqlite3.OperationalError as e:
            if "duplicate column name" not in str(e).lower():
                print(f"[ERROR] Could not add {col_name} column: {e}")

    cursor.execute(
        "UPDATE users SET unlocked_tap_sounds = ? WHERE unlocked_tap_sounds IS NULL OR TRIM(unlocked_tap_sounds) = ''",
        (DEFAULT_TAP_SOUND,),
    )
    cursor.execute(
        "UPDATE users SET selected_tap_sound = ? WHERE selected_tap_sound IS NULL OR TRIM(selected_tap_sound) = ''",
        (DEFAULT_TAP_SOUND,),
    )
    cursor.execute(
        "UPDATE users SET unlocked_bg_music = ? WHERE unlocked_bg_music IS NULL OR TRIM(unlocked_bg_music) = ''",
        (DEFAULT_BG_MUSIC,),
    )
    cursor.execute(
        "UPDATE users SET selected_bg_music = ? WHERE selected_bg_music IS NULL OR TRIM(selected_bg_music) = ''",
        (DEFAULT_BG_MUSIC,),
    )
    cursor.execute(
        "UPDATE users SET claimed_rewards = '' WHERE claimed_rewards IS NULL"
    )
    conn.commit()
    conn.close()

init_db()

# --- Pydantic Models ---
class EmailRequest(BaseModel):
    email: str

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    code: str

class LoginRequest(BaseModel):
    username: str
    password: str

class LevelCompletionRequest(BaseModel):
    level: int
    difficulty: str
    seconds_left: int
    used_done_button: bool
    perfect_run: bool
    boxes_tapped: int = 0
    run_score_before_level: int = 0


class UsernameUpdateRequest(BaseModel):
    username: str


class PasswordUpdateRequest(BaseModel):
    password: str


class EmailUpdateRequest(BaseModel):
    email: str


class ProfilePictureUpdateRequest(BaseModel):
    profile_picture: str


class UserSettingsUpdateRequest(BaseModel):
    tap_sound_enabled: bool
    bg_music_enabled: bool
    tap_volume: float
    bg_volume: float
    colorblind_mode: bool


def split_csv(raw_value: str | None) -> list[str]:
    if not raw_value:
        return []
    return [item.strip() for item in raw_value.split(",") if item.strip()]


def join_csv(values: list[str]) -> str:
    unique_values = list(dict.fromkeys(value.strip() for value in values if value and value.strip()))
    return ",".join(unique_values)


def count_unlocked_themes(unlocked_themes: str | None) -> int:
    return len(split_csv(unlocked_themes))


def build_reward_inventory(user_row: sqlite3.Row) -> dict:
    keys = set(user_row.keys())
    return {
        "themes": split_csv(user_row["unlocked_themes"]) if "unlocked_themes" in keys else [],
        "tap_sounds": split_csv(user_row["unlocked_tap_sounds"]) if "unlocked_tap_sounds" in keys else [DEFAULT_TAP_SOUND],
        "bg_music": split_csv(user_row["unlocked_bg_music"]) if "unlocked_bg_music" in keys else [DEFAULT_BG_MUSIC],
        "claimed_rewards": split_csv(user_row["claimed_rewards"]) if "claimed_rewards" in keys else [],
    }


def get_int_value(user_row: sqlite3.Row, key: str) -> int:
    keys = set(user_row.keys())
    if key not in keys or user_row[key] is None:
        return 0
    return int(user_row[key])


def is_fresh_account(user_row: sqlite3.Row) -> bool:
    return (
        get_int_value(user_row, "total_score") == 0
        and get_int_value(user_row, "highest_score") == 0
        and get_int_value(user_row, "highest_level") == 0
        and get_int_value(user_row, "levels_cleared") == 0
        and get_int_value(user_row, "boxes_tapped") == 0
        and get_int_value(user_row, "completed_daily_challenges") == 0
    )


def get_applicable_tutorial_ids(user_row: sqlite3.Row) -> list[str]:
    tutorial_ids = list(STANDARD_TUTORIAL_IDS)
    if is_fresh_account(user_row):
        tutorial_ids.insert(0, WELCOME_TUTORIAL_ID)
    return tutorial_ids


def build_tutorial_state(user_row: sqlite3.Row) -> dict:
    keys = set(user_row.keys())
    tutorial_enabled = bool(user_row["tutorial_enabled"]) if "tutorial_enabled" in keys else False
    completed_tutorials = split_csv(user_row["completed_tutorials"]) if "completed_tutorials" in keys else []
    pending_tutorials = [
        tutorial_id
        for tutorial_id in get_applicable_tutorial_ids(user_row)
        if tutorial_enabled and tutorial_id not in completed_tutorials
    ]
    return {
        "tutorial_enabled": tutorial_enabled,
        "completed_tutorials": completed_tutorials,
        "pending_tutorials": pending_tutorials,
        "has_pending_tutorials": bool(pending_tutorials),
    }


def evaluate_achievements(user_row: sqlite3.Row) -> dict:
    keys = set(user_row.keys())
    def get_value(key: str, default: int = 0):
        return user_row[key] if key in keys and user_row[key] is not None else default

    inventory = build_reward_inventory(user_row)
    claimed_rewards = set(inventory["claimed_rewards"])
    metrics = {
        "levels_cleared": get_value("levels_cleared"),
        "fast_finishes": get_value("fast_finishes"),
        "perfect_finishes": get_value("perfect_finishes"),
        "streak": get_value("streak"),
        "completed_daily_challenges": get_value("completed_daily_challenges"),
        "highest_level": get_value("highest_level"),
        "extreme_clears": get_value("extreme_clears"),
        "total_score": get_value("total_score"),
        "highest_score": get_value("highest_score"),
        "boxes_tapped": get_value("boxes_tapped"),
        "unlocked_themes_count": count_unlocked_themes(user_row["unlocked_themes"]) if "unlocked_themes" in keys else 0,
    }

    achievements = []
    unlocked_count = 0
    claimable_count = 0

    for achievement in ACHIEVEMENT_CATALOG:
        current_value = metrics.get(achievement["metric"], 0)
        is_unlocked = current_value >= achievement["target"]
        has_reward = achievement.get("reward_type") is not None
        is_claimed = achievement["id"] in claimed_rewards if has_reward else False
        can_claim = bool(is_unlocked and has_reward and not is_claimed)
        unlocked_count += 1 if is_unlocked else 0
        claimable_count += 1 if can_claim else 0

        achievements.append({
            "id": achievement["id"],
            "title": achievement["title"],
            "description": achievement["description"],
            "icon": achievement["icon"],
            "reward_type": achievement.get("reward_type"),
            "reward_label": achievement.get("reward_label"),
            "reward_name": achievement.get("reward_name"),
            "reward_id": achievement.get("reward_id"),
            "target": achievement["target"],
            "current_value": current_value,
            "progress": min(current_value / achievement["target"], 1.0) if achievement["target"] > 0 else 0.0,
            "is_unlocked": is_unlocked,
            "is_claimed": is_claimed,
            "can_claim": can_claim,
        })

    return {
        "achievements": achievements,
        "achievement_count": unlocked_count,
        "achievement_total_count": len(ACHIEVEMENT_CATALOG),
        "claimable_reward_count": claimable_count,
        "has_claimable_rewards": claimable_count > 0,
    }


def calculate_achievement_count(user_row: sqlite3.Row) -> int:
    return evaluate_achievements(user_row)["achievement_count"]


def build_user_payload(user_row: sqlite3.Row) -> dict:
    user_dict = dict(user_row)
    achievement_state = evaluate_achievements(user_row)
    inventory = build_reward_inventory(user_row)
    tutorial_state = build_tutorial_state(user_row)
    user_dict["unlocked_themes"] = inventory["themes"]
    user_dict["unlocked_tap_sounds"] = inventory["tap_sounds"]
    user_dict["unlocked_bg_music"] = inventory["bg_music"]
    user_dict["claimed_rewards"] = inventory["claimed_rewards"]
    
    # User settings
    user_dict["tap_sound_enabled"] = bool(user_row["tap_sound_enabled"]) if "tap_sound_enabled" in user_dict else True
    user_dict["bg_music_enabled"] = bool(user_row["bg_music_enabled"]) if "bg_music_enabled" in user_dict else True
    user_dict["tap_volume"] = user_row["tap_volume"] if "tap_volume" in user_dict else 1.0
    user_dict["bg_volume"] = user_row["bg_volume"] if "bg_volume" in user_dict else 0.5
    user_dict["colorblind_mode"] = bool(user_row["colorblind_mode"]) if "colorblind_mode" in user_dict else False

    user_dict.update(achievement_state)
    user_dict.update(tutorial_state)
    return user_dict


def get_base_score(difficulty: str) -> int:
    normalized = difficulty.strip().lower()
    score_map = {
        "easy": 10,
        "normal": 20,
        "hard": 30,
        "extreme": 50,
    }
    if normalized not in score_map:
        raise HTTPException(status_code=400, detail="Invalid difficulty")
    return score_map[normalized]


def calculate_level_score(request: LevelCompletionRequest) -> dict:
    base_score = get_base_score(request.difficulty)
    fast_bonus_thresholds = {
        "easy": 5,
        "normal": 7,
        "hard": 12,
        "extreme": 18,
    }
    normalized = request.difficulty.strip().lower()
    fast_bonus = 5 if request.seconds_left > fast_bonus_thresholds[normalized] else 0
    perfect_bonus = 5 if request.perfect_run else 0
    total_earned = base_score + fast_bonus + perfect_bonus
    return {
        "base_score": base_score,
        "fast_bonus": fast_bonus,
        "perfect_bonus": perfect_bonus,
        "total_earned": total_earned,
    }

# --- Endpoints ---

@app.post("/send-code")
async def send_code(request: EmailRequest):
    code = str(random.randint(100000, 999999))
    pending_codes[request.email] = code
    msg = EmailMessage()
    msg.set_content(f"Your verification code is: {code}")
    msg["Subject"] = "Tap & Match - Verification Code"
    msg["From"] = SENDER_EMAIL
    msg["To"] = request.email

    try:
        print(f"[DEBUG] Generated code for {request.email}: {code}")
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.send_message(msg)
        server.quit()
    except Exception as e:
        print(f"[WARNING] Could not send email. Code: {code}")

    return {"message": "Code sent successfully"}

@app.post("/register")
async def register(request: RegisterRequest):
    if request.email not in pending_codes or pending_codes[request.email] != request.code:
        raise HTTPException(status_code=400, detail="Invalid code.")

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    today = date.today().isoformat()
    try:
        cursor.execute(
            """
            INSERT INTO users (
                username,
                email,
                password,
                created_at,
                tutorial_enabled,
                completed_tutorials
            )
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (request.username, request.email, request.password, today, 1, ""),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Username or email exists.")
    finally:
        conn.close()

    pending_codes.pop(request.email, None)
    return {"message": "User registered successfully."}

@app.post("/login")
async def login(request: LoginRequest):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", 
                   (request.username, request.password))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if user["is_banned"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail={
                "message": "Your account has been suspended.",
                "reason": user["ban_reason"]
            }
        )

    # In a real app, return a token. For now, we return user info.
    return {"message": "Login successful", "user_id": user["id"], "username": user["username"]}

# --- NEW: Get User Info for Theme/Streak Logic ---
# --- NEW: Fix Database for Existing Users ---
@app.get("/fix-database")
async def fix_database():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    # Fix existing users with problematic unlocked_themes
    cursor.execute('UPDATE users SET unlocked_themes = "" WHERE unlocked_themes = "#FFFFFF"')
    conn.commit()
    
    # Check results
    cursor.execute('SELECT id, username, unlocked_themes, streak FROM users')
    users = cursor.fetchall()
    conn.close()
    
    return {"message": "Database fixed!", "users": users}

@app.get("/fix1")
async def fix1():
    import sqlite3
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("INSERT OR IGNORE INTO users (id, username, email, password, created_at) VALUES (1, 'demo', 'demo@demo.com', 'pass', '2023-01-01')")
    conn.commit()
    conn.close()
    return {"status": "fixed"}

@app.get("/users/{user_id}")
async def get_user_info(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute(
        """
        SELECT *
        FROM users
        WHERE id = ?
        """,
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user_dict = build_user_payload(user)
    today = date.today().isoformat()

    # Reset daily attempts if it's a new day
    if user_dict["last_attempt_date"] != today:
        user_dict["daily_attempts"] = 0

    return user_dict


@app.put("/tutorials/{user_id}/{tutorial_id}/complete")
async def complete_tutorial(user_id: int, tutorial_id: str):
    normalized_tutorial_id = tutorial_id.strip().lower()
    if normalized_tutorial_id not in TUTORIAL_IDS:
        raise HTTPException(status_code=400, detail="Unknown tutorial.")

    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    completed_tutorials = split_csv(user["completed_tutorials"])
    if normalized_tutorial_id not in completed_tutorials:
        completed_tutorials.append(normalized_tutorial_id)

    applicable_tutorial_ids = get_applicable_tutorial_ids(user)
    is_all_done = all(tutorial in completed_tutorials for tutorial in applicable_tutorial_ids)
    tutorial_enabled = 0 if is_all_done else 1

    cursor.execute(
        """
        UPDATE users
        SET tutorial_enabled = ?, completed_tutorials = ?
        WHERE id = ?
        """,
        (tutorial_enabled, join_csv(completed_tutorials), user_id),
    )
    conn.commit()

    updated_user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    return {
        "status": "success",
        "tutorial_id": normalized_tutorial_id,
        **build_tutorial_state(updated_user),
    }


@app.get("/public-users/{user_id}")
async def get_public_user_info(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute(
        """
        SELECT *
        FROM users
        WHERE id = ?
        """,
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user_dict = build_user_payload(user)
    today = date.today().isoformat()
    if user_dict["last_attempt_date"] != today:
        user_dict["daily_attempts"] = 0

    return user_dict


@app.put("/complete-level/{user_id}")
async def complete_level(user_id: int, request: LevelCompletionRequest):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute(
        """
        SELECT *
        FROM users
        WHERE id = ?
        """,
        (user_id,),
    ).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    score_breakdown = calculate_level_score(request)
    current_total_score = user["total_score"] or 0
    current_highest_score = user["highest_score"] or 0
    current_highest_level = user["highest_level"] or 0
    current_levels_cleared = user["levels_cleared"] or 0
    current_fast_finishes = user["fast_finishes"] or 0
    current_perfect_finishes = user["perfect_finishes"] or 0
    current_boxes_tapped = user["boxes_tapped"] or 0
    current_extreme_clears = user["extreme_clears"] or 0

    new_total_score = current_total_score + score_breakdown["total_earned"]
    new_banked_points = (user["banked_points"] or 0) + score_breakdown["total_earned"]
    new_lifetime_points = (user["lifetime_points"] or 0) + score_breakdown["total_earned"]
    new_run_score = max(request.run_score_before_level, 0) + score_breakdown["total_earned"]
    new_highest_score = max(current_highest_score, new_run_score)
    new_highest_level = max(current_highest_level, request.level)
    new_levels_cleared = current_levels_cleared + 1
    new_fast_finishes = current_fast_finishes + (1 if score_breakdown["fast_bonus"] > 0 else 0)
    new_perfect_finishes = current_perfect_finishes + (1 if score_breakdown["perfect_bonus"] > 0 else 0)
    new_boxes_tapped = current_boxes_tapped + max(request.boxes_tapped, 0)
    new_extreme_clears = current_extreme_clears + (1 if request.difficulty.strip().lower() == "extreme" else 0)

    cursor.execute(
        """
        UPDATE users
        SET total_score = ?, highest_score = ?, highest_level = ?, levels_cleared = ?,
            fast_finishes = ?, perfect_finishes = ?, boxes_tapped = ?, extreme_clears = ?,
            banked_points = ?, lifetime_points = ?
        WHERE id = ?
        """,
        (
            new_total_score,
            new_highest_score,
            new_highest_level,
            new_levels_cleared,
            new_fast_finishes,
            new_perfect_finishes,
            new_boxes_tapped,
            new_extreme_clears,
            new_banked_points,
            new_lifetime_points,
            user_id,
        ),
    )
    conn.commit()

    updated_user = cursor.execute(
        """
        SELECT *
        FROM users
        WHERE id = ?
        """,
        (user_id,),
    ).fetchone()
    conn.close()

    return {
        "status": "success",
        "score_breakdown": score_breakdown,
        "total_score": new_total_score,
        "banked_points": new_banked_points,
        "lifetime_points": new_lifetime_points,
        "highest_score": new_highest_score,
        "highest_level": new_highest_level,
        "boxes_tapped": new_boxes_tapped,
        "achievement_count": calculate_achievement_count(updated_user),
        "claimable_reward_count": evaluate_achievements(updated_user)["claimable_reward_count"],
    }


@app.get("/leaderboards")
async def get_leaderboards():
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    rows = cursor.execute(
        """
        SELECT id, username, unlocked_themes, selected_theme, highest_score, highest_level, streak,
               last_challenge_date, levels_cleared, fast_finishes, perfect_finishes, lifetime_points
        FROM users
        WHERE is_banned = 0
        ORDER BY lifetime_points DESC, highest_score DESC, highest_level DESC, username COLLATE NOCASE ASC
        """
    ).fetchall()
    conn.close()

    leaderboard = []
    for index, row in enumerate(rows, start=1):
        leaderboard.append({
            "rank": index,
            "user_id": row["id"],
            "username": row["username"],
            "selected_theme": row["selected_theme"],
            "score": row["lifetime_points"],
            "highest_level": row["highest_level"],
            "achievement_count": calculate_achievement_count(row),
        })

    return {"players": leaderboard}

class BuyItemRequest(BaseModel):
    item_id: str
    item_type: str # 'theme', 'tap_sound', 'bg_music'
    price: int

@app.post("/buy-item/{user_id}")
async def buy_item(user_id: int, request: BuyItemRequest):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
        
    current_banked = user["banked_points"] or 0
    if current_banked < request.price:
        conn.close()
        raise HTTPException(status_code=400, detail="Insufficient points")
        
    # Add to inventory
    inventory_col = {
        "theme": "unlocked_themes",
        "tap_sound": "unlocked_tap_sounds",
        "bg_music": "unlocked_bg_music"
    }.get(request.item_type)
    
    if not inventory_col:
        conn.close()
        raise HTTPException(status_code=400, detail="Invalid item type")
        
    unlocked_items = split_csv(user[inventory_col])
    if request.item_id in unlocked_items:
        conn.close()
        raise HTTPException(status_code=400, detail="Item already unlocked")
        
    unlocked_items.append(request.item_id)
    new_inventory = join_csv(unlocked_items)
    new_banked = current_banked - request.price
    
    cursor.execute(f"UPDATE users SET {inventory_col} = ?, banked_points = ? WHERE id = ?", 
                   (new_inventory, new_banked, user_id))
    conn.commit()
    conn.close()
    
    return {"status": "success", "banked_points": new_banked}


@app.put("/update-username/{user_id}")
async def update_username(user_id: int, request: UsernameUpdateRequest):
    new_username = request.username.strip()
    if not new_username:
        raise HTTPException(status_code=400, detail="Username cannot be empty.")

    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute(
        "SELECT id, last_username_change_date FROM users WHERE id = ?",
        (user_id,),
    ).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    duplicate = cursor.execute(
        "SELECT id FROM users WHERE username = ? AND id != ?",
        (new_username, user_id),
    ).fetchone()
    if duplicate:
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists.")

    last_change = user["last_username_change_date"]
    if last_change:
        try:
            last_change_date = date.fromisoformat(last_change)
            next_allowed = last_change_date + timedelta(days=30)
            if date.today() < next_allowed:
                conn.close()
                raise HTTPException(
                    status_code=400,
                    detail=f"Username can only be changed once every 30 days. Try again on {next_allowed.isoformat()}.",
                )
        except ValueError:
            pass

    today = date.today().isoformat()
    cursor.execute(
        "UPDATE users SET username = ?, last_username_change_date = ? WHERE id = ?",
        (new_username, today, user_id),
    )
    conn.commit()
    conn.close()

    return {"status": "success", "username": new_username, "last_username_change_date": today}


@app.put("/update-password/{user_id}")
async def update_password(user_id: int, request: PasswordUpdateRequest):
    new_password = request.password.strip()
    if not new_password:
        raise HTTPException(status_code=400, detail="Password cannot be empty.")

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    cursor.execute("UPDATE users SET password = ? WHERE id = ?", (new_password, user_id))
    conn.commit()
    conn.close()
    return {"status": "success"}


@app.put("/update-email/{user_id}")
async def update_email(user_id: int, request: EmailUpdateRequest):
    new_email = request.email.strip()
    if not new_email:
        raise HTTPException(status_code=400, detail="Email cannot be empty.")

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    duplicate = cursor.execute(
        "SELECT id FROM users WHERE email = ? AND id != ?",
        (new_email, user_id),
    ).fetchone()
    if duplicate:
        conn.close()
        raise HTTPException(status_code=400, detail="Email already exists.")

    cursor.execute("UPDATE users SET email = ? WHERE id = ?", (new_email, user_id))
    conn.commit()
    conn.close()
    return {"status": "success", "email": new_email}


@app.put("/update-profile-picture/{user_id}")
async def update_profile_picture(user_id: int, request: ProfilePictureUpdateRequest):
    profile_picture = request.profile_picture.strip()
    if not profile_picture:
        raise HTTPException(status_code=400, detail="Profile picture cannot be empty.")

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    cursor.execute("UPDATE users SET profile_picture = ? WHERE id = ?", (profile_picture, user_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Profile picture updated."}


@app.put("/update-user-settings/{user_id}")
async def update_user_settings(user_id: int, request: UserSettingsUpdateRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    cursor.execute(
        """
        UPDATE users
        SET tap_sound_enabled = ?,
            bg_music_enabled = ?,
            tap_volume = ?,
            bg_volume = ?,
            colorblind_mode = ?
        WHERE id = ?
        """,
        (
            1 if request.tap_sound_enabled else 0,
            1 if request.bg_music_enabled else 0,
            request.tap_volume,
            request.bg_volume,
            1 if request.colorblind_mode else 0,
            user_id,
        ),
    )
    conn.commit()
    conn.close()
    return {"status": "success"}


@app.post("/reset-account/{user_id}")
async def reset_account(user_id: int):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    cursor.execute(
        """
        UPDATE users
        SET unlocked_themes = '',
            selected_theme = ?,
            streak = 0,
            last_challenge_date = NULL,
            daily_attempts = 0,
            last_attempt_date = NULL,
            total_score = 0,
            highest_score = 0,
            highest_level = 0,
            levels_cleared = 0,
            fast_finishes = 0,
            perfect_finishes = 0,
            boxes_tapped = 0,
            completed_daily_challenges = 0,
            extreme_clears = 0,
            unlocked_tap_sounds = ?,
            selected_tap_sound = ?,
            unlocked_bg_music = ?,
            selected_bg_music = ?,
            claimed_rewards = '',
            tutorial_enabled = 1,
            completed_tutorials = ''
        WHERE id = ?
        """,
        (DEFAULT_THEME, DEFAULT_TAP_SOUND, DEFAULT_TAP_SOUND, DEFAULT_BG_MUSIC, DEFAULT_BG_MUSIC, user_id),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Account progress reset."}

@app.put("/select-theme/{user_id}")
async def select_theme(user_id: int, theme_color: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute("SELECT unlocked_themes FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    unlocked_themes = split_csv(user["unlocked_themes"])
    if theme_color != DEFAULT_THEME and theme_color not in unlocked_themes:
        conn.close()
        raise HTTPException(status_code=400, detail="Theme is not unlocked")

    cursor.execute("UPDATE users SET selected_theme = ? WHERE id = ?", (theme_color, user_id))
    conn.commit()
    conn.close()

    return {"status": "success", "selected_theme": theme_color}


@app.put("/select-tap-sound/{user_id}")
async def select_tap_sound(user_id: int, asset_path: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute("SELECT unlocked_tap_sounds FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    unlocked_sounds = split_csv(user["unlocked_tap_sounds"])
    if asset_path not in unlocked_sounds:
        conn.close()
        raise HTTPException(status_code=400, detail="Tap sound is not unlocked")

    cursor.execute("UPDATE users SET selected_tap_sound = ? WHERE id = ?", (asset_path, user_id))
    conn.commit()
    conn.close()
    return {"status": "success", "selected_tap_sound": asset_path}


@app.put("/select-bg-music/{user_id}")
async def select_bg_music(user_id: int, asset_path: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute("SELECT unlocked_bg_music FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    unlocked_tracks = split_csv(user["unlocked_bg_music"])
    if asset_path not in unlocked_tracks:
        conn.close()
        raise HTTPException(status_code=400, detail="Background music is not unlocked")

    cursor.execute("UPDATE users SET selected_bg_music = ? WHERE id = ?", (asset_path, user_id))
    conn.commit()
    conn.close()
    return {"status": "success", "selected_bg_music": asset_path}


@app.get("/achievements/{user_id}")
async def get_achievements(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return evaluate_achievements(user)


@app.post("/claim-achievement/{user_id}/{achievement_id}")
async def claim_achievement(user_id: int, achievement_id: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    achievement_state = evaluate_achievements(user)
    achievement = next((item for item in achievement_state["achievements"] if item["id"] == achievement_id), None)
    if not achievement:
        conn.close()
        raise HTTPException(status_code=404, detail="Achievement not found")
    if not achievement["can_claim"]:
        conn.close()
        raise HTTPException(status_code=400, detail="Achievement reward is not claimable")

    claimed_rewards = split_csv(user["claimed_rewards"])
    claimed_rewards.append(achievement_id)
    unlocked_themes = split_csv(user["unlocked_themes"])
    unlocked_tap_sounds = split_csv(user["unlocked_tap_sounds"])
    unlocked_bg_music = split_csv(user["unlocked_bg_music"])

    reward_type = achievement["reward_type"]
    reward_id = achievement["reward_id"]
    if reward_type == "theme":
        unlocked_themes.append(reward_id)
    elif reward_type == "tap_sound":
        unlocked_tap_sounds.append(reward_id)
    elif reward_type == "bg_music":
        unlocked_bg_music.append(reward_id)

    cursor.execute(
        """
        UPDATE users
        SET unlocked_themes = ?, unlocked_tap_sounds = ?, unlocked_bg_music = ?, claimed_rewards = ?
        WHERE id = ?
        """,
        (
            join_csv(unlocked_themes),
            join_csv(unlocked_tap_sounds),
            join_csv(unlocked_bg_music),
            join_csv(claimed_rewards),
            user_id,
        ),
    )
    conn.commit()

    updated_user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    updated_state = evaluate_achievements(updated_user)

    return {
        "status": "success",
        "achievement_id": achievement_id,
        "reward_type": reward_type,
        "reward_id": reward_id,
        "reward_name": achievement["reward_name"],
        "claimable_reward_count": updated_state["claimable_reward_count"],
        "has_claimable_rewards": updated_state["has_claimable_rewards"],
        "unlocked_themes": split_csv(updated_user["unlocked_themes"]),
        "unlocked_tap_sounds": split_csv(updated_user["unlocked_tap_sounds"]),
        "unlocked_bg_music": split_csv(updated_user["unlocked_bg_music"]),
    }

@app.post("/record-attempt/{user_id}")
async def record_attempt(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute("SELECT daily_attempts, last_attempt_date FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    today = date.today().isoformat()
    attempts = user['daily_attempts']
    
    if user['last_attempt_date'] != today:
        attempts = 0
    
    if attempts >= 2:
        conn.close()
        return {"status": "limit_reached", "message": "You have already played twice today!"}

    cursor.execute("""
        UPDATE users 
        SET daily_attempts = ?, last_attempt_date = ? 
        WHERE id = ?
    """, (attempts + 1, today, user_id))
    
    conn.commit()
    conn.close()
    return {"status": "success", "attempts": attempts + 1}

# --- NEW: Daily Challenge Reward Logic ---
@app.put("/complete-challenge/{user_id}")
async def complete_challenge(user_id: int, reward_color: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    today = date.today().isoformat()
    
    # Check if reward already claimed today
    if user['last_challenge_date'] == today:
        conn.close()
        return {"status": "already_played", "message": "Reward already claimed today!"}

    # Calculate Streak
    current_streak = user['streak']
    new_streak = current_streak + 1
    
    # Add new color to unlocked_themes list (comma separated)
    theme_list = split_csv(user["unlocked_themes"])
    if reward_color not in theme_list:
        theme_list.append(reward_color)

    new_themes = join_csv(theme_list)
    new_completed_daily_challenges = (user["completed_daily_challenges"] or 0) + 1

    cursor.execute("""
        UPDATE users 
        SET streak = ?, last_challenge_date = ?, unlocked_themes = ?, completed_daily_challenges = ?
        WHERE id = ?
    """, (new_streak, today, new_themes, new_completed_daily_challenges, user_id))
    
    conn.commit()
    conn.close()
    
    return {
        "status": "success", 
        "new_streak": new_streak, 
        "unlocked_color": reward_color,
        "completed_daily_challenges": new_completed_daily_challenges,
    }


@app.put("/mark-reward-seen/{user_id}/{reward_id}")
async def mark_reward_seen(user_id: int, reward_id: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute("SELECT seen_rewards FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    trimmed_reward_id = reward_id.strip()
    seen_list = split_csv(user["seen_rewards"])
    if trimmed_reward_id not in seen_list:
        seen_list.append(trimmed_reward_id)
        new_seen = join_csv(seen_list)
        cursor.execute("UPDATE users SET seen_rewards = ? WHERE id = ?", (new_seen, user_id))
        conn.commit()
    
    conn.close()
    return {"status": "success"}

@app.get("/admin/stats", dependencies=[Depends(verify_admin)])
async def get_admin_stats():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()

    total_users = cursor.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    banned_users = cursor.execute("SELECT COUNT(*) FROM users WHERE is_banned = 1").fetchone()[0]
    pending_reports = cursor.execute("SELECT COUNT(*) FROM reports WHERE status = 'Pending'").fetchone()[0]

    conn.close()
    return {
        "total_users": total_users,
        "banned_users": banned_users,
        "pending_reports": pending_reports
    }

@app.get("/admin/users", dependencies=[Depends(verify_admin)])
async def get_admin_users(search: str = ""):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    query = "SELECT id, username, email, total_score, highest_level, is_banned, ban_reason, banked_points, lifetime_points FROM users"
    params = []
    
    if search:
        query += " WHERE username LIKE ? OR email LIKE ?"
        params = [f"%{search}%", f"%{search}%"]
    
    query += " ORDER BY id DESC"
    
    users = cursor.execute(query, params).fetchall()
    conn.close()
    
    return [dict(u) for u in users]

class AdjustPointsRequest(BaseModel):
    banked_points: int
    lifetime_points: int

@app.post("/admin/users/{user_id}/adjust-points", dependencies=[Depends(verify_admin)])
async def adjust_points(user_id: int, request: AdjustPointsRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET banked_points = ?, lifetime_points = ? WHERE id = ?", 
                   (request.banked_points, request.lifetime_points, user_id))
    conn.commit()
    conn.close()
    return {"message": f"Points for user {user_id} adjusted successfully."}

@app.post("/admin/users/{user_id}/reset", dependencies=[Depends(verify_admin)])
async def admin_reset_user(user_id: int):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    # Check if user exists
    user = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
        
    cursor.execute("""
        UPDATE users 
        SET total_score = 0, highest_score = 0, highest_level = 0, levels_cleared = 0,
            fast_finishes = 0, perfect_finishes = 0, boxes_tapped = 0, completed_daily_challenges = 0,
            extreme_clears = 0, unlocked_themes = '', selected_theme = '#A9A9A9',
            streak = 0, last_challenge_date = NULL, daily_attempts = 0, last_attempt_date = NULL
        WHERE id = ?
    """, (user_id,))
    
    conn.commit()
    conn.close()
    return {"message": f"User {user_id} progress reset successfully."}

class BanRequest(BaseModel):
    reason: str

@app.put("/admin/users/{user_id}/ban", dependencies=[Depends(verify_admin)])
async def ban_user(user_id: int, request: BanRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET is_banned = 1, ban_reason = ? WHERE id = ?", (request.reason, user_id))
    conn.commit()
    conn.close()
    return {"message": f"User {user_id} banned successfully."}

@app.put("/admin/users/{user_id}/unban", dependencies=[Depends(verify_admin)])
async def unban_user(user_id: int):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET is_banned = 0, ban_reason = NULL WHERE id = ?", (user_id,))
    conn.commit()
    conn.close()
    return {"message": f"User {user_id} unbanned successfully."}

class AppealRequest(BaseModel):
    user_id: int
    appeal_text: str

@app.post("/appeals")
async def submit_appeal(request: AppealRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO appeals (user_id, appeal_text, status, timestamp) VALUES (?, ?, 'Pending', ?)",
        (request.user_id, request.appeal_text, str(date.today()))
    )
    conn.commit()
    appeal_id = cursor.lastrowid
    conn.close()
    return {"appeal_id": appeal_id, "message": "Appeal submitted successfully."}

@app.get("/admin/appeals", dependencies=[Depends(verify_admin)])
async def get_appeals():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    appeals = cursor.execute(
        "SELECT id, user_id, appeal_text, status, timestamp FROM appeals ORDER BY timestamp DESC"
    ).fetchall()
    conn.close()
    return [
        {"id": a[0], "user_id": a[1], "appeal_text": a[2], "status": a[3], "timestamp": a[4]}
        for a in appeals
    ]

@app.put("/admin/appeals/{appeal_id}", dependencies=[Depends(verify_admin)])
async def update_appeal_status(appeal_id: int, status: str):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE appeals SET status = ? WHERE id = ?", (status, appeal_id))
    conn.commit()
    conn.close()
    return {"message": f"Appeal {appeal_id} status updated to {status}."}

class ReportRequest(BaseModel):
    reporter_id: int
    reported_id: int
    reason: str

@app.post("/reports")
async def submit_report(request: ReportRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO reports (reporter_id, reported_id, reason, timestamp, status) VALUES (?, ?, ?, ?, 'Pending')",
        (request.reporter_id, request.reported_id, request.reason, str(date.today()))
    )
    conn.commit()
    report_id = cursor.lastrowid
    conn.close()
    return {"report_id": report_id, "message": "Report submitted successfully."}

@app.get("/admin/reports", dependencies=[Depends(verify_admin)])
async def get_reports():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    reports = cursor.execute(
        "SELECT id, reporter_id, reported_id, reason, timestamp, status FROM reports ORDER BY timestamp DESC"
    ).fetchall()
    conn.close()
    return [
        {"id": r[0], "reporter_id": r[1], "reported_id": r[2], "reason": r[3], "timestamp": r[4], "status": r[5]}
        for r in reports
    ]

@app.put("/admin/reports/{report_id}", dependencies=[Depends(verify_admin)])
async def update_report_status(report_id: int, status: str):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE reports SET status = ? WHERE id = ?", (status, report_id))
    conn.commit()
    conn.close()
    return {"message": f"Report {report_id} status updated to {status}."}

class SupportTicketRequest(BaseModel):
    user_id: int
    type: str
    message: str

@app.post("/support/tickets")
async def submit_support_ticket(request: SupportTicketRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO support_tickets (user_id, type, message, status, timestamp) VALUES (?, ?, ?, 'Open', ?)",
        (request.user_id, request.type, request.message, str(date.today()))
    )
    conn.commit()
    ticket_id = cursor.lastrowid
    conn.close()
    return {"ticket_id": ticket_id, "message": "Support ticket submitted successfully."}

@app.get("/admin/support/tickets", dependencies=[Depends(verify_admin)])
async def get_support_tickets():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    tickets = cursor.execute(
        "SELECT id, user_id, type, message, status, timestamp FROM support_tickets ORDER BY timestamp DESC"
    ).fetchall()
    conn.close()
    return [
        {"id": t[0], "user_id": t[1], "type": t[2], "message": t[3], "status": t[4], "timestamp": t[5]}
        for t in tickets
    ]

@app.put("/admin/support/tickets/{ticket_id}", dependencies=[Depends(verify_admin)])
async def update_support_ticket_status(ticket_id: int, status: str):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE support_tickets SET status = ? WHERE id = ?", (status, ticket_id))
    conn.commit()
    conn.close()
    return {"message": f"Support ticket {ticket_id} status updated to {status}."}
