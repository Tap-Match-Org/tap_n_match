from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import smtplib, random
from email.message import EmailMessage
import sqlite3
from datetime import date

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
            unlocked_themes TEXT DEFAULT '#FFFFFF', 
            streak INTEGER DEFAULT 0,
            last_challenge_date TEXT
        )
    """)
    
    # Try adding the new created_at column to existing DBs safely
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN created_at TEXT DEFAULT CURRENT_DATE")
    except sqlite3.OperationalError:
        pass # Column already exists
        
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

    del pending_codes[request.email]
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
        "SELECT unlocked_themes, streak, last_challenge_date, created_at FROM users WHERE id = ?", 
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return dict(user)

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
    
    # Check if already played today
    if user['last_challenge_date'] == today:
        conn.close()
        return {"status": "already_played", "message": "Reward already claimed today!"}

    # Calculate Streak
    current_streak = user['streak']
    new_streak = current_streak + 1 if current_streak < 7 else 1
    
    # Add new color to unlocked_themes list (comma separated)
    themes = user['unlocked_themes'] or ""
    if reward_color not in themes:
        themes = f"{themes},{reward_color}".strip(",")

    cursor.execute("""
        UPDATE users 
        SET streak = ?, last_challenge_date = ?, unlocked_themes = ? 
        WHERE id = ?
    """, (new_streak, today, themes, user_id))
    
    conn.commit()
    conn.close()
    
    return {
        "status": "success", 
        "new_streak": new_streak, 
        "unlocked_color": reward_color
    }