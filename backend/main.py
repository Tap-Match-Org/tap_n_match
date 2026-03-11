from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import smtplib, random
from email.message import EmailMessage
import sqlite3
from datetime import date, timedelta

app = FastAPI()

# Enable CORS so your Flutter app can talk to the backend
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

def init_db():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    # Updated Schema to include unlocked_themes and streak
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            unlocked_themes TEXT DEFAULT '#A9A9A9', 
            streak INTEGER DEFAULT 0,
            last_challenge_date TEXT
        )
    """)
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

# --- Auth Routes ---

@app.post("/send-code")
async def send_code(request: EmailRequest):
    code = str(random.randint(100000, 999999))
    pending_codes[request.email] = code
    print(f"[DEBUG] Verification Code for {request.email}: {code}")
    return {"message": "Code sent successfully"}

@app.post("/register")
async def register(request: RegisterRequest):
    if request.email not in pending_codes or pending_codes[request.email] != request.code:
        raise HTTPException(status_code=400, detail="Invalid code.")
    
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
                       (request.username, request.email, request.password))
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Username or Email already exists.")
    finally:
        conn.close()
    return {"message": "Registered successfully."}

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
    return {"user_id": user[0], "username": user[1]}

# --- User & Theme Routes ---

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    user = cursor.execute("SELECT unlocked_themes, streak FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    return {
        "unlocked_themes": user["unlocked_themes"],
        "streak": user["streak"]
    }

@app.put("/complete-challenge/{user_id}")
async def complete_challenge(user_id: int, reward_color: str):
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    user = cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    today_obj = date.today()
    today = today_obj.isoformat()
    yesterday = (today_obj - timedelta(days=1)).isoformat()
    last_played = user['last_challenge_date']

    # Prevent double-claiming today
    if last_played == today:
        conn.close()
        return {"status": "already_played"}

    # Streak Logic
    current_streak = user['streak'] or 0
    new_streak = (current_streak + 1 if current_streak < 7 else 1) if last_played == yesterday else 1
    
    # Theme Unlocking Logic
    themes = user['unlocked_themes'] or ""
    unlocked_list = [t.strip() for t in themes.split(",") if t.strip()]
    
    if reward_color and reward_color not in unlocked_list:
        unlocked_list.append(reward_color)
    
    new_themes_str = ",".join(unlocked_list)

    cursor.execute("""
        UPDATE users 
        SET streak = ?, last_challenge_date = ?, unlocked_themes = ? 
        WHERE id = ?
    """, (new_streak, today, new_themes_str, user_id))
    
    conn.commit()
    conn.close()
    return {"status": "success", "streak": new_streak, "themes": new_themes_str}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)