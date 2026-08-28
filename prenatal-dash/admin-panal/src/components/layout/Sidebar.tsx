import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
    LayoutDashboard,
    UserCheck,
    Users,
    Building2,
    Apple,
    Baby,
    Activity,
    Moon,
    Music,
    Bell,
    HeartPulse,
    Globe,
    Shield,
    Megaphone,
    ClipboardList,
    LogOut,
    ChevronRight,
    MessageSquareWarning,
} from 'lucide-react';
import clsx from 'clsx';
import { useAuth } from '../../context/AuthContext';
import { useState } from 'react';

const navSections = [
    {
        label: 'Overview',
        items: [
            { icon: LayoutDashboard, label: 'Dashboard', key: 'dashboard', path: '/', badge: 0 },
        ],
    },
    {
        label: 'Management',
        items: [
            { icon: UserCheck, label: 'Doctor Approvals', key: 'doctorApprovals', path: '/doctor-approvals', badge: 3 },
            { icon: Users, label: 'Users', key: 'users', path: '/users', badge: 0 },
            { icon: Building2, label: 'Health Providers', key: 'healthProviders', path: '/health-providers', badge: 0 },
        ],
    },
    {
        label: 'Content Library',
        collapsible: true, // we translate the label inline directly
        items: [
            { icon: Apple, label: 'Nutrition Guide', key: 'nutrition', path: '/nutrition', badge: 0 },
            { icon: Baby, label: 'Fetal Development', key: 'fetalDevelopment', path: '/fetal-development', badge: 0 },
            { icon: Activity, label: 'Exercise Recs', key: 'exercise', path: '/exercise', badge: 0 },
            { icon: Moon, label: 'Sleep Position Tips', key: 'sleep', path: '/sleep', badge: 0 },
            { icon: Music, label: 'Music & Relaxation', key: 'music', path: '/music', badge: 0 },
            { icon: Bell, label: 'Tracker & Notifications', key: 'notifications', path: '/notifications', badge: 0 },
            { icon: HeartPulse, label: 'Emergency & Health', key: 'emergency', path: '/emergency', badge: 0 },
            { icon: Globe, label: 'Language Options', key: 'language', path: '/language', badge: 0 },
        ],
    },
    {
        label: 'Engagement',
        items: [
            { icon: MessageSquareWarning, label: 'Community', key: 'community', path: '/community', badge: 3 },
            { icon: Megaphone, label: 'Announcements', key: 'announcements', path: '/announcements', badge: 0 },
        ],
    },
    {
        label: 'System',
        items: [
            { icon: ClipboardList, label: 'Audit Log', key: 'auditLog', path: '/audit-log', badge: 0 },
            { icon: Shield, label: 'Settings', key: 'settings', path: '/settings', badge: 0 },
        ],
    },
];

export function Sidebar() {
    const { t } = useTranslation();
    const location = useLocation();
    const { user, logout } = useAuth();
    const [contentExpanded, setContentExpanded] = useState(true);

    const isActive = (path: string) => {
        if (path === '/') return location.pathname === '/';
        return location.pathname.startsWith(path);
    };

    // auto-expand content section if any child is active
    const contentPaths = ['/nutrition', '/fetal-development', '/exercise', '/sleep', '/music', '/notifications', '/emergency', '/language'];
    const isContentActive = contentPaths.some(p => location.pathname.startsWith(p));

    return (
        <aside className="w-64 bg-white border-r border-gray-100 flex flex-col h-screen sticky top-0 shadow-sm shrink-0">
            {/* Logo */}
            <div className="py-5 px-4 border-b border-gray-100 flex items-center gap-3">
                <img src="/white-pregnancy-logo.png" alt="Mom Care Logo" className="w-16 h-16 object-contain shrink-0" />
                <div className="flex flex-col justify-center">
                    <h1 className="text-[#61183e] font-bold text-xl leading-tight">Mom Care</h1>
                    <p className="text-gray-400 text-xs">Admin Panel</p>
                </div>
            </div>

            {/* Nav */}
            <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-2">
                {navSections.map(section => {
                    const isCollapsible = section.collapsible;
                    const expanded = isCollapsible ? (contentExpanded || isContentActive) : true;

                    return (
                        <div key={section.label}>
                            {isCollapsible ? (
                                <button
                                    onClick={() => setContentExpanded(e => !e)}
                                    className="w-full flex items-center justify-between text-[10px] font-semibold text-gray-400 uppercase tracking-wider px-3 mb-1 hover:text-gray-600 transition-colors"
                                >
                                    <span>{t(`nav.${section.label.toLowerCase().replace(/ /g, '')}`, { defaultValue: section.label })}</span>
                                    <ChevronRight className={`w-3 h-3 transition-transform ${expanded ? 'rotate-90' : ''}`} />
                                </button>
                            ) : (
                                <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider px-3 mb-1">
                                    {t(`nav.${section.label.toLowerCase().replace(/ /g, '')}`, { defaultValue: section.label })}
                                </p>
                            )}

                            {expanded && (
                                <div className="space-y-0.5">
                                    {section.items.map(item => {
                                        const active = isActive(item.path);
                                        return (
                                            <Link
                                                key={item.path}
                                                to={item.path}
                                                className={clsx(
                                                    'flex items-center px-3 py-2 rounded-lg transition-all text-sm font-medium group',
                                                    active
                                                        ? 'bg-[#61183e] text-white shadow-sm'
                                                        : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                                                )}
                                            >
                                                <item.icon className={clsx(
                                                    'w-4 h-4 mr-2.5 shrink-0',
                                                    active ? 'text-white' : 'text-gray-400 group-hover:text-[#61183e]'
                                                )} />
                                                <span className="flex-1 truncate text-xs">
                                                    {item.key ? t(`nav.${item.key}`, { defaultValue: item.label }) : item.label}
                                                </span>
                                                {item.badge > 0 ? (
                                                    <span className={clsx(
                                                        'ml-1 text-xs rounded-full px-1.5 py-0.5 font-semibold min-w-[18px] text-center',
                                                        active ? 'bg-white/20 text-white' : 'bg-red-100 text-red-600'
                                                    )}>
                                                        {item.badge}
                                                    </span>
                                                ) : null}
                                            </Link>
                                        );
                                    })}
                                </div>
                            )}
                        </div>
                    );
                })}
            </nav>

            {/* User info + Logout */}
            <div className="p-3 border-t border-gray-100">
                {user && (
                    <div className="flex items-center gap-2.5 px-3 py-2 mb-1">
                        <div className="w-8 h-8 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">
                            {user.name.split(' ').map(n => n[0]).join('')}
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-gray-800 truncate">{user.name}</p>
                            <p className="text-xs text-gray-400 truncate capitalize">{user.role}</p>
                        </div>
                    </div>
                )}
                <button
                    onClick={logout}
                    className="flex items-center w-full px-3 py-2 rounded-lg text-sm font-medium text-red-500 hover:bg-red-50 transition-colors"
                >
                    <LogOut className="w-4 h-4 mr-2.5" />
                    Logout
                </button>
            </div>
        </aside>
    );
}
