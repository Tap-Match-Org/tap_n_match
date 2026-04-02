# Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build a secure, web-based moderation and support dashboard for *Tap & Match*.

**Architecture:**
- **Backend:** FastAPI routes under `/admin/` protected by a static API key.
- **Frontend:** A standalone React dashboard (standalone task).
- **Game:** Flutter client integration for reporting and instant-kick handling.

**Tech Stack:** Python (FastAPI), SQLite, Flutter (Dart).

---

### Task 1: Database Migration for Moderation

**Files:**
- Create: `backend/migrate_moderation.py`
- Modify: `backend/users.db` (via script)

- [x] **Step 1: Write the migration script**
- [x] **Step 2: Run the migration**
- [x] **Step 3: Commit**

---

### Task 2: Backend Admin Security & Base Routes

**Files:**
- Modify: `backend/main.py`

- [x] **Step 1: Implement Admin Dependency in `main.py`**
- [x] **Step 2: Test with curl**
- [x] **Step 3: Commit**

---

### Task 3: Backend Moderation API (Ban/Unban)

**Files:**
- Modify: `backend/main.py`

- [x] **Step 1: Add Ban Route**
- [x] **Step 2: Commit**

---

### Task 4: Flutter Game Integration - Instant Kick

**Files:**
- Modify: `lib/presentation/auth/login_page.dart` (and other core API calls)
- Create: `lib/presentation/auth/banned_page.dart`

- [x] **Step 1: Create Banned Screen UI**
- [x] **Step 2: Update API handlers to check for is_banned flag in user payload**
- [x] **Step 3: Commit**
