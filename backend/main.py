from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import smtplib, random
from email.message import EmailMessage
import sqlite3
from datetime import date, timedelta

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
            boxes_tapped INTEGER DEFAULT 0
        )
    """)
    
    # Try adding new columns to existing DBs safely
    columns_to_add = [
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
    ]
    for col_name, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
        except sqlite3.OperationalError as e:
            if "duplicate column name" not in str(e).lower():
                print(f"[ERROR] Could not add {col_name} column: {e}")
        
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


def count_unlocked_themes(unlocked_themes: str | None) -> int:
    if not unlocked_themes:
        return 0
    return len([theme.strip() for theme in unlocked_themes.split(",") if theme.strip()])


def calculate_achievement_count(user_row: sqlite3.Row) -> int:
    unlocked_count = count_unlocked_themes(user_row["unlocked_themes"])
    levels_cleared = user_row["levels_cleared"] or 0
    fast_finishes = user_row["fast_finishes"] or 0
    perfect_finishes = user_row["perfect_finishes"] or 0
    streak = user_row["streak"] or 0
    achievements = [
        levels_cleared >= 1,
        levels_cleared >= 5,
        levels_cleared >= 25,
        fast_finishes >= 1,
        user_row["last_challenge_date"] is not None,
        streak >= 3,
        streak >= 7,
        unlocked_count >= 3,
        unlocked_count >= 7,
        perfect_finishes >= 1,
    ]
    return sum(1 for unlocked in achievements if unlocked)


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
        cursor.execute("INSERT INTO users (username, email, password, created_at) VALUES (?, ?, ?, ?)",
                       (request.username, request.email, request.password, today))
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
    cursor = conn.cursor()
    cursor.execute("SELECT id, username FROM users WHERE username = ? AND password = ?", 
                   (request.username, request.password))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # In a real app, return a token. For now, we return user info.
    return {"message": "Login successful", "user_id": user[0], "username": user[1]}

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
        SELECT username, email, unlocked_themes, selected_theme, last_username_change_date,
               profile_picture, streak, last_challenge_date, created_at, daily_attempts, last_attempt_date,
               total_score, highest_score, highest_level, levels_cleared,
               fast_finishes, perfect_finishes, boxes_tapped
        FROM users
        WHERE id = ?
        """,
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user_dict = dict(user)
    today = date.today().isoformat()
    
    # Reset daily attempts if it's a new day
    if user_dict['last_attempt_date'] != today:
        user_dict['daily_attempts'] = 0

    user_dict["achievement_count"] = calculate_achievement_count(user)
        
    return user_dict


@app.get("/public-users/{user_id}")
async def get_public_user_info(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute(
        """
        SELECT username, unlocked_themes, selected_theme, profile_picture,
               last_username_change_date, streak, last_challenge_date, created_at,
               daily_attempts, last_attempt_date, total_score, highest_score,
               highest_level, levels_cleared, fast_finishes, perfect_finishes,
               boxes_tapped
        FROM users
        WHERE id = ?
        """,
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user_dict = dict(user)
    today = date.today().isoformat()
    if user_dict["last_attempt_date"] != today:
        user_dict["daily_attempts"] = 0

    user_dict["achievement_count"] = calculate_achievement_count(user)
    return user_dict


@app.put("/complete-level/{user_id}")
async def complete_level(user_id: int, request: LevelCompletionRequest):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    user = cursor.execute(
        """
        SELECT username, email, unlocked_themes, selected_theme, last_username_change_date,
               profile_picture, streak, last_challenge_date, created_at, daily_attempts, last_attempt_date,
               total_score, highest_score, highest_level, levels_cleared,
               fast_finishes, perfect_finishes, boxes_tapped
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

    new_total_score = current_total_score + score_breakdown["total_earned"]
    new_run_score = max(request.run_score_before_level, 0) + score_breakdown["total_earned"]
    new_highest_score = max(current_highest_score, new_run_score)
    new_highest_level = max(current_highest_level, request.level)
    new_levels_cleared = current_levels_cleared + 1
    new_fast_finishes = current_fast_finishes + (1 if score_breakdown["fast_bonus"] > 0 else 0)
    new_perfect_finishes = current_perfect_finishes + (1 if score_breakdown["perfect_bonus"] > 0 else 0)
    new_boxes_tapped = current_boxes_tapped + max(request.boxes_tapped, 0)

    cursor.execute(
        """
        UPDATE users
        SET total_score = ?, highest_score = ?, highest_level = ?, levels_cleared = ?,
            fast_finishes = ?, perfect_finishes = ?, boxes_tapped = ?
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
            user_id,
        ),
    )
    conn.commit()

    updated_user = cursor.execute(
        """
        SELECT username, email, unlocked_themes, selected_theme, last_username_change_date,
               profile_picture, streak, last_challenge_date, created_at, daily_attempts, last_attempt_date,
               total_score, highest_score, highest_level, levels_cleared,
               fast_finishes, perfect_finishes, boxes_tapped
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
        "highest_score": new_highest_score,
        "highest_level": new_highest_level,
        "boxes_tapped": new_boxes_tapped,
        "achievement_count": calculate_achievement_count(updated_user),
    }


@app.get("/leaderboards")
async def get_leaderboards():
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    rows = cursor.execute(
        """
        SELECT id, username, unlocked_themes, highest_score, highest_level, streak,
               last_challenge_date, levels_cleared, fast_finishes, perfect_finishes
        FROM users
        ORDER BY highest_score DESC, highest_level DESC, username COLLATE NOCASE ASC
        """
    ).fetchall()
    conn.close()

    leaderboard = []
    for index, row in enumerate(rows, start=1):
        leaderboard.append({
            "rank": index,
            "user_id": row["id"],
            "username": row["username"],
            "score": row["highest_score"],
            "highest_level": row["highest_level"],
            "achievement_count": calculate_achievement_count(row),
        })

    return {"players": leaderboard}


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

    cursor.execute(
        "UPDATE users SET profile_picture = ? WHERE id = ?",
        (profile_picture, user_id),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Profile picture updated."}


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
            selected_theme = '#A9A9A9',
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
            boxes_tapped = 0
        WHERE id = ?
        """,
        (user_id,),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Account progress reset."}

@app.put("/select-theme/{user_id}")
async def select_theme(user_id: int, theme_color: str):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    
    cursor.execute("UPDATE users SET selected_theme = ? WHERE id = ?", (theme_color, user_id))
    conn.commit()
    conn.close()
    
    return {"status": "success", "selected_theme": theme_color}

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
    themes = user['unlocked_themes'] or ""
    theme_list = [t.strip() for t in themes.split(",") if t.strip()]
    if reward_color not in theme_list:
        theme_list.append(reward_color)
    
    new_themes = ",".join(theme_list)

    cursor.execute("""
        UPDATE users 
        SET streak = ?, last_challenge_date = ?, unlocked_themes = ? 
        WHERE id = ?
    """, (new_streak, today, new_themes, user_id))
    
    conn.commit()
    conn.close()
    
    return {
        "status": "success", 
        "new_streak": new_streak, 
        "unlocked_color": reward_color
    }
