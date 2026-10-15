import { useState, useRef, useEffect } from 'react';
import { Bell, Check, UserCheck, AlertTriangle, LogOut, Menu, PanelLeftClose, PanelLeftOpen } from 'lucide-react';
import { useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from '../LanguageSwitcher';
import { useAuth } from '../../context/AuthContext';
import { useSidebar } from '../../context/SidebarContext';

const pageMap: Record<string, { key: string; subtitle: string; fallbackTitle?: string }> = {
    '/': { key: 'dashboard', subtitle: 'Overview of platform activity' },
    '/doctor-approvals': { key: 'doctorApprovals', subtitle: 'Review registration requests' },
    '/users': { key: 'users', subtitle: 'Manage mothers and doctors' },
    '/health-providers': { key: 'healthProviders', subtitle: 'Manage registered facilities' },
    '/nutrition': { key: 'nutrition', subtitle: 'Manage educational content' },
    '/nutrition/weeks': { key: 'nutrition', subtitle: 'Weekly nutrition importance & hydration guidelines', fallbackTitle: 'Nutrition Week Guides' },
    '/nutrition/add': { key: 'nutrition', subtitle: 'Add & manage pregnancy nutrient profiles', fallbackTitle: 'Add Nutrient' },
    '/fetal-development': { key: 'fetalDevelopment', subtitle: 'Manage fetal stages & weekly milestones' },
    '/exercise': { key: 'exercise', subtitle: 'Manage exercise routines' },
    '/exercise/weeks': { key: 'exercise', subtitle: 'Weekly exercise guidelines & trimester routines', fallbackTitle: 'Exercise Week Guides' },
    '/exercise/add': { key: 'exercise', subtitle: 'Add & manage safe pregnancy exercises', fallbackTitle: 'Add Exercise Routine' },
    '/sleep': { key: 'sleep', subtitle: 'Manage sleep tips' },
    '/sleep/weeks': { key: 'sleep', subtitle: 'Weekly sleep positions & rest guidance', fallbackTitle: 'Sleep Week Guides' },
    '/sleep/add': { key: 'sleep', subtitle: 'Add & manage sleep position tips', fallbackTitle: 'Add Sleep Tip' },
    '/music': { key: 'music', subtitle: 'Manage audio & relaxation content' },
    '/notifications': { key: 'notifications', subtitle: 'Manage platform alerts & push reminders' },
    '/emergency': { key: 'emergency', subtitle: 'Manage hospital contacts & health warnings' },
    '/language': { key: 'language', subtitle: 'Manage localization & translations' },
    '/community': { key: 'community', subtitle: 'Monitor, moderate, and manage user posts' },
    '/announcements': { key: 'announcements', subtitle: 'Broadcast notifications to mothers and doctors' },
    '/audit-log': { key: 'auditLog', subtitle: 'Complete audit history of admin actions' },
    '/settings': { key: 'settings', subtitle: 'Configure platform preferences & security' },
};

export function Header() {
    const { t } = useTranslation();
    const location = useLocation();
    const { user, logout } = useAuth();
    const { isCollapsed, toggleCollapse, toggleMobileOpen } = useSidebar();

    // Match exact path or prefix for detail pages like /doctor-approvals/:id
    let page = pageMap[location.pathname];
    if (!page) {
        if (location.pathname.startsWith('/doctor-approvals/')) {
            page = { key: 'doctorApprovals', subtitle: 'Doctor credential verification' };
        } else {
            page = { key: '', subtitle: 'Admin Panel' };
        }
    }

    const title = page.key ? t(`nav.${page.key}`, { defaultValue: page.fallbackTitle || 'Mom Care' }) : (page.fallbackTitle || 'Mom Care');

    const [showNotifs, setShowNotifs] = useState(false);
    const notifRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        function handleClickOutside(event: MouseEvent) {
            if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
                setShowNotifs(false);
            }
        }
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const mockNotifications = [
        { id: 1, title: 'New Doctor Registration', message: 'Dr. Sarah Abebe requested approval.', time: '2 mins ago', icon: <UserCheck className="w-4 h-4 text-blue-500" /> },
        { id: 2, title: 'System Alert', message: 'High CPU usage detected.', time: '1 hour ago', icon: <AlertTriangle className="w-4 h-4 text-orange-500" /> },
        { id: 3, title: 'Export Completed', message: 'User report CSV is ready.', time: '3 hours ago', icon: <Check className="w-4 h-4 text-green-500" /> },
    ];

    return (
        <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-3 sm:px-6 shadow-xs shrink-0 z-30 relative">
            {/* Left section: Hamburger / Toggle & Page Title */}
            <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                {/* Mobile Hamburger Drawer Toggle */}
                <button
                    onClick={toggleMobileOpen}
                    className="lg:hidden p-2 rounded-xl text-gray-600 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors shrink-0"
                    title="Open Navigation Menu"
                    aria-label="Toggle navigation menu"
                >
                    <Menu className="w-5 h-5" />
                </button>

                {/* Desktop Collapse / Expand Toggle */}
                <button
                    onClick={toggleCollapse}
                    className="hidden lg:flex p-2 rounded-xl text-gray-500 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors shrink-0"
                    title={isCollapsed ? 'Expand sidebar' : 'Contract sidebar'}
                    aria-label={isCollapsed ? 'Expand sidebar' : 'Contract sidebar'}
                >
                    {isCollapsed ? (
                        <PanelLeftOpen className="w-5 h-5 text-[#61183e]" />
                    ) : (
                        <PanelLeftClose className="w-5 h-5 text-gray-500" />
                    )}
                </button>

                {/* Page title and subtitle */}
                <div className="min-w-0">
                    <h2 className="text-sm sm:text-base font-bold text-gray-900 truncate leading-tight">
                        {title}
                    </h2>
                    <p className="text-[11px] sm:text-xs text-gray-400 truncate hidden sm:block">
                        {page.subtitle}
                    </p>
                </div>
            </div>

            {/* Right section: Language Switcher, Notifications, User profile */}
            <div className="flex items-center gap-1.5 sm:gap-3 shrink-0">
                {/* Language Switcher */}
                <div className="shrink-0">
                    <LanguageSwitcher />
                </div>

                {/* Notification Bell */}
                <div className="relative" ref={notifRef}>
                    <button
                        onClick={() => setShowNotifs(!showNotifs)}
                        className="relative p-2 rounded-xl text-gray-500 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors"
                        title="Notifications"
                        aria-label="View notifications"
                    >
                        <Bell className="w-5 h-5" />
                        <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white" aria-hidden="true" />
                        <span className="sr-only">3 pending notifications</span>
                    </button>

                    {showNotifs && (
                        <div className="absolute right-0 mt-2 w-80 max-w-[calc(100vw-2rem)] bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-150">
                            <div className="p-3.5 border-b border-gray-100 flex justify-between items-center bg-gray-50/70">
                                <h3 className="font-bold text-gray-800 text-xs sm:text-sm">Notifications</h3>
                                <button className="text-[11px] text-[#61183e] font-semibold hover:underline">Mark all read</button>
                            </div>
                            <div className="max-h-80 overflow-y-auto divide-y divide-gray-50">
                                {mockNotifications.map(n => (
                                    <div key={n.id} className="p-3 hover:bg-gray-50/60 transition-colors flex gap-2.5 cursor-pointer">
                                        <div className="mt-0.5 bg-white shadow-xs p-1.5 rounded-full border border-gray-100 h-fit shrink-0">
                                            {n.icon}
                                        </div>
                                        <div className="min-w-0">
                                            <p className="text-xs font-semibold text-gray-800 leading-snug truncate">{n.title}</p>
                                            <p className="text-[11px] text-gray-500 mt-0.5 line-clamp-2">{n.message}</p>
                                            <p className="text-[10px] font-medium text-gray-400 mt-1">{n.time}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <button className="w-full p-2.5 text-xs text-gray-600 hover:text-[#61183e] font-semibold transition-colors border-t border-gray-100 bg-gray-50/50 text-center">
                                View all notification history
                            </button>
                        </div>
                    )}
                </div>

                {/* Admin Avatar & Profile */}
                <div className="flex items-center gap-2 pl-1.5 sm:pl-3 border-l border-gray-100">
                    <div className="w-8 h-8 rounded-full bg-[#fdf2f8] text-[#61183e] border border-rose-100 flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                        {user?.name.split(' ').map(n => n[0]).join('') ?? 'A'}
                    </div>
                    <div className="flex flex-col text-sm hidden md:block min-w-0 max-w-[120px]">
                        <span className="font-bold text-xs text-gray-900 leading-tight truncate">{user?.name ?? 'Admin'}</span>
                        <span className="text-[11px] text-gray-400 capitalize truncate">{user?.role ?? 'admin'}</span>
                    </div>
                    <button
                        onClick={logout}
                        className="p-1.5 rounded-xl hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors"
                        title="Sign Out"
                        aria-label="Sign out"
                    >
                        <LogOut className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </header>
    );
}
