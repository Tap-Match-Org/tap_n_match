# Tap & Match Admin Dashboard

A comprehensive web-based moderation and support dashboard for the Tap & Match game.

## Features

- **Dashboard Statistics**: View total users, banned users, and pending reports
- **Report Management**: Review user reports, approve/reject them
- **Appeal Management**: Handle ban appeals from banned users
- **Support Tickets**: Manage user support requests and feedback
- **Admin Authentication**: Secure access with approved Gmail verification and admin password

## Tech Stack

- **Frontend**: React 18 + Vite
- **UI**: Modern CSS with responsive design
- **API Client**: Axios
- **Backend**: FastAPI (Python)

## Setup

### Prerequisites

- Node.js 16+ 
- npm or yarn

### Installation

1. Navigate to the dashboard directory:
```bash
cd dashboard
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

The dashboard will open at `http://localhost:3000`

### Building for Production

```bash
npm run build
npm run preview
```

## Usage

1. Open the dashboard in your browser
2. Enter one of the approved Gmail accounts
3. Request the verification code sent to that inbox
4. Log in using the admin password
5. View and manage:
   - **Reports Tab**: Review user reports and take action
   - **Appeals Tab**: Review ban appeals and approve/reject them
   - **Support Tickets Tab**: View and close support requests

## API Endpoints

The dashboard communicates with these FastAPI endpoints:

- `GET /admin/stats` - Get dashboard statistics
- `GET /admin/reports` - List all reports
- `PUT /admin/reports/{id}` - Update report status
- `GET /admin/appeals` - List all appeals
- `PUT /admin/appeals/{id}` - Update appeal status
- `GET /admin/support/tickets` - List all support tickets
- `PUT /admin/support/tickets/{id}` - Update ticket status
- `PUT /admin/users/{id}/ban` - Ban a user
- `PUT /admin/users/{id}/unban` - Unban a user

## Notes

- The admin session token is stored in localStorage for session persistence
- The dashboard auto-refreshes stats every 30 seconds
- All admin actions require valid authentication
- The backend must be running on `http://localhost:8000`
