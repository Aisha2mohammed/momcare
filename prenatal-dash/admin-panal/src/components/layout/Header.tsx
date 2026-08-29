import { useState, useRef, useEffect } from 'react';
import { Bell, Check, UserCheck, AlertTriangle, LogOut } from 'lucide-react';
import { useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from '../LanguageSwitcher';
import { useAuth } from '../../context/AuthContext';

const pageMap: Record<string, { key: string; subtitle: string }> = {
    '/': { key: 'dashboard', subtitle: 'Overview of platform activity' },
    '/doctor-approvals': { key: 'doctorApprovals', subtitle: 'Review registration requests' },
    '/users': { key: 'users', subtitle: 'Manage mothers and doctors' },
    '/health-providers': { key: 'healthProviders', subtitle: 'Manage registered facilities' },
    '/nutrition': { key: 'nutrition', subtitle: 'Manage educational content' },
    '/fetal-development': { key: 'fetalDevelopment', subtitle: 'Manage fetal stages' },
    '/exercise': { key: 'exercise', subtitle: 'Manage exercise routines' },
    '/sleep': { key: 'sleep', subtitle: 'Manage sleep tips' },
    '/music': { key: 'music', subtitle: 'Manage audio content' },
    '/notifications': { key: 'notifications', subtitle: 'Manage platform alerts' },
    '/emergency': { key: 'emergency', subtitle: 'Manage emergency contacts' },
    '/language': { key: 'language', subtitle: 'Manage language options' },
    '/community': { key: 'community', subtitle: 'Monitor and manage posts' },
    '/announcements': { key: 'announcements', subtitle: 'Broadcast messages to users' },
    '/audit-log': { key: 'auditLog', subtitle: 'Complete history of admin actions' },
    '/settings': { key: 'settings', subtitle: 'Configure platform settings' },
};

export function Header() {
    const { t } = useTranslation();
    const location = useLocation();
    const { user, logout } = useAuth();
    const page = pageMap[location.pathname] ?? { key: '', subtitle: 'Admin Panel' };
    const title = page.key ? t(`nav.${page.key}`) : 'Mom Care';

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
        <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-6 shadow-sm shrink-0">
            {/* Page title */}
            <div className="hidden md:block">
                <h2 className="text-base font-semibold text-gray-900">{title}</h2>
                <p className="text-xs text-gray-400">{page.subtitle}</p>
            </div>

            <div className="flex items-center gap-3 ml-auto">
                {/* Language Switcher */}
                <LanguageSwitcher />

                {/* Notification Bell */}
                <div className="relative" ref={notifRef}>
                    <button
                        onClick={() => setShowNotifs(!showNotifs)}
                        className="relative p-2 rounded-lg text-gray-500 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors"
                        title="Notifications"
                    >
                        <Bell className="w-5 h-5" />
                        <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white" aria-hidden="true" />
                        <span className="sr-only">3 pending notifications</span>
                    </button>

                    {showNotifs && (
                        <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-lg border border-gray-100 overflow-hidden z-50">
                            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                                <h3 className="font-semibold text-gray-800 text-sm">Notifications</h3>
                                <button className="text-xs text-[#61183e] font-medium hover:underline">Mark all read</button>
                            </div>
                            <div className="max-h-80 overflow-y-auto">
                                {mockNotifications.map(n => (
                                    <div key={n.id} className="p-4 border-b border-gray-50 hover:bg-gray-50/50 transition-colors flex gap-3 cursor-pointer">
                                        <div className="mt-0.5 bg-white shadow-sm p-1.5 rounded-full border border-gray-100 h-fit">
                                            {n.icon}
                                        </div>
                                        <div>
                                            <p className="text-sm font-medium text-gray-800 leading-tight">{n.title}</p>
                                            <p className="text-xs text-gray-500 mt-1">{n.message}</p>
                                            <p className="text-[10px] font-medium text-gray-400 mt-2">{n.time}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <button className="w-full p-3 text-sm text-gray-500 hover:text-[#61183e] font-medium transition-colors border-t border-gray-100 bg-gray-50/50">
                                View all notification history
                            </button>
                        </div>
                    )}
                </div>

                {/* Admin Avatar */}
                <div className="flex items-center gap-2.5 border-l pl-4 border-gray-100">
                    <div className="w-8 h-8 rounded-full bg-[#fdf2f8] text-[#61183e] flex items-center justify-center font-bold text-sm">
                        {user?.name.split(' ').map(n => n[0]).join('') ?? 'A'}
                    </div>
                    <div className="flex flex-col text-sm hidden sm:block">
                        <span className="font-semibold text-gray-900 leading-tight">{user?.name ?? 'Admin'}</span>
                        <span className="text-xs text-gray-400 capitalize">{user?.role ?? 'admin'}</span>
                    </div>
                </div>
            </div>
        </header>
    );
}
