# Design Spec: Reporting & Admin System

**Date:** 2026-03-30  
**Status:** Draft  
**Topic:** Game Reporting System & Admin Dashboard  

## 1. Overview
The goal is to implement a robust reporting system for the "Tap & Match" game. This includes an in-game UI for players to report bugs, feedback, or other players, and a separate web-based admin dashboard for moderators to review reports and take disciplinary actions (banning).

## 2. Architecture
Following **Approach 1 (Unified Monolith)**:
- **Backend:** Integrated into the existing FastAPI `main.py`.
- **Database:** Uses the existing `users.db` (SQLite) with a new `reports` table and updates to the `users` table.
- **Admin UI:** Server-side rendered HTML using **Jinja2** templates and **Tailwind CSS** for styling, served directly by FastAPI.

## 3. Data Model

### 3.1. `reports` Table (New)
| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary Key (Auto-increment) |
| `reporter_id` | INTEGER | User ID of the person submitting the report. |
| `reported_user_id`| INTEGER | (Optional) User ID of the player being reported. |
| `report_type` | TEXT | `BUG`, `FEEDBACK`, or `PLAYER_REPORT`. |
| `message` | TEXT | Description of the issue. |
| `status` | TEXT | `PENDING`, `RESOLVED`, `DISMISSED`. Default: `PENDING`. |
| `created_at` | TEXT | ISO timestamp of submission. |

### 3.2. `users` Table (Updates)
| Column | Type | Description |
|--------|------|-------------|
| `is_banned` | INTEGER | Boolean (0/1). Default: 0. |
| `ban_expires_at` | TEXT | ISO timestamp for when the ban ends. NULL for permanent. |
| `ban_reason` | TEXT | Description of why the user was banned. |

## 4. API Endpoints

### 4.1. Player Endpoints (Game App)
- `POST /submit-report/{user_id}`: Submits a bug or feedback report.
- `POST /report-player/{reporter_id}/{reported_user_id}`: Submits a report against another player.

### 4.2. Admin Endpoints (Web Dashboard)
- `GET /admin/dashboard`: Serves the HTML dashboard page.
- `GET /api/admin/reports`: Returns a list of all reports (filtered/sorted).
- `PATCH /api/admin/reports/{report_id}`: Updates report status (e.g., to `RESOLVED`).
- `POST /api/admin/ban/{user_id}`: Bans a user (Payload: `reason`, `duration_hours`).
- `POST /api/admin/unban/{user_id}`: Lifts a ban manually.

## 5. UI/UX Design

### 5.1. Game App
- **General Report:** A "Report Issue" button in the Settings/Main Menu opening a dialog with a dropdown (`Bug`, `Feedback`) and a text area.
- **Player Report:** A "Report" button on player profiles (Leaderboard/Community) that auto-selects the reported user's ID.

### 5.2. Admin Dashboard
- **Report List:** A table showing Type, Reporter, Message, and Status.
- **Action Buttons:** Quick actions for each report:
    - **Resolve:** Mark as handled.
    - **Ban User:** Opens a modal to set reason and duration (24h, 3d, 7d, Permanent).
- **Authentication:** A simple admin login page (`/admin/login`) to protect the dashboard.

## 6. Implementation Notes
- **Ban Check:** The `/login` and `/users/{user_id}` endpoints must be updated to check if `ban_expires_at` is in the future.
- **Temporary Logic:** If `ban_expires_at` is passed, the user is automatically "unbanned" during the next login attempt by clearing the ban fields.
- **Dependencies:** Requires `jinja2` and `python-multipart` for FastAPI template rendering and form handling.
