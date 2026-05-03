import React, { useEffect, useMemo, useState, useRef } from 'react';
import axios from 'axios';

// Use /api proxy in development (Vite), or fall back to absolute URL if needed.
// This allows the Vite proxy defined in vite.config.js to handle CORS.
const API_BASE_URL = window.location.hostname === 'localhost' ? '/api' : 'http://localhost:8000';
const POLL_INTERVAL_MS = 20000;
const THEME_NAME_MAP = {
    '#A9A9A9': 'Default',
    '#98EE99': 'Mint',
    '#2E1A47': 'Amethyst',
    '#1A3A5F': 'Ocean',
    '#FFA500': 'Orange',
    '#FFC0CB': 'Pink',
    '#00FF00': 'Lime',
    '#00FFFF': 'Cyan',
    '#FFD700': 'Gold',
    '#87CEEB': 'Sky Blue',
    '#228B22': 'Forest Green',
    '#301934': 'Deep Purple',
    '#FF4500': 'Sunset Orange',
    '#DC143C': 'Crimson Red',
    '#BF00FF': 'Electric Purple',
    '#800000': 'Maroon Velvet',
    '#191970': 'Midnight Blue',
    '#FF7F50': 'Coral Reef',
    '#40E0D0': 'Turquoise Dream',
    '#000080': 'Navy Commander',
    '#50C878': 'Emerald Green',
    '#FF69B4': 'Hot Pink',
    '#39FF14': 'Neon Green',
    '#E0E0E0': 'Pearl White',
    '#A020F0': 'Rainbow Prism',
    '#F8F8FF': 'Perfect White',
    '#FFFFFF': 'White',
    '#4B0082': 'Indigo',
    '#480082': 'Dark Indigo',
    '#C0C0C0': 'Silver',
    '#708090': 'Slate Gray',
    '#CD7F32': 'Bronze',
    'asset:assets/background/minecraft_bgColor.jpg': 'Minecraft Grass',
    'asset:assets/background/harvest_moon_background.jpeg': 'Harvest Moon',
    'asset:assets/background/genshin_background.jpeg': 'Genshin',
    'asset:assets/background/snowfall_background.jpeg': 'Snowfall',
};

const TAP_SOUND_NAME_MAP = {
    'audio/tap_sounds/default_tapSounds.mp3': 'Default Tap',
    'audio/tap_sounds/genshin_tap_sound.mp3': 'Genshin Tap',
    'audio/tap_sounds/minecraft_tap_sound.mp3': 'Minecraft Tap',
    'audio/tap_sounds/snowfall_tap_sound.mp3': 'Snowfall Tap',
};

const MUSIC_NAME_MAP = {
    'audio/background_music/stal_default.mp3': 'Default Music',
    'audio/background_music/genshin_bgMusic.mp3': 'Genshin BGM',
    'audio/background_music/minecraft_bgMusic.mp3': 'Minecraft BGM',
    'audio/background_music/harvestMoon.mp3': 'Harvest Moon BGM',
    'audio/background_music/snowfall_bgMusic.mp3': 'Snowfall BGM',
};

function buildAdminHeaders(adminToken) {
    return { Authorization: `Bearer ${adminToken}` };
}

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

function getAssetUrl(rawPath) {
    if (!rawPath || typeof rawPath !== 'string') return null;
    let path = rawPath;
    if (path.startsWith('asset:assets/')) {
        path = path.replace('asset:assets/', '');
    } else if (path.startsWith('audio/')) {
        path = `audio/${path.replace('audio/', '')}`;
    }
    return `${API_BASE_URL}/assets/${path}`;
}

function stripAssetPrefix(value) {
    if (!value || typeof value !== 'string') return '';
    return value
        .replace(/^asset:assets\//, '')
        .replace(/^assets\//, '')
        .replace(/^audio\//, '');
}

function prettifySegment(value) {
    return String(value || '')
        .replace(/\.[^/.]+$/, '')
        .replace(/[_-]+/g, ' ')
        .replace(/([a-z])([A-Z])/g, '$1 $2')
        .replace(/\s+/g, ' ')
        .trim()
        .replace(/\b\w/g, (char) => char.toUpperCase());
}

function findCaseInsensitiveMatch(source, key) {
    if (!key || typeof key !== 'string') return null;
    const normalized = key.trim().toLowerCase();
    return Object.entries(source).find(([candidate]) => candidate.toLowerCase() === normalized)?.[1] ?? null;
}

function formatThemeName(theme) {
    if (!theme || typeof theme !== 'string') return 'Default Theme';
    const namedTheme = findCaseInsensitiveMatch(THEME_NAME_MAP, theme);
    if (namedTheme) return namedTheme;
    if (theme.startsWith('#')) return `Theme ${theme.toUpperCase()}`;

    const cleanPath = stripAssetPrefix(theme);
    const parts = cleanPath.split('/').filter(Boolean);
    const fileName = parts[parts.length - 1] || theme;
    return prettifySegment(fileName);
}

function formatAudioName(assetPath, type = 'generic') {
    if (!assetPath || typeof assetPath !== 'string') return 'Not equipped';
    const source = type === 'tap' ? TAP_SOUND_NAME_MAP : type === 'music' ? MUSIC_NAME_MAP : null;
    const namedAudio = source ? findCaseInsensitiveMatch(source, assetPath) : null;
    if (namedAudio) return namedAudio;

    const cleanPath = stripAssetPrefix(assetPath);
    const parts = cleanPath.split('/').filter(Boolean);
    const fileName = parts[parts.length - 1] || assetPath;
    return prettifySegment(fileName);
}

function formatAudioCategory(assetPath) {
    if (!assetPath || typeof assetPath !== 'string') return '';

    const cleanPath = stripAssetPrefix(assetPath);
    const parts = cleanPath.split('/').filter(Boolean);
    if (parts.length <= 1) return 'Custom audio';
    return prettifySegment(parts.slice(0, -1).join(' '));
}

function formatInventoryMeta(item, kind) {
    if (kind === 'theme') {
        return (typeof item === 'string' && item.startsWith('#')) ? 'Solid color background' : 'Custom background asset';
    }
    return formatAudioCategory(item);
}

function AudioPreviewButton({ assetPath, label }) {
    const [isPlaying, setIsPlaying] = useState(false);
    const audioRef = useRef(null);

    const togglePlay = (e) => {
        e.stopPropagation();
        if (!audioRef.current) {
            const url = getAssetUrl(assetPath);
            if (!url) return;
            audioRef.current = new Audio(url);
            audioRef.current.onended = () => setIsPlaying(false);
        }

        if (isPlaying) {
            audioRef.current.pause();
            audioRef.current.currentTime = 0;
            setIsPlaying(false);
        } else {
            audioRef.current.play().catch(err => console.error("Audio play failed:", err));
            setIsPlaying(true);
        }
    };

    if (!assetPath) return null;
    return (
        <button 
            type="button" 
            className={`btn-icon-only ${isPlaying ? 'btn-primary' : 'btn-secondary'}`}
            onClick={togglePlay}
            title={`${isPlaying ? 'Stop' : 'Play'} ${label}`}
            style={{ marginLeft: 'auto' }}
        >
            {isPlaying ? 'Stop' : 'Play'}
        </button>
    );
}

function ThemeHoverPreview({ theme }) {
    const [isHovered, setIsHovered] = useState(false);
    
    const isHex = theme?.startsWith('#');
    const assetUrl = !isHex ? getAssetUrl(theme) : null;
    const displayName = formatThemeName(theme);

    return (
        <div 
            className="theme-preview-wrapper"
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
        >
            <strong className="eq-val">{displayName}</strong>
            {isHovered && (
                <div className="theme-floating-preview">
                    {isHex ? (
                        <div className="color-box" style={{ backgroundColor: theme }}></div>
                    ) : (
                        <img src={assetUrl} alt="Theme Preview" className="image-preview" />
                    )}
                </div>
            )}
        </div>
    );
}

function InventoryList({ items, kind, emptyLabel = 'None yet' }) {
    if (!Array.isArray(items) || items.length === 0) {
        return <div className="empty-state inline">{emptyLabel}</div>;
    }

    return (
        <div className="inventory-list">
            {items.map((item, idx) => {
                if (!item) return null;
                return (
                    <div className="inventory-item" key={`${kind}-${item}-${idx}`}>
                        <div className="eq-head">
                            <span className="eq-icon" aria-hidden="true">
                                {kind === 'theme' ? 'TH' : kind === 'tap' ? 'FX' : 'BG'}
                            </span>
                            <div className="eq-copy">
                                <span className="eq-label">
                                    {kind === 'theme' ? 'Theme' : kind === 'tap' ? 'Tap Sound' : 'Background Music'}
                                </span>
                                {kind === 'theme' ? (
                                    <ThemeHoverPreview theme={item} />
                                ) : (
                                    <strong className="eq-val">{formatAudioName(item, kind)}</strong>
                                )}
                                <small className="eq-meta">{formatInventoryMeta(item, kind)}</small>
                            </div>
                            {kind !== 'theme' && typeof item === 'string' && (
                                <AudioPreviewButton
                                    assetPath={item}
                                    label={kind === 'tap' ? 'Tap Sound' : 'Background Music'}
                                />
                            )}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

function AuthComponent({ onAuth }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [code, setCode] = useState('');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [codeSent, setCodeSent] = useState(false);
    const [isSendingCode, setIsSendingCode] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [step, setStep] = useState(1);

    const resetFeedback = () => {
        setError('');
        setMessage('');
    };

    const handleSendCode = async () => {
        const normalizedEmail = email.trim().toLowerCase();
        if (!normalizedEmail.endsWith('@gmail.com')) {
            setError('Enter a valid Gmail address.');
            return;
        }

        setIsSendingCode(true);
        resetFeedback();
        try {
            const response = await axios.post(`${API_BASE_URL}/admin/send-code`, {
                email: normalizedEmail,
            });
            setMessage(response.data?.message || 'Verification code sent.');
            setCodeSent(true);
            setStep(2);
        } catch (err) {
            setError(err.response?.data?.detail || 'Failed to send verification code.');
        } finally {
            setIsSendingCode(false);
        }
    };

    const handleContinueFromCode = () => {
        if (!code.trim()) {
            setError('Enter the 6-digit code before continuing.');
            return;
        }
        setError('');
        setMessage('');
        setStep(3);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const normalizedEmail = email.trim().toLowerCase();

        if (!normalizedEmail || !password.trim() || !code.trim()) {
            setError('Email, password, and verification code are required.');
            return;
        }

        setIsSubmitting(true);
        resetFeedback();
        try {
            const response = await axios.post(`${API_BASE_URL}/admin/login`, {
                email: normalizedEmail,
                password: password.trim(),
                code: code.trim(),
            });
            onAuth(response.data);
        } catch (err) {
            setError(err.response?.data?.detail || 'Admin login failed.');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="auth-section">
            <h2>Tap & Match Admin Dashboard</h2>
            <p style={{ marginBottom: '16px', color: '#6b6258', lineHeight: 1.5 }}>
                Step 1: enter your Gmail, Step 2: enter the code, Step 3: enter the admin password.
            </p>
            <div className="auth-steps">
                <span className={step === 1 ? 'is-active' : step > 1 ? 'is-done' : ''}>1. Gmail</span>
                <span className={step === 2 ? 'is-active' : step > 2 ? 'is-done' : ''}>2. Code</span>
                <span className={step === 3 ? 'is-active' : ''}>3. Password</span>
            </div>
            <form onSubmit={handleSubmit}>
                {step === 1 && (
                    <div className="auth-page">
                        <div className="form-group">
                            <label htmlFor="adminEmail">Gmail Address</label>
                            <input
                                id="adminEmail"
                                type="email"
                                value={email}
                                onChange={(e) => {
                                    setEmail(e.target.value);
                                    resetFeedback();
                                }}
                                placeholder="you@gmail.com"
                            />
                        </div>
                        <button
                            type="button"
                            className="btn-primary"
                            style={{ width: '100%' }}
                            onClick={handleSendCode}
                            disabled={isSendingCode}
                        >
                            {isSendingCode ? 'Sending Code...' : codeSent ? 'Resend Code' : 'Send Code'}
                        </button>
                    </div>
                )}
                {step === 2 && (
                    <div className="auth-page">
                        <div className="page-note">
                            Code sent to <strong>{email}</strong>
                        </div>
                        <div className="form-group">
                            <label htmlFor="adminCode">Enter 6 Digit Code</label>
                            <input
                                id="adminCode"
                                type="text"
                                inputMode="numeric"
                                maxLength={6}
                                value={code}
                                onChange={(e) => {
                                    setCode(e.target.value);
                                    resetFeedback();
                                }}
                                placeholder="000000"
                            />
                        </div>
                        <div className="auth-actions">
                            <button type="button" className="btn-secondary" onClick={() => setStep(1)}>
                                Back
                            </button>
                            <button type="button" className="btn-primary" onClick={handleContinueFromCode}>
                                Continue
                            </button>
                        </div>
                    </div>
                )}
                {step === 3 && (
                    <div className="auth-page">
                        <div className="page-note">
                            Signing in as <strong>{email}</strong>
                        </div>
                        <div className="form-group">
                            <label htmlFor="adminPassword">Admin Password</label>
                            <input
                                id="adminPassword"
                                type="password"
                                value={password}
                                onChange={(e) => {
                                    setPassword(e.target.value);
                                    resetFeedback();
                                }}
                                placeholder="Enter admin password"
                            />
                        </div>
                        <div className="auth-actions">
                            <button type="button" className="btn-secondary" onClick={() => setStep(2)}>
                                Back
                            </button>
                            <button type="submit" className="btn-primary" disabled={isSubmitting}>
                                {isSubmitting ? 'Signing In...' : 'Login'}
                            </button>
                        </div>
                    </div>
                )}
                {message && <div className="alert alert-success">{message}</div>}
                {error && <div className="alert alert-error">{error}</div>}
            </form>
        </div>
    );
}

function StatsBar({ stats, onStatClick }) {
    const cards = [
        { id: 'total', label: 'Total Users', value: stats?.total_users, targetTab: 'users' },
        { id: 'new', label: 'New Users Today', value: stats?.new_users_today, targetTab: 'users' },
        { id: 'banned', label: 'Banned Users', value: stats?.banned_users, targetTab: 'users' },
        { id: 'appeals', label: 'Pending Appeals', value: stats?.pending_appeals, targetTab: 'appeals' },
        { id: 'tickets', label: 'Open Tickets', value: stats?.open_tickets, targetTab: 'tickets' },
    ];

    return (
        <div className="stats">
            {cards.map((card) => (
                <button 
                    type="button"
                    className="stat-card interactable" 
                    key={card.label}
                    onClick={() => onStatClick(card.targetTab, card.id)}
                >
                    <h3>{card.label}</h3>
                    <div className="number">{formatNumber(card.value)}</div>
                    <div className="stat-hint">Click to view</div>
                </button>
            ))}
        </div>
    );
}

function StatusBadge({ status, isOnline }) {
    if (isOnline) {
        return (
            <span className="status-badge status-online">
                <span className="online-dot"></span> Online
            </span>
        );
    }
    return (
        <span className={`status-badge status-${statusClassName(status)}`}>
            {status || 'Unknown'}
        </span>
    );
}

function SectionCard({ title, subtitle, children, actions, collapsible, defaultExpanded = true }) {
    const [isExpanded, setIsExpanded] = useState(defaultExpanded);

    return (
        <section className={`panel-card ${collapsible ? 'collapsible' : ''} ${isExpanded ? 'is-expanded' : 'is-collapsed'}`}>
            <div className="panel-header" onClick={() => collapsible && setIsExpanded(!isExpanded)} style={{ cursor: collapsible ? 'pointer' : 'default' }}>
                <div>
                    <h3>
                        {title}
                        {collapsible && <span className="collapse-icon">{isExpanded ? '▼' : '▶'}</span>}
                    </h3>
                    {subtitle && <p>{subtitle}</p>}
                </div>
                {actions}
            </div>
            {(isExpanded || !collapsible) && <div className="panel-content">{children}</div>}
        </section>
    );
}

function OverviewTab({ overview, onSelectUser }) {
    const [activitySearch, setActivitySearch] = useState('');
    const [playerSearch, setPlayerSearch] = useState('');

    const filteredActivity = useMemo(() => {
        const activities = overview?.recent_activity;
        if (!Array.isArray(activities)) return [];
        if (!activitySearch.trim()) return activities;
        const query = activitySearch.toLowerCase();
        return activities.filter(
            (a) =>
                a && (
                    (String(a.username || '')).toLowerCase().includes(query) ||
                    (String(a.event_label || '')).toLowerCase().includes(query) ||
                    (String(a.summary || '')).toLowerCase().includes(query)
                )
        );
    }, [overview?.recent_activity, activitySearch]);

    const filteredTopPlayers = useMemo(() => {
        const players = overview?.top_players;
        if (!Array.isArray(players)) return [];
        if (!playerSearch.trim()) return players;
        const query = playerSearch.toLowerCase();
        return players.filter(
            (p) =>
                p && (
                    (String(p.username || '')).toLowerCase().includes(query) ||
                    (String(p.email || '')).toLowerCase().includes(query)
                )
        );
    }, [overview?.top_players, playerSearch]);

    if (!overview) {
        return <div className="loading">Loading overview...</div>;
    }

    return (
        <div className="overview-grid">
            <SectionCard title="Recent Activity" subtitle="Latest tracked player actions from the live game.">
                <div className="form-group" style={{ marginBottom: '16px' }}>
                    <input
                        type="text"
                        placeholder="Search players, actions, or summaries..."
                        value={activitySearch}
                        onChange={(e) => setActivitySearch(e.target.value)}
                        style={{ width: '100%', padding: '8px 12px' }}
                    />
                </div>
                <div className="stack-list overview-scroll-container">
                    {filteredActivity.length ? filteredActivity.map((activity) => (
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
                    )) : <div className="empty-state">No matching player activity found.</div>}
                </div>
            </SectionCard>

            <SectionCard title="Top Players" subtitle="Current leaderboard snapshot from game data.">
                <div className="form-group" style={{ marginBottom: '16px' }}>
                    <input
                        type="text"
                        placeholder="Search top players..."
                        value={playerSearch}
                        onChange={(e) => setPlayerSearch(e.target.value)}
                        style={{ width: '100%', padding: '8px 12px' }}
                    />
                </div>
                <div className="stack-list compact overview-scroll-container">
                    {filteredTopPlayers.length ? filteredTopPlayers.map((player) => (
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
                    )) : <div className="empty-state">No matching players found.</div>}
                </div>
            </SectionCard>

            <SectionCard title="Needs Attention" subtitle="Open moderation items that still need admin action.">
                <div className="attention-grid">
                    <div>
                        <h4>Pending Appeals</h4>
                        <div className="stack-list compact">
                            {overview.attention_queue?.pending_appeals?.length ? overview.attention_queue.pending_appeals.map((appeal) => (
                                <button
                                    type="button"
                                    className="list-card"
                                    key={`appeal-${appeal.id}`}
                                    onClick={() => onSelectUser(appeal.user_id)}
                                >
                                    <div className="list-title">
                                        <strong>Appeal #{appeal.id}</strong>
                                        <StatusBadge status={appeal.status} />
                                    </div>
                                    <p>User {appeal.user_id}</p>
                                    <small>{truncate(appeal.appeal_text, 90)}</small>
                                </button>
                            )) : <div className="empty-state">No pending appeals.</div>}
                        </div>
                    </div>
                </div>
            </SectionCard>
        </div>
    );
}

function DataTable({ columns, rows, emptyMessage, onRowClick, selectedId }) {
    return (
        <div className="table-container">
            <table>
                <thead>
                    <tr>
                        {columns.map((column) => <th key={column.key}>{column.label}</th>)}
                    </tr>
                </thead>
                <tbody>
                    {!Array.isArray(rows) || !rows.length ? (
                        <tr>
                            <td colSpan={columns.length}>
                                <div className="empty-state">{emptyMessage}</div>
                            </td>
                        </tr>
                    ) : rows.map((row, rowIndex) => {
                        if (!row) return null;
                        return (
                            <tr 
                                key={row.id ?? rowIndex} 
                                onClick={() => onRowClick?.(row.id)}
                                className={`${onRowClick ? 'clickable-row' : ''} ${selectedId === row.id ? 'selected-row' : ''}`}
                            >
                                {columns.map((column) => (
                                    <td key={column.key}>
                                        {column.render ? column.render(row) : row[column.key]}
                                    </td>
                                ))}
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    );
}

function UsersTab({ adminToken, onMutate, onSelectUser, selectedUserId, initialFilter = '' }) {
    const [users, setUsers] = useState([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchUsers = async (searchTerm = search) => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/users?search=${encodeURIComponent(searchTerm)}`, {
                headers: buildAdminHeaders(adminToken)
            });
            
            let filteredData = response.data;
            if (searchTerm === 'filter:banned') {
                filteredData = filteredData.filter(u => u.is_banned);
            } else if (searchTerm === 'filter:new') {
                const today = new Date().toISOString().split('T')[0];
                filteredData = filteredData.filter(u => u.created_at && u.created_at.startsWith(today));
            }

            setUsers(filteredData);
            setError('');
        } catch (err) {
            setError('Failed to fetch users');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminToken) {
            fetchUsers(initialFilter);
            setSearch(initialFilter.startsWith('filter:') ? '' : initialFilter);
        }
    }, [adminToken, initialFilter]);

    const handleSearch = (e) => {
        e.preventDefault();
        fetchUsers(search);
    };

    const toggleBan = async (user, e) => {
        e.stopPropagation();
        try {
            if (user.is_banned) {
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/unban`, {}, {
                    headers: buildAdminHeaders(adminToken)
                });
            } else {
                const reason = window.prompt('Enter ban reason:', user.ban_reason || 'Rules violation');
                if (reason === null) return;
                await axios.put(`${API_BASE_URL}/admin/users/${user.id}/ban`, { reason }, {
                    headers: buildAdminHeaders(adminToken)
                });
            }
            await fetchUsers(search);
            onMutate(user.id);
        } catch (err) {
            setError('Failed to update ban status');
        }
    };

    const resetProgress = async (userId, e) => {
        e.stopPropagation();
        if (!window.confirm('Reset this player progress? This cannot be undone.')) return;
        try {
            await axios.post(`${API_BASE_URL}/admin/users/${userId}/reset`, {}, {
                headers: buildAdminHeaders(adminToken)
            });
            await fetchUsers(search);
            onMutate(userId);
        } catch (err) {
            setError('Failed to reset user progress');
        }
    };

    const columns = useMemo(() => ([
        { key: 'id', label: 'ID', render: (user) => `#${user.id}` },
        { 
            key: 'username', 
            label: 'Username',
            render: (user) => (
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {user.is_online && <span className="online-indicator-dot" title="Online now"></span>}
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <span style={{ fontWeight: 'bold' }}>{user.username}</span>
                        <small style={{ color: '#6b6258', fontSize: '11px' }}>{user.email}</small>
                    </div>
                </div>
            )
        },
        { 
            key: 'activity', 
            label: 'Current Status', 
            render: (user) => (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 'bold' }}>
                        {user.is_online ? (
                            <span style={{ color: '#2e7d32', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <span className="online-dot"></span> Online
                            </span>
                        ) : (
                            <span style={{ color: '#6b6258' }}>Offline</span>
                        )}
                    </div>
                    <small style={{ color: '#6b6258' }}>Seen: {formatDate(user.latest_activity_at)}</small>
                </div>
            )
        },
        {
            key: 'actions',
            label: 'Actions',
            render: (user) => (
                <div className="action-cell">
                    <button
                        type="button"
                        className={user.is_banned ? 'btn-primary btn-icon-only' : 'btn-secondary btn-icon-only'}
                        onClick={(e) => toggleBan(user, e)}
                        title={user.is_banned ? 'Unban' : 'Ban'}
                    >
                        {user.is_banned ? 'U' : 'B'}
                    </button>
                    <button
                        type="button"
                        className="btn-danger btn-icon-only"
                        onClick={(e) => resetProgress(user.id, e)}
                        title="Reset Progress"
                    >
                        R
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
                {initialFilter && (
                    <div className="filter-tag">
                        Showing: {initialFilter.replace('filter:', '')}
                        <button type="button" onClick={() => fetchUsers('')}>x</button>
                    </div>
                )}
            </div>

            {error && <div className="alert alert-error">{error}</div>}
            {loading ? <div className="loading">Loading users...</div> : (
                <DataTable 
                    columns={columns} 
                    rows={users} 
                    emptyMessage="No users found." 
                    onRowClick={onSelectUser}
                    selectedId={selectedUserId}
                />
            )}
        </div>
    );
}

function AppealsTab({ adminToken, onMutate, onSelectUser, filterStatus = '' }) {
    const [appeals, setAppeals] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchAppeals = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/appeals`, {
                headers: buildAdminHeaders(adminToken)
            });
            let data = response.data;
            if (filterStatus) {
                data = data.filter(a => a.status === filterStatus);
            }
            setAppeals(data);
            setError('');
        } catch (err) {
            setError('Failed to fetch appeals');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminToken) fetchAppeals();
    }, [adminToken, filterStatus]);

    const updateStatus = async (appealId, status, userId, e) => {
        e.stopPropagation();
        try {
            await axios.put(`${API_BASE_URL}/admin/appeals/${appealId}?status=${status}`, {}, {
                headers: buildAdminHeaders(adminToken)
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
                <span className="link-text">User {appeal.user_id}</span>
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
                    <button type="button" className="btn-primary" onClick={(e) => updateStatus(appeal.id, 'Approved', appeal.user_id, e)}>
                        Approve
                    </button>
                    <button type="button" className="btn-secondary" onClick={(e) => updateStatus(appeal.id, 'Rejected', appeal.user_id, e)}>
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
                <DataTable columns={columns} rows={appeals} emptyMessage="No appeals found." onRowClick={onSelectUser} />
            )}
        </div>
    );
}

function SupportTicketsTab({ adminToken, onMutate, onSelectUser, filterStatus = '' }) {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const fetchTickets = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/support/tickets`, {
                headers: buildAdminHeaders(adminToken)
            });
            let data = response.data;
            if (filterStatus) {
                data = data.filter(t => t.status === filterStatus);
            }
            setTickets(data);
            setError('');
        } catch (err) {
            setError('Failed to fetch support tickets');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (adminToken) fetchTickets();
    }, [adminToken, filterStatus]);

    const updateStatus = async (ticketId, status, userId, e) => {
        e.stopPropagation();
        try {
            await axios.put(`${API_BASE_URL}/admin/support/tickets/${ticketId}?status=${status}`, {}, {
                headers: buildAdminHeaders(adminToken)
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
                <span className="link-text">User {ticket.user_id}</span>
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
                    <button type="button" className="btn-primary" onClick={(e) => updateStatus(ticket.id, 'Closed', ticket.user_id, e)}>
                        Close
                    </button>
                    <button type="button" className="btn-secondary" onClick={(e) => updateStatus(ticket.id, 'Open', ticket.user_id, e)}>
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
                <DataTable columns={columns} rows={tickets} emptyMessage="No support tickets found." onRowClick={onSelectUser} />
            )}
        </div>
    );
}

class ErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        console.error("Dashboard Error:", error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="alert alert-error" style={{ margin: '20px', padding: '20px' }}>
                    <h3>Something went wrong.</h3>
                    <p>{this.state.error?.toString()}</p>
                    <button 
                        className="btn-primary" 
                        style={{ marginTop: '12px' }}
                        onClick={() => window.location.reload()}
                    >
                        Reload Page
                    </button>
                </div>
            );
        }
        return this.props.children;
    }
}

function UserDetailPanel({ adminToken, selectedUserId, refreshNonce, onRefreshComplete }) {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [activitySearch, setActivitySearch] = useState('');

    const filteredActivity = useMemo(() => {
        const activities = data?.recent_activity;
        if (!Array.isArray(activities)) return [];
        if (!activitySearch.trim()) return activities;
        const query = activitySearch.toLowerCase();
        return activities.filter(
            (a) =>
                a && (
                    (String(a.event_label || '')).toLowerCase().includes(query) ||
                    (String(a.summary || '')).toLowerCase().includes(query)
                )
        );
    }, [data?.recent_activity, activitySearch]);

    const fetchDetails = async () => {
        if (!selectedUserId) {
            setData(null);
            return;
        }

        setLoading(true);
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/users/${selectedUserId}/details`, {
                headers: buildAdminHeaders(adminToken)
            });
            setData(response.data);
            setError('');
            onRefreshComplete?.();
        } catch (err) {
            console.error("Fetch Details Error:", err);
            setError('Failed to fetch player details');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        setActivitySearch(''); // Reset search when switching users
        fetchDetails();
    }, [adminToken, selectedUserId, refreshNonce]);

    if (!selectedUserId) {
        return (
            <SectionCard title="Player Inspector" subtitle="Select a player to inspect their current game state and tracked activity.">
                <div className="empty-state">Pick a player from Overview, Users, Appeals, or Tickets.</div>
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

    const user = data?.user;
    const achievements = user?.achievements || [];

    const fiveMinutesAgo = new Date(Date.now() - 5 * 60000);
    const isOnline = user?.last_active_at && new Date(user.last_active_at) >= fiveMinutesAgo;

    return (
        <div className="detail-stack">
            {(error || (!loading && !user)) && (
                <div className="alert alert-error">{error || 'Player not found or data missing.'}</div>
            )}

            <SectionCard
                title={user ? `${user.username} Overview` : `User ${selectedUserId}`}
                subtitle="Current stored player state from the game backend."
                actions={<button type="button" className="btn-secondary" onClick={fetchDetails} disabled={loading}>Refresh</button>}
            >
                {user ? (
                    <div className="detail-grid">
                        <div className="metric-card">
                            <span>Status</span>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <strong>{user.is_banned ? 'Banned' : 'Active'}</strong>
                                {isOnline && <span className="online-indicator-dot"></span>}
                                {isOnline && <small style={{ color: '#4CAF50' }}>Online Now</small>}
                            </div>
                        </div>
                        <div className="metric-card"><span>Email</span><strong>{user.email || '-'}</strong></div>
                        <div className="metric-card"><span>Created</span><strong>{formatDate(user.created_at)}</strong></div>
                        <div className="metric-card"><span>Last Active</span><strong>{formatDate(user.last_active_at)}</strong></div>
                        <div className="metric-card"><span>Total Score</span><strong>{formatNumber(user.total_score)}</strong></div>
                        <div className="metric-card"><span>Lifetime Pts</span><strong>{formatNumber(user.lifetime_points)}</strong></div>
                        <div className="metric-card"><span>Banked Pts</span><strong>{formatNumber(user.banked_points)}</strong></div>
                        <div className="metric-card"><span>Highest Lv</span><strong>{formatNumber(user.highest_level)}</strong></div>
                        <div className="metric-card"><span>Lv Cleared</span><strong>{formatNumber(user.levels_cleared)}</strong></div>
                        <div className="metric-card"><span>Streak</span><strong>{formatNumber(user.streak)}</strong></div>
                        <div className="metric-card"><span>Colorblind</span><strong>{user.colorblind_mode ? 'On' : 'Off'}</strong></div>
                    </div>
                ) : <div className="empty-state">No player data available.</div>}
            </SectionCard>

            <SectionCard title="Inventory & Cosmetics" subtitle="Equipped and unlocked items." collapsible defaultExpanded={false}>
                {user ? (
                    <div className="inventory-v3 inventory-scroll-container">
                        <div className="equipped-panel">
                            <h4>Current Gear</h4>
                            <div className="eq-stack">
                                <div className="eq-box">
                                    <div className="eq-head">
                                        <span className="eq-icon" aria-hidden="true">TH</span>
                                        <div className="eq-copy">
                                            <span className="eq-label">Theme</span>
                                            <ThemeHoverPreview theme={user.selected_theme} />
                                            <small className="eq-meta">
                                                {user.selected_theme?.startsWith('#') ? 'Solid color background' : 'Custom background asset'}
                                            </small>
                                        </div>
                                    </div>
                                </div>
                                <div className="eq-box">
                                    <div className="eq-head">
                                        <span className="eq-icon" aria-hidden="true">FX</span>
                                        <div className="eq-copy">
                                            <span className="eq-label">Tap Sound</span>
                                            <strong className="eq-val">{formatAudioName(user.selected_tap_sound, 'tap')}</strong>
                                            <small className="eq-meta">{formatAudioCategory(user.selected_tap_sound)}</small>
                                        </div>
                                        <AudioPreviewButton assetPath={user.selected_tap_sound} label="Tap Sound" />
                                    </div>
                                </div>
                                <div className="eq-box">
                                    <div className="eq-head">
                                        <span className="eq-icon" aria-hidden="true">BG</span>
                                        <div className="eq-copy">
                                            <span className="eq-label">Background Music</span>
                                            <strong className="eq-val">{formatAudioName(user.selected_bg_music, 'music')}</strong>
                                            <small className="eq-meta">{formatAudioCategory(user.selected_bg_music)}</small>
                                        </div>
                                        <AudioPreviewButton assetPath={user.selected_bg_music} label="Background Music" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="unlocked-panel">
                            <div className="un-group">
                                <h4>Unlocked Themes</h4>
                                <InventoryList items={user.unlocked_themes} kind="theme" />
                            </div>
                            <div className="un-group">
                                <h4>Unlocked Tap Sounds</h4>
                                <InventoryList items={user.unlocked_tap_sounds} kind="tap" />
                            </div>
                            <div className="un-group">
                                <h4>Unlocked Background Music</h4>
                                <InventoryList items={user.unlocked_bg_music} kind="music" />
                            </div>
                        </div>
                    </div>
                ) : null}
            </SectionCard>

            <SectionCard title="Achievements" subtitle="Progress and unlocked rewards." collapsible defaultExpanded={false}>
                {user ? (
                    <div className="achievement-grid-full">
                        <h4>Progress Summary</h4>
                        <div className="mini-list" style={{marginBottom: '12px'}}>
                            <div>Unlocked: {formatNumber(user.achievement_count)} / {formatNumber(user.achievement_total_count)}</div>
                            <div>Claimable: {formatNumber(user.claimable_reward_count)}</div>
                        </div>
                        <div className="achievement-list-dashboard">
                            {achievements.map((achievement) => (
                                <div className={`achievement-item ${achievement.is_unlocked ? 'is-unlocked' : ''}`} key={achievement.id}>
                                    <div className="ach-main">
                                        <strong>{achievement.title}</strong>
                                        <p>{achievement.description}</p>
                                    </div>
                                    <div className="ach-status">
                                        <span className={`status-badge ${achievement.is_claimed ? 'status-closed' : achievement.is_unlocked ? 'status-approved' : 'status-pending'}`}>
                                            {achievement.is_claimed ? 'Claimed' : achievement.is_unlocked ? 'Unlocked' : 'Locked'}
                                        </span>
                                        <small>{achievement.current_value} / {achievement.target}</small>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                ) : null}
            </SectionCard>

            <SectionCard title="Recent Activity Timeline" subtitle="Newest tracked player actions." collapsible defaultExpanded={true}>
                <div className="form-group" style={{ marginBottom: '16px' }}>
                    <input
                        type="text"
                        placeholder="Search actions or summaries..."
                        value={activitySearch}
                        onChange={(e) => setActivitySearch(e.target.value)}
                        style={{ width: '100%', padding: '8px 12px' }}
                    />
                </div>
                <div className="stack-list timeline-scroll-container">
                    {filteredActivity.length ? filteredActivity.map((activity) => (
                        <div className="list-card static" key={activity.id}>
                            <div className="list-title">
                                <strong>{activity.event_label}</strong>
                                <span>{formatDate(activity.created_at)}</span>
                            </div>
                            <p>{activity.summary}</p>
                        </div>
                    )) : <div className="empty-state">No matching tracked activity found.</div>}
                </div>
            </SectionCard>
        </div>
    );
}

function Dashboard({ adminToken, adminEmail, onLogout }) {
    const [activeTab, setActiveTab] = useState('overview');
    const [overview, setOverview] = useState(null);
    const [overviewError, setOverviewError] = useState('');
    const [selectedUserId, setSelectedUserId] = useState(null);
    const [detailRefreshNonce, setDetailRefreshNonce] = useState(0);
    const [userFilter, setUserFilter] = useState('');
    const [appealFilter, setAppealFilter] = useState('');
    const [ticketFilter, setTicketFilter] = useState('');

    const fetchOverview = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/admin/overview`, {
                headers: buildAdminHeaders(adminToken)
            });
            setOverview(response.data);
            setOverviewError('');
        } catch (err) {
            setOverviewError('Failed to fetch admin overview. Your admin session may be invalid or expired.');
            onLogout();
        }
    };

    useEffect(() => {
        fetchOverview();
        const interval = setInterval(fetchOverview, POLL_INTERVAL_MS);
        return () => clearInterval(interval);
    }, [adminToken]);

    const handleMutate = (userId) => {
        fetchOverview();
        if (userId) {
            setSelectedUserId(userId);
            setDetailRefreshNonce((value) => value + 1);
        }
    };

    const handleStatClick = (tab, statId) => {
        setActiveTab(tab);
        if (tab === 'users') {
            if (statId === 'banned') setUserFilter('filter:banned');
            else if (statId === 'new') setUserFilter('filter:new');
            else setUserFilter('');
        } else if (tab === 'appeals') {
            setAppealFilter('Pending');
        } else if (tab === 'tickets') {
            setTicketFilter('Open');
        }
    };

    return (
        <div>
            <header>
                <div className="header-content">
                    <h1>Tap & Match Admin Dashboard</h1>
                    <p>Dynamic player monitoring, moderation, and game-state verification.</p>
                    {adminEmail ? <small>Signed in as {adminEmail}</small> : null}
                </div>
                <button
                    type="button"
                    onClick={onLogout}
                    className="logout-button"
                >
                    Logout
                </button>
            </header>

            {overviewError && <div className="alert alert-error">{overviewError}</div>}

            <StatsBar stats={overview?.stats} onStatClick={handleStatClick} />

            <div className="tabs">
                {[
                    ['overview', 'Overview'],
                    ['users', 'Users'],
                    ['appeals', 'Appeals'],
                    ['tickets', 'Support'],
                ].map(([value, label]) => (
                    <button
                        key={value}
                        type="button"
                        className={`tab-button ${activeTab === value ? 'active' : ''}`}
                        onClick={() => {
                            setActiveTab(value);
                            if (value === 'users') setUserFilter('');
                            if (value === 'appeals') setAppealFilter('');
                            if (value === 'tickets') setTicketFilter('');
                        }}
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
                                setUserFilter('');
                            }}
                        />
                    )}
                    {activeTab === 'users' && (
                        <UsersTab
                            adminToken={adminToken}
                            onMutate={handleMutate}
                            selectedUserId={selectedUserId}
                            onSelectUser={setSelectedUserId}
                            initialFilter={userFilter}
                        />
                    )}
                    {activeTab === 'appeals' && (
                        <AppealsTab
                            adminToken={adminToken}
                            onMutate={handleMutate}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                                setUserFilter('');
                            }}
                            filterStatus={appealFilter}
                        />
                    )}
                    {activeTab === 'tickets' && (
                        <SupportTicketsTab
                            adminToken={adminToken}
                            onMutate={handleMutate}
                            onSelectUser={(userId) => {
                                setSelectedUserId(userId);
                                setActiveTab('users');
                                setUserFilter('');
                            }}
                            filterStatus={ticketFilter}
                        />
                    )}
                </div>

                <aside className="dashboard-side">
                    <UserDetailPanel
                        adminToken={adminToken}
                        selectedUserId={selectedUserId}
                        refreshNonce={detailRefreshNonce}
                    />
                </aside>
            </div>
        </div>
    );
}

export default function App() {
    const [adminToken, setAdminToken] = useState(localStorage.getItem('adminToken') || null);
    const [adminEmail, setAdminEmail] = useState(localStorage.getItem('adminEmail') || '');

    const handleAuth = (session) => {
        localStorage.setItem('adminToken', session.token);
        localStorage.setItem('adminEmail', session.email);
        setAdminToken(session.token);
        setAdminEmail(session.email);
    };

    const handleLogout = async () => {
        const activeToken = localStorage.getItem('adminToken');
        if (activeToken) {
            try {
                await axios.post(`${API_BASE_URL}/admin/logout`, {}, {
                    headers: buildAdminHeaders(activeToken),
                });
            } catch (err) {
                // Local cleanup is enough if the session is already invalid.
            }
        }
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminEmail');
        setAdminToken(null);
        setAdminEmail('');
    };

    return (
        <div className="container">
            {adminToken ? (
                <ErrorBoundary>
                    <Dashboard adminToken={adminToken} adminEmail={adminEmail} onLogout={handleLogout} />
                </ErrorBoundary>
            ) : (
                <AuthComponent onAuth={handleAuth} />
            )}
        </div>
    );
}
