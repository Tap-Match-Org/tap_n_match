import React, { useEffect, useMemo, useState } from 'react';
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000';
const POLL_INTERVAL_MS = 20000;

function formatDate(value) {
    if (!value) return 'Not available';
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return value;
    return parsed.toLocaleString();
}

function formatNumber(value) {
    if (value === null || value === undefined) return '0';
    return Number(value).toLocaleString();
}

function statusClassName(status) {
    return String(status || 'unknown').toLowerCase().replace(/\s+/g, '-');
}

function truncate(value, max = 120) {
    if (!value) return '-';
    if (value.length <= max) return value;
    return `${value.slice(0, max)}...`;
}

function AuthComponent({ onAuth }) {
    const [adminKey, setAdminKey] = useState('');
    const [error, setError] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();
        if (!adminKey.trim()) {
            setError('Admin key is required');
            return;
        }
        onAuth(adminKey);
        setAdminKey('');
    };

    return (
        <div className="auth-section">
            <h2>Tap & Match Admin Dashboard</h2>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label htmlFor="adminKey">Admin Key</label>
                    <input
                        id="adminKey"
                        type="password"
                        value={adminKey}
                        onChange={(e) => {
                            setAdminKey(e.target.value);
                            setError('');
                        }}
                        placeholder="Enter admin key"
                    />
                </div>
                {error && <div className="alert alert-error">{error}</div>}
                <button type="submit" className="btn-primary" style={{ width: '100%' }}>
                    Login
                </button>
            </form>
        </div>
    );
}

function StatsBar({ stats }) {
    const cards = [
        { label: 'Total Users', value: stats?.total_users },
        { label: 'New Users Today', value: stats?.new_users_today },
        { label: 'Banned Users', value: stats?.banned_users },
        { label: 'Pending Reports', value: stats?.pending_reports },
        { label: 'Pending Appeals', value: stats?.pending_appeals },
        { label: 'Open Tickets', value: stats?.open_tickets },
    ];

    return (
        <div className="stats">
            {cards.map((card) => (
                <div className="stat-card" key={card.label}>
                    <h3>{card.label}</h3>
                    <div className="number">{formatNumber(card.value)}</div>
                </div>
            ))}
        </div>
    );
}

function StatusBadge({ status }) {
    return (
        <span className={`status-badge status-${statusClassName(status)}`}>
            {status || 'Unknown'}
        </span>
    );
}

function SectionCard({ title, subtitle, children, actions }) {
    return (
        <section className="panel-card">
            <div className="panel-header">
                <div>
                    <h3>{title}</h3>
                    {subtitle && <p>{subtitle}</p>}
                </div>
                {actions}
            </div>
            {children}
        </section>
    );
}

function OverviewTab({ overview, onSelectUser }) {
    if (!overview) {
        return <div className="loading">Loading overview...</div>;
    }

    return (
        <div className="overview-grid">
            <SectionCard title="Recent Activity" subtitle="Latest tracked player actions from the live game.">
                <div className="stack-list">
                    {overview.recent_activity?.length ? overview.recent_activity.map((activity) => (
                        <button
                            type="button"
                            key={activity.id}
                            className="list-card"
                            onClick={() => onSelectUser(activity.user_id)}
                        >
                            <div className="list-title">
                                <strong>{activity.username || `User ${activity.user_id}`}</strong>
                                <span>{activity.event_label}</span>
                            </div>
                            <p>{activity.summary}</p>
                            <small>{formatDate(activity.created_at)}</small>
                        </button>
                    )) : <div className="empty-state">No player activity has been logged yet.</div>}
                </div>
            </SectionCard>

            <SectionCard title="Top Players" subtitle="Current leaderboard snapshot from game data.">
                <div className="stack-list compact">
                    {overview.top_players?.map((player) => (
                        <button
                            type="button"
                            key={player.id}
                            className="list-card"
                            onClick={() => onSelectUser(player.id)}
                        >
                            <div className="list-title">
                                <strong>{player.username}</strong>
                                {player.is_banned ? <StatusBadge status="Banned" /> : null}
                            </div>
                            <p>
                                Lifetime: {formatNumber(player.lifetime_points)} | Banked: {formatNumber(player.banked_points)} | Highest Level: {formatNumber(player.highest_level)}
                            </p>
                        </button>
                    ))}
                </div>
            </SectionCard>

            <SectionCard title="Most Reported Players" subtitle="Useful for moderation triage and appeal review.">
                <div className="stack-list compact">
                    {overview.most_reported_players?.length ? overview.most_reported_players.map((player) => (
                        <button
                            type="button"
                            key={player.id}
                            className="list-card"
                            onClick={() => onSelectUser(player.id)}
                        >
                            <div className="list-title">
                                <strong>{player.username}</strong>
                                <span>{player.pending_report_count} pending</span>
                            </div>
                            <p>Total reports: {player.report_count}</p>
                        </button>
                    )) : <div className="empty-state">No player reports yet.</div>}
                </div>
            </SectionCard>

            <SectionCard title="Needs Attention" subtitle="Open moderation items that still need admin action.">
                <div className="attention-grid">
                    <div>
                        <h4>Pending Reports</h4>
                        <div className="stack-list compact">
                            {overview.attention_queue?.pending_reports?.length ? overview.attention_queue.pending_reports.map((report) => (
                                <div className="list-card static" key={`report-${report.id}`}>
                                    <div className="list-title">
                                        <strong>Report #{report.id}</strong>
                                        <StatusBadge status={report.status} />
                                    </div>
                                    <p>User {report.reporter_id} reported User {report.reported_id}</p>
                                    <small>{truncate(report.reason, 90)}</small>
                                </div>
                            )) : <div className="empty-state">No pending reports.</div>}
                        </div>
                    </div>
                    <div>
                        <h4>Pending Appeals</h4>
                        <div className="stack-list compact">
                            {overview.attention_queue?.pending_appeals?.length ? overview.attention_queue.pending_appeals.map((appeal) => (
                                <div className="list-card static" key={`appeal-${appeal.id}`}>
                                    <div className="list-title">
                                        <strong>Appeal #{appeal.id}</strong>
                                        <StatusBadge status={appeal.status} />
                                    </div>
                                    <p>User {appeal.user_id}</p>
                                    <small>{truncate(appeal.appeal_text, 90)}</small>
                                </div>
                            )) : <div className="empty-state">No pending appeals.</div>}
                        </div>
                    </div>
                </div>
            </SectionCard>
        </div>
    );
}

function DataTable({ columns, rows, emptyMessage }) {
    return (
        <div className="table-container">
            <table>
                <thead>
                    <tr>
                        {columns.map((column) => <th key={column.key}>{column.label}</th>)}
                    </tr>
                </thead>
                <tbody>
                    {!rows.length ? (
                        <tr>
                            <td colSpan={columns.length}>
                                <div className="empty-state">{emptyMessage}</div>
                            </td>
                        </tr>
                    ) : rows.map((row, rowIndex) => (
                        <tr key={row.id ?? rowIndex}>
                            {columns.map((column) => (
                                <td key={column.key}>
                                    {column.render ? column.render(row) : row[column.key]}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

function UsersTab({ adminKey, onMutate, onSelectUser, selectedUserId }) {
    const [users, setUsers] = useState([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchUsers = async (searchTerm = search) => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/users?search=${encodeURIComponent(searchTerm)}`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setUsers(response.data);
            setError('');
        } catch (err) {
            setError('Failed to fetch users');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminKey) {
            fetchUsers('');
        }
    }, [adminKey]);

    const handleSearch = (e) => {
        e.preventDefault();
        fetchUsers(search);
    };

    const toggleBan = async (user) => {
        try {
            if (user.is_banned) {
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/unban`, {}, {
                    headers: { 'X-Admin-Key': adminKey }
                });
            } else {
                const reason = window.prompt('Enter ban reason:', user.ban_reason || 'Rules violation');
                if (reason === null) return;
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/ban`, { reason }, {
                    headers: { 'X-Admin-Key': adminKey }
                });
            }
            await fetchUsers(search);
            onMutate(user.id);
        } catch (err) {
            setError('Failed to update ban status');
        }
    };

    const resetProgress = async (userId) => {
        if (!window.confirm('Reset this player progress? This cannot be undone.')) return;
        try {
            await axios.post(`${API_BASE_URL}/admin/users/${userId}/reset`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            await fetchUsers(search);
            onMutate(userId);
        } catch (err) {
            setError('Failed to reset user progress');
        }
    };

    const adjustPoints = async (user) => {
        const newBanked = window.prompt('New banked points:', user.banked_points);
        if (newBanked === null) return;
        const newLifetime = window.prompt('New lifetime points:', user.lifetime_points);
        if (newLifetime === null) return;

        try {
            await axios.post(`${API_BASE_URL}/admin/users/${user.id}/adjust-points`, {
                banked_points: parseInt(newBanked, 10),
                lifetime_points: parseInt(newLifetime, 10),
            }, {
                headers: { 'X-Admin-Key': adminKey }
            });
            await fetchUsers(search);
            onMutate(user.id);
        } catch (err) {
            setError('Failed to adjust points');
        }
    };

    const columns = useMemo(() => ([
        { key: 'id', label: 'ID', render: (user) => `#${user.id}` },
        { key: 'username', label: 'Username' },
        { key: 'email', label: 'Email' },
        { key: 'total_score', label: 'Total Score', render: (user) => formatNumber(user.total_score) },
        { key: 'banked_points', label: 'Banked', render: (user) => formatNumber(user.banked_points) },
        { key: 'lifetime_points', label: 'Lifetime', render: (user) => formatNumber(user.lifetime_points) },
        { key: 'highest_level', label: 'Highest Level', render: (user) => formatNumber(user.highest_level) },
        { key: 'latest_activity_at', label: 'Latest Activity', render: (user) => formatDate(user.latest_activity_at) },
        {
            key: 'status',
            label: 'Status',
            render: (user) => <StatusBadge status={user.is_banned ? 'Banned' : 'Active'} />,
        },
        {
            key: 'actions',
            label: 'Actions',
            render: (user) => (
                <div className="action-cell">
                    <button
                        type="button"
                        className={selectedUserId === user.id ? 'btn-primary' : 'btn-secondary'}
                        onClick={() => onSelectUser(user.id)}
                    >
                        Inspect
                    </button>
                    <button type="button" className="btn-secondary" onClick={() => adjustPoints(user)}>
                        Pts
                    </button>
                    <button
                        type="button"
                        className={user.is_banned ? 'btn-primary' : 'btn-secondary'}
                        onClick={() => toggleBan(user)}
                    >
                        {user.is_banned ? 'Unban' : 'Ban'}
                    </button>
                    <button
                        type="button"
                        className="btn-danger"
                        onClick={() => resetProgress(user.id)}
                    >
                        Reset
                    </button>
                </div>
            ),
        },
    ]), [selectedUserId]);

    return (
        <div className="tab-panel">
            <div className="toolbar">
                <form onSubmit={handleSearch} className="toolbar-form">
                    <input
                        type="text"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        placeholder="Search by username or email"
                    />
                    <button type="submit" className="btn-primary">Search</button>
                    <button type="button" className="btn-secondary" onClick={() => { setSearch(''); fetchUsers(''); }}>
                        Clear
                    </button>
                </form>
            </div>

            {error && <div className="alert alert-error">{error}</div>}
            {loading ? <div className="loading">Loading users...</div> : (
                <DataTable columns={columns} rows={users} emptyMessage="No users found." />
            )}
        </div>
    );
}

function ReportsTab({ adminKey, onMutate, onSelectUser }) {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchReports = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/reports`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setReports(response.data);
            setError('');
        } catch (err) {
            setError('Failed to fetch reports');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminKey) fetchReports();
    }, [adminKey]);

    const updateStatus = async (reportId, status, reportedId) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/reports/${reportId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            await fetchReports();
            onMutate(reportedId);
        } catch (err) {
            setError('Failed to update report status');
        }
    };

    const columns = [
        { key: 'id', label: 'ID', render: (report) => `#${report.id}` },
        {
            key: 'reporter_id',
            label: 'Reporter',
            render: (report) => (
                <button type="button" className="link-button" onClick={() => onSelectUser(report.reporter_id)}>
                    User {report.reporter_id}
                </button>
            ),
        },
        {
            key: 'reported_id',
            label: 'Reported User',
            render: (report) => (
                <button type="button" className="link-button" onClick={() => onSelectUser(report.reported_id)}>
                    User {report.reported_id}
                </button>
            ),
        },
        { key: 'reason', label: 'Reason', render: (report) => truncate(report.reason) },
        { key: 'timestamp', label: 'Date', render: (report) => formatDate(report.timestamp) },
        { key: 'status', label: 'Status', render: (report) => <StatusBadge status={report.status} /> },
        {
            key: 'actions',
            label: 'Actions',
            render: (report) => (
                <div className="action-cell">
                    <button type="button" className="btn-primary" onClick={() => updateStatus(report.id, 'approved', report.reported_id)}>
                        Approve
                    </button>
                    <button type="button" className="btn-secondary" onClick={() => updateStatus(report.id, 'rejected', report.reported_id)}>
                        Reject
                    </button>
                </div>
            ),
        },
    ];

    return (
        <div className="tab-panel">
            {error && <div className="alert alert-error">{error}</div>}
            {loading ? <div className="loading">Loading reports...</div> : (
                <DataTable columns={columns} rows={reports} emptyMessage="No reports found." />
            )}
        </div>
    );
}

function AppealsTab({ adminKey, onMutate, onSelectUser }) {
    const [appeals, setAppeals] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchAppeals = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/appeals`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setAppeals(response.data);
            setError('');
        } catch (err) {
            setError('Failed to fetch appeals');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminKey) fetchAppeals();
    }, [adminKey]);

    const updateStatus = async (appealId, status, userId) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/appeals/${appealId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            await fetchAppeals();
            onMutate(userId);
        } catch (err) {
            setError('Failed to update appeal status');
        }
    };

    const columns = [
        { key: 'id', label: 'ID', render: (appeal) => `#${appeal.id}` },
        {
            key: 'user_id',
            label: 'User',
            render: (appeal) => (
                <button type="button" className="link-button" onClick={() => onSelectUser(appeal.user_id)}>
                    User {appeal.user_id}
                </button>
            ),
        },
        { key: 'appeal_text', label: 'Appeal', render: (appeal) => truncate(appeal.appeal_text) },
        { key: 'timestamp', label: 'Date', render: (appeal) => formatDate(appeal.timestamp) },
        { key: 'status', label: 'Status', render: (appeal) => <StatusBadge status={appeal.status} /> },
        {
            key: 'actions',
            label: 'Actions',
            render: (appeal) => (
                <div className="action-cell">
                    <button type="button" className="btn-primary" onClick={() => updateStatus(appeal.id, 'Approved', appeal.user_id)}>
                        Approve
                    </button>
                    <button type="button" className="btn-secondary" onClick={() => updateStatus(appeal.id, 'Rejected', appeal.user_id)}>
                        Reject
                    </button>
                </div>
            ),
        },
    ];

    return (
        <div className="tab-panel">
            {error && <div className="alert alert-error">{error}</div>}
            {loading ? <div className="loading">Loading appeals...</div> : (
                <DataTable columns={columns} rows={appeals} emptyMessage="No appeals found." />
            )}
        </div>
    );
}

function SupportTicketsTab({ adminKey, onMutate, onSelectUser }) {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchTickets = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/support/tickets`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setTickets(response.data);
            setError('');
        } catch (err) {
            setError('Failed to fetch support tickets');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminKey) fetchTickets();
    }, [adminKey]);

    const updateStatus = async (ticketId, status, userId) => {
        try {
            await axios.put(`${API_BASE_URL}/admin/support/tickets/${ticketId}?status=${status}`, {}, {
                headers: { 'X-Admin-Key': adminKey }
            });
            await fetchTickets();
            onMutate(userId);
        } catch (err) {
            setError('Failed to update ticket status');
        }
    };

    const columns = [
        { key: 'id', label: 'ID', render: (ticket) => `#${ticket.id}` },
        {
            key: 'user_id',
            label: 'User',
            render: (ticket) => (
                <button type="button" className="link-button" onClick={() => onSelectUser(ticket.user_id)}>
                    User {ticket.user_id}
                </button>
            ),
        },
        { key: 'type', label: 'Type' },
        { key: 'message', label: 'Message', render: (ticket) => truncate(ticket.message) },
        { key: 'timestamp', label: 'Date', render: (ticket) => formatDate(ticket.timestamp) },
        { key: 'status', label: 'Status', render: (ticket) => <StatusBadge status={ticket.status} /> },
        {
            key: 'actions',
            label: 'Actions',
            render: (ticket) => (
                <div className="action-cell">
                    <button type="button" className="btn-primary" onClick={() => updateStatus(ticket.id, 'Closed', ticket.user_id)}>
                        Close
                    </button>
                    <button type="button" className="btn-secondary" onClick={() => updateStatus(ticket.id, 'Open', ticket.user_id)}>
                        Reopen
                    </button>
                </div>
            ),
        },
    ];

    return (
        <div className="tab-panel">
            {error && <div className="alert alert-error">{error}</div>}
            {loading ? <div className="loading">Loading support tickets...</div> : (
                <DataTable columns={columns} rows={tickets} emptyMessage="No support tickets found." />
            )}
        </div>
    );
}

function TagList({ items, emptyLabel = 'None yet' }) {
    if (!items?.length) {
        return <div className="empty-state inline">{emptyLabel}</div>;
    }
    return (
        <div className="tag-list">
            {items.map((item) => <span className="tag" key={item}>{item}</span>)}
        </div>
    );
}

function LatestEventCard({ label, activity }) {
    return (
        <div className="list-card static">
            <div className="list-title">
                <strong>{label}</strong>
                <span>{activity?.created_at ? formatDate(activity.created_at) : 'No tracked event yet'}</span>
            </div>
            <p>{activity?.summary || 'Not available'}</p>
            {activity?.metadata ? <small>{JSON.stringify(activity.metadata)}</small> : null}
        </div>
    );
}

function UserDetailPanel({ adminKey, selectedUserId, refreshNonce, onRefreshComplete }) {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchDetails = async () => {
        if (!selectedUserId) {
            setData(null);
            return;
        }

        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/users/${selectedUserId}/details`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setData(response.data);
            setError('');
            onRefreshComplete?.();
        } catch (err) {
            setError('Failed to fetch player details');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDetails();
    }, [adminKey, selectedUserId, refreshNonce]);

    if (!selectedUserId) {
        return (
            <SectionCard title="Player Inspector" subtitle="Select a player to inspect their current game state and tracked activity.">
                <div className="empty-state">Pick a player from Overview, Users, Reports, Appeals, or Tickets.</div>
            </SectionCard>
        );
    }

    if (loading && !data) {
        return (
            <SectionCard title="Player Inspector">
                <div className="loading">Loading player details...</div>
            </SectionCard>
        );
    }

    if (error && !data) {
        return (
            <SectionCard title="Player Inspector">
                <div className="alert alert-error">{error}</div>
            </SectionCard>
        );
    }

    const user = data?.user;
    const latest = data?.latest || {};
    const moderation = data?.moderation || {};
    const achievements = user?.achievements || [];
    const unlockedAchievements = achievements.filter((item) => item.is_unlocked);

    return (
        <div className="detail-stack">
            {error && <div className="alert alert-error">{error}</div>}

            <SectionCard
                title={user ? `${user.username} Overview` : `User ${selectedUserId}`}
                subtitle="Current stored player state from the game backend."
                actions={<button type="button" className="btn-secondary" onClick={fetchDetails}>Refresh</button>}
            >
                {user ? (
                    <div className="detail-grid">
                        <div className="metric-card">
                            <span>Email</span>
                            <strong>{user.email}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Status</span>
                            <strong>{user.is_banned ? 'Banned' : 'Active'}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Created</span>
                            <strong>{formatDate(user.created_at)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Profile Picture</span>
                            <strong>{user.profile_picture || 'Default'}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Total Score</span>
                            <strong>{formatNumber(user.total_score)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Lifetime Points</span>
                            <strong>{formatNumber(user.lifetime_points)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Banked Points</span>
                            <strong>{formatNumber(user.banked_points)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Highest Level</span>
                            <strong>{formatNumber(user.highest_level)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Highest Score</span>
                            <strong>{formatNumber(user.highest_score)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Levels Cleared</span>
                            <strong>{formatNumber(user.levels_cleared)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Daily Challenge Streak</span>
                            <strong>{formatNumber(user.streak)}</strong>
                        </div>
                        <div className="metric-card">
                            <span>Colorblind Mode</span>
                            <strong>{user.colorblind_mode ? 'On' : 'Off'}</strong>
                        </div>
                    </div>
                ) : <div className="empty-state">No player data.</div>}
            </SectionCard>

            <SectionCard title="Inventory and Cosmetics" subtitle="Everything currently unlocked and selected in the live game state.">
                {user ? (
                    <div className="split-grid">
                        <div>
                            <h4>Selected</h4>
                            <div className="mini-list">
                                <div>Theme: {user.selected_theme}</div>
                                <div>Tap Sound: {user.selected_tap_sound}</div>
                                <div>Background Music: {user.selected_bg_music}</div>
                            </div>
                        </div>
                        <div>
                            <h4>Unlocked Themes</h4>
                            <TagList items={user.unlocked_themes} />
                        </div>
                        <div>
                            <h4>Unlocked Tap Sounds</h4>
                            <TagList items={user.unlocked_tap_sounds} />
                        </div>
                        <div>
                            <h4>Unlocked Background Music</h4>
                            <TagList items={user.unlocked_bg_music} />
                        </div>
                    </div>
                ) : null}
            </SectionCard>

            <SectionCard title="Achievements and Tutorials" subtitle="What the player has unlocked, claimed, and still has pending.">
                {user ? (
                    <div className="split-grid">
                        <div>
                            <h4>Achievement Summary</h4>
                            <div className="mini-list">
                                <div>Unlocked: {formatNumber(user.achievement_count)} / {formatNumber(user.achievement_total_count)}</div>
                                <div>Claimable Rewards: {formatNumber(user.claimable_reward_count)}</div>
                                <div>Claimed Reward IDs: {user.claimed_rewards?.length || 0}</div>
                            </div>
                            <div className="achievement-list">
                                {achievements.map((achievement) => (
                                    <div className="achievement-item" key={achievement.id}>
                                        <strong>{achievement.title}</strong>
                                        <span>
                                            {achievement.is_claimed ? 'Claimed' : achievement.is_unlocked ? 'Unlocked' : 'Locked'} | {achievement.current_value}/{achievement.target}
                                        </span>
                                    </div>
                                ))}
                            </div>
                        </div>
                        <div>
                            <h4>Tutorial State</h4>
                            <div className="mini-list">
                                <div>Tutorial Enabled: {user.tutorial_enabled ? 'Yes' : 'No'}</div>
                                <div>Pending Tutorials: {user.pending_tutorials?.length || 0}</div>
                            </div>
                            <h4>Completed Tutorials</h4>
                            <TagList items={user.completed_tutorials} />
                            <h4 style={{ marginTop: '16px' }}>Pending Tutorials</h4>
                            <TagList items={user.pending_tutorials} emptyLabel="No pending tutorials" />
                            <h4 style={{ marginTop: '16px' }}>Unlocked Achievements</h4>
                            <TagList items={unlockedAchievements.map((item) => item.title)} emptyLabel="No achievements unlocked yet" />
                        </div>
                    </div>
                ) : null}
            </SectionCard>

            <SectionCard title="Latest Tracked Actions" subtitle="Useful for validating whether an appeal or claim matches recent player behavior.">
                <div className="stack-list compact">
                    <LatestEventCard label="Latest Purchase" activity={latest.purchase} />
                    <LatestEventCard label="Latest Achievement Reward" activity={latest.achievement} />
                    <LatestEventCard label="Latest Daily Challenge" activity={latest.daily_challenge} />
                    <LatestEventCard label="Latest Level Completion" activity={latest.level_completion} />
                    <LatestEventCard label="Latest Theme Change" activity={latest.theme_change} />
                    <LatestEventCard label="Latest Tap Sound Change" activity={latest.tap_sound_change} />
                    <LatestEventCard label="Latest Background Music Change" activity={latest.bg_music_change} />
                </div>
            </SectionCard>

            <SectionCard title="Moderation Context" subtitle="Reports, appeals, and support records tied to this player.">
                <div className="split-grid">
                    <div>
                        <h4>Counts</h4>
                        <div className="mini-list">
                            <div>Reports Against: {formatNumber(moderation.report_count)}</div>
                            <div>Pending Reports Against: {formatNumber(moderation.pending_report_count)}</div>
                            <div>Appeals: {moderation.appeals?.length || 0}</div>
                            <div>Support Tickets: {moderation.support_tickets?.length || 0}</div>
                        </div>
                    </div>
                    <div>
                        <h4>Reports Against Player</h4>
                        <div className="stack-list compact">
                            {moderation.reports_against?.length ? moderation.reports_against.map((report) => (
                                <div className="list-card static" key={`against-${report.id}`}>
                                    <div className="list-title">
                                        <strong>Report #{report.id}</strong>
                                        <StatusBadge status={report.status} />
                                    </div>
                                    <p>Reporter: User {report.reporter_id}</p>
                                    <small>{truncate(report.reason, 120)}</small>
                                </div>
                            )) : <div className="empty-state">No reports against this player.</div>}
                        </div>
                    </div>
                    <div>
                        <h4>Reports Filed By Player</h4>
                        <div className="stack-list compact">
                            {moderation.reports_filed?.length ? moderation.reports_filed.map((report) => (
                                <div className="list-card static" key={`filed-${report.id}`}>
                                    <div className="list-title">
                                        <strong>Report #{report.id}</strong>
                                        <StatusBadge status={report.status} />
                                    </div>
                                    <p>Against User {report.reported_id}</p>
                                    <small>{truncate(report.reason, 120)}</small>
                                </div>
                            )) : <div className="empty-state">This player has not filed reports.</div>}
                        </div>
                    </div>
                    <div>
                        <h4>Appeals and Tickets</h4>
                        <div className="stack-list compact">
                            {moderation.appeals?.map((appeal) => (
                                <div className="list-card static" key={`appeal-${appeal.id}`}>
                                    <div className="list-title">
                                        <strong>Appeal #{appeal.id}</strong>
                                        <StatusBadge status={appeal.status} />
                                    </div>
                                    <small>{truncate(appeal.appeal_text, 120)}</small>
                                </div>
                            ))}
                            {moderation.support_tickets?.map((ticket) => (
                                <div className="list-card static" key={`ticket-${ticket.id}`}>
                                    <div className="list-title">
                                        <strong>{ticket.type}</strong>
                                        <StatusBadge status={ticket.status} />
                                    </div>
                                    <small>{truncate(ticket.message, 120)}</small>
                                </div>
                            ))}
                            {!moderation.appeals?.length && !moderation.support_tickets?.length ? (
                                <div className="empty-state">No appeals or support tickets for this player.</div>
                            ) : null}
                        </div>
                    </div>
                </div>
            </SectionCard>

            <SectionCard title="Recent Activity Timeline" subtitle="Newest tracked player actions first.">
                <div className="stack-list">
                    {data?.recent_activity?.length ? data.recent_activity.map((activity) => (
                        <div className="list-card static" key={activity.id}>
                            <div className="list-title">
                                <strong>{activity.event_label}</strong>
                                <span>{formatDate(activity.created_at)}</span>
                            </div>
                            <p>{activity.summary}</p>
                            {activity.metadata ? <small>{JSON.stringify(activity.metadata)}</small> : null}
                        </div>
                    )) : <div className="empty-state">No tracked activity for this player yet.</div>}
                </div>
            </SectionCard>
        </div>
    );
}

function Dashboard({ adminKey, onLogout }) {
    const [activeTab, setActiveTab] = useState('overview');
    const [overview, setOverview] = useState(null);
    const [overviewError, setOverviewError] = useState('');
    const [selectedUserId, setSelectedUserId] = useState(null);
    const [detailRefreshNonce, setDetailRefreshNonce] = useState(0);

    const fetchOverview = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/overview`, {
                headers: { 'X-Admin-Key': adminKey }
            });
            setOverview(response.data);
            setOverviewError('');
        } catch (err) {
            setOverviewError('Failed to fetch admin overview. Admin key may be invalid.');
            onLogout();
        }
    };

    useEffect(() => {
        fetchOverview();
        const interval = setInterval(fetchOverview, POLL_INTERVAL_MS);
        return () => clearInterval(interval);
    }, [adminKey]);

    const handleMutate = (userId) => {
        fetchOverview();
        if (userId) {
            setSelectedUserId(userId);
            setDetailRefreshNonce((value) => value + 1);
        }
    };

    return (
        <div>
            <header>
                <h1>Tap & Match Admin Dashboard</h1>
                <p>Dynamic player monitoring, moderation, and game-state verification.</p>
                <button
                    type="button"
                    onClick={onLogout}
                    className="logout-button"
                >
                    Logout
                </button>
            </header>

            {overviewError && <div className="alert alert-error">{overviewError}</div>}

            <StatsBar stats={overview?.stats} />

            <div className="tabs">
                {[
                    ['overview', 'Overview'],
                    ['users', 'Users'],
                    ['reports', 'Reports'],
                    ['appeals', 'Appeals'],
                    ['tickets', 'Support'],
                ].map(([value, label]) => (
                    <button
                        key={value}
                        type="button"
                        className={`tab-button ${activeTab === value ? 'active' : ''}`}
                        onClick={() => setActiveTab(value)}
                    >
                        {label}
                    </button>
                ))}
            </div>

            <div className="dashboard-shell">
                <div className="dashboard-main">
                    {activeTab === 'overview' && (
                        <OverviewTab
                            overview={overview}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                            }}
                        />
                    )}
                    {activeTab === 'users' && (
                        <UsersTab
                            adminKey={adminKey}
                            onMutate={handleMutate}
                            selectedUserId={selectedUserId}
                            onSelectUser={setSelectedUserId}
                        />
                    )}
                    {activeTab === 'reports' && (
                        <ReportsTab
                            adminKey={adminKey}
                            onMutate={handleMutate}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                            }}
                        />
                    )}
                    {activeTab === 'appeals' && (
                        <AppealsTab
                            adminKey={adminKey}
                            onMutate={handleMutate}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                            }}
                        />
                    )}
                    {activeTab === 'tickets' && (
                        <SupportTicketsTab
                            adminKey={adminKey}
                            onMutate={handleMutate}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                            }}
                        />
                    )}
                </div>

                <aside className="dashboard-side">
                    <UserDetailPanel
                        adminKey={adminKey}
                        selectedUserId={selectedUserId}
                        refreshNonce={detailRefreshNonce}
                    />
                </aside>
            </div>
        </div>
    );
}

export default function App() {
    const [adminKey, setAdminKey] = useState(localStorage.getItem('adminKey') || null);

    const handleAuth = (key) => {
        localStorage.setItem('adminKey', key);
        setAdminKey(key);
    };

    const handleLogout = () => {
        localStorage.removeItem('adminKey');
        setAdminKey(null);
    };

    return (
        <div className="container">
            {adminKey ? (
                <Dashboard adminKey={adminKey} onLogout={handleLogout} />
            ) : (
                <AuthComponent onAuth={handleAuth} />
            )}
        </div>
    );
}
