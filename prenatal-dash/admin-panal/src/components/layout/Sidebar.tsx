import { Link, useLocation } from 'react-router-dom';
import {
    LayoutDashboard,
    Users,
    Apple,
    Baby,
    Activity,
    Moon,
    Music,
    Bell,
    HeartPulse,
    Globe,
    Settings,
    LogOut
} from 'lucide-react';
import clsx from 'clsx';

const navItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
    { icon: Users, label: 'Users Management', path: '/users' },
    { icon: Apple, label: 'Nutrition Guide', path: '/nutrition' },
    { icon: Baby, label: 'Fetal Development', path: '/fetal-development' },
    { icon: Activity, label: 'Exercise Recs', path: '/exercise' },
    { icon: Moon, label: 'Sleep Position Tips', path: '/sleep' },
    { icon: Music, label: 'Music & Relaxation', path: '/music' },
    { icon: Bell, label: 'Tracker & Notifications', path: '/notifications' },
    { icon: HeartPulse, label: 'Emergency & Health', path: '/emergency' },
    { icon: Globe, label: 'Language Options', path: '/language' },
    { icon: Settings, label: 'Settings', path: '/settings' },
];

export function Sidebar() {
    const location = useLocation();

    return (
        <aside className="w-64 bg-white border-r border-[#fdf2f8] flex flex-col h-screen sticky top-0 shadow-sm">
            <div className="p-6 border-b border-[#fdf2f8] flex items-center justify-center">
                <img src="/pregnancy-logo.png" alt="Logo" className="h-10 object-contain mr-2" />
                <h1 className="text-[#61183e] font-bold text-lg leading-tight">Pregnancy<br />Companion</h1>
            </div>

            <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
                {navItems.map((item) => {
                    const isActive = location.pathname === item.path;
                    return (
                        <Link
                            key={item.path}
                            to={item.path}
                            className={clsx(
                                'flex items-center px-3 py-2.5 rounded-lg transition-colors text-sm font-medium',
                                isActive
                                    ? 'bg-[#61183e] text-white'
                                    : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                            )}
                        >
                            <item.icon className={clsx("w-5 h-5 mr-3", isActive ? 'text-white' : 'text-[#61183e]')} />
                            {item.label}
                        </Link>
                    );
                })}
            </nav>

            <div className="p-4 border-t border-[#fdf2f8]">
                <button className="flex items-center w-full px-3 py-2.5 rounded-lg text-sm font-medium text-red-600 hover:bg-red-50 transition-colors">
                    <LogOut className="w-5 h-5 mr-3" />
                    Logout
                </button>
            </div>
        </aside>
    );
}
