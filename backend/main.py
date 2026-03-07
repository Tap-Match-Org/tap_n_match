from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import smtplib, random
from email.message import EmailMessage
import sqlite3

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

# In-memory dictionary to store verification codes
# In a real app, use Redis or a database with expiration
pending_codes = {}

# Setup Database
def init_db():
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
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

# --- Endpoints ---

@app.post("/send-code")
async def send_code(request: EmailRequest):
    code = str(random.randint(100000, 999999))
    pending_codes[request.email] = code
    
    # Optional: Send the actual email
    # If the credentials are invalid, we just print the code to the console for testing
    msg = EmailMessage()
    msg.set_content(f"Your verification code is: {code}")
    msg["Subject"] = "Tap & Match - Verification Code"
    msg["From"] = SENDER_EMAIL
    msg["To"] = request.email

    try:
        # NOTE: You probably need to set real credentials in SENDER_EMAIL and SENDER_PASSWORD
        # to actually send the email via Gmail.
        # Alternatively, we just print it to the console so you can test it locally.
        print(f"[DEBUG] Generated code for {request.email}: {code}")
        
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.send_message(msg)
        server.quit()
    except Exception as e:
        print("[WARNING] Could not send email due to invalid credentials or network issue.")
        print(f"[NOTE] Please check terminal for the code: {code}")

    return {"message": "Code sent successfully or logged to console"}

@app.post("/register")
async def register(request: RegisterRequest):
    # Verify the code
    if request.email not in pending_codes or pending_codes[request.email] != request.code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Invalid or expired verification code."
        )

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()

    try:
        # Check if username or email already exists
        cursor.execute("SELECT * FROM users WHERE username = ? OR email = ?", (request.username, request.email))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail="Username or email already exists."
            )

        # Insert new user
        cursor.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
                       (request.username, request.email, request.password))
        conn.commit()
    except sqlite3.Error as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )
    finally:
        conn.close()

    # Clear code
    del pending_codes[request.email]

    return {"message": "User registered successfully."}

@app.post("/login")
async def login(request: LoginRequest):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (request.username, request.password))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid username or password"
        )

    return {"message": "Login successful"}