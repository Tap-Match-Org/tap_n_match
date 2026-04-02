# Design Spec: Admin Dashboard - Unified Support Hub

A centralized moderation and support platform for the *Tap & Match* game.

## Goal

To provide a secure, web-based dashboard for game administrators to manage users, monitor leaderboards, handle reports, and review ban appeals.

## Architecture

1.  **Admin Web App:** A standalone React (or simple HTML/JS) dashboard.
2.  **Extended Backend (FastAPI):** A new `/admin/` route prefix in `backend/main.py`.
3.  **Moderation Flow (Instant Kick):** The backend updates the `users.db`. The game client (Flutter) checks for the `is_banned` flag during every API interaction and triggers an immediate lockout if it is set to `true`.

## Data Models (SQLite)

### Users Table (Updated)
- `is_banned` (INTEGER): `1` for banned, `0` for active.
- `ban_reason` (TEXT): A brief explanation for the ban.

### Reports Table (New)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `reporter_id` (INTEGER): The ID of the user submitting the report.
- `reported_id` (INTEGER): The ID of the user being reported.
- `reason` (TEXT): The reason for the report (e.g., "Inappropriate Username").
- `timestamp` (TEXT): ISO 8601 formatted date/time.
- `status` (TEXT): "Pending", "Reviewed", "Dismissed".

### Support/Feedback Table (New)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `user_id` (INTEGER): The ID of the user submitting the ticket.
- `type` (TEXT): "Bug", "Feedback", "Support".
- `message` (TEXT): The message body.
- `status` (TEXT): "Open", "Closed".
- `timestamp` (TEXT): ISO 8601 formatted date/time.

### Appeals Table (New)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `user_id` (INTEGER): The ID of the user submitting the appeal.
- `appeal_text` (TEXT): The justification for the appeal.
- `status` (TEXT): "Pending", "Approved", "Denied".
- `timestamp` (TEXT): ISO 8601 formatted date/time.

## API Endpoints

### Public Endpoints (For Flutter Game)
- `POST /reports`: Submit a report for another player.
- `POST /support`: Submit a bug report or feedback.
- `POST /appeals`: Submit a ban appeal (only accessible to banned users).

### Protected Admin Endpoints (Header: `X-Admin-Key`)
- `GET /admin/stats`: Get overview metrics (Total Users, Active Reports, Open Appeals).
- `GET /admin/reports`: List all player reports.
- `GET /admin/appeals`: List all ban appeals.
- `GET /admin/support`: List all bug reports and feedback.
- `PUT /admin/users/{id}/ban`: Ban or unban a user.
- `DELETE /admin/users/{id}`: (Optional) Delete a user account and its data.

## Security

- **Admin Password:** A single, secure string stored in a `.env` file on the backend.
- **Header Auth:** Every admin request must include the `X-Admin-Key` header matching the backend password.

## User Experience (Instant Kick)

When a player is banned in the dashboard, their next request to the backend will return a `403 Forbidden` error. The Flutter app will catch this error, clear the local user session, and navigate to a "You are Banned" screen with an "Appeal" button.

## Roadmap

1.  **Phase 1: Database Migration.** Create a script to add new columns and tables.
2.  **Phase 2: Backend API.** Implement the new routes in `backend/main.py`.
3.  **Phase 3: Frontend Dashboard.** Create a simple, functional web-based dashboard.
4.  **Phase 4: Game Integration.** Update the Flutter app to support reporting and handle bans.
