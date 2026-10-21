import { useState, useRef } from 'react';
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
    Shield,
    Megaphone,
    ClipboardList,
    LogOut,
    ChevronRight,
    ChevronDown,
    MessageSquareWarning,
    ListChecks,
    PlusCircle,
    PanelLeftClose,
    PanelLeftOpen,
    X,
} from 'lucide-react';
import clsx from 'clsx';
import { useAuth } from '../../context/AuthContext';
import { useSidebar } from '../../context/SidebarContext';

interface SubItem {
    label: string;
    path: string;
    icon: any;
}

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
        collapsible: true,
        items: [
            { icon: Baby, label: 'Fetal Development', key: 'fetalDevelopment', path: '/fetal-development', badge: 0 },
            { icon: Music, label: 'Music & Relaxation', key: 'music', path: '/music', badge: 0 },
            { icon: Bell, label: 'Tracker & Notifications', key: 'notifications', path: '/notifications', badge: 0 },
            { icon: HeartPulse, label: 'Emergency & Health', key: 'emergency', path: '/emergency', badge: 0 },
          
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
    const { isCollapsed, toggleCollapse, isMobileOpen, closeMobile } = useSidebar();

    const [contentExpanded, setContentExpanded] = useState(true);
    const [nutritionExpanded, setNutritionExpanded] = useState(
        location.pathname.startsWith('/nutrition')
    );
    const [exerciseExpanded, setExerciseExpanded] = useState(
        location.pathname.startsWith('/exercise')
    );
    const [sleepExpanded, setSleepExpanded] = useState(
        location.pathname.startsWith('/sleep')
    );

    // Active flyout state for collapsed desktop view
    const [activeFlyout, setActiveFlyout] = useState<string | null>(null);
    const flyoutTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

    const handleFlyoutEnter = (key: string) => {
        if (!isCollapsed) return;
        if (flyoutTimeoutRef.current) clearTimeout(flyoutTimeoutRef.current);
        setActiveFlyout(key);
    };

    const handleFlyoutLeave = () => {
        if (!isCollapsed) return;
        flyoutTimeoutRef.current = setTimeout(() => {
            setActiveFlyout(null);
        }, 150);
    };

    const isActive = (path: string) => {
        if (path === '/') return location.pathname === '/';
        return location.pathname === path;
    };

    const isActivePrefix = (path: string) => location.pathname.startsWith(path);

    // Auto-expand content section if any child is active
    const contentPaths = ['/nutrition', '/fetal-development', '/exercise', '/sleep', '/music', '/notifications', '/emergency', '/language'];
    const isContentActive = contentPaths.some(p => location.pathname.startsWith(p));

    // Submenu definition for expanded view
    const renderSubMenu = (
        label: string,
        Icon: any,
        pathPrefix: string,
        expanded: boolean,
        setExpanded: React.Dispatch<React.SetStateAction<boolean>>,
        subItems: SubItem[],
        flyoutKey: string
    ) => {
        const isPrefixActive = isActivePrefix(pathPrefix);

        // If collapsed on desktop, render compact icon with popover flyout
        if (isCollapsed) {
            const isFlyoutOpen = activeFlyout === flyoutKey;
            return (
                <div
                    key={pathPrefix}
                    className="relative group"
                    onMouseEnter={() => handleFlyoutEnter(flyoutKey)}
                    onMouseLeave={handleFlyoutLeave}
                >
                    <button
                        type="button"
                        onClick={() => setActiveFlyout(isFlyoutOpen ? null : flyoutKey)}
                        className={clsx(
                            'w-full flex items-center justify-center p-2.5 rounded-xl transition-all group relative',
                            isPrefixActive
                                ? 'bg-[#fdf2f8] text-[#61183e] font-bold shadow-xs'
                                : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                        )}
                        title={label}
                    >
                        <Icon className={clsx('w-5 h-5 shrink-0', isPrefixActive ? 'text-[#61183e]' : 'text-gray-500 group-hover:text-[#61183e]')} />
                        <span className="sr-only">{label}</span>
                    </button>

                    {/* Collapsed Flyout Popover */}
                    {isFlyoutOpen && (
                        <div
                            className="absolute left-full top-0 ml-2 w-52 bg-white rounded-xl shadow-xl border border-gray-100 p-2 z-50 animate-in fade-in zoom-in-95 duration-150"
                            onMouseEnter={() => handleFlyoutEnter(flyoutKey)}
                            onMouseLeave={handleFlyoutLeave}
                        >
                            <div className="px-3 py-1.5 border-b border-gray-100 mb-1 flex items-center gap-2">
                                <Icon className="w-4 h-4 text-[#61183e]" />
                                <span className="text-xs font-bold text-gray-800">{label}</span>
                            </div>
                            <div className="space-y-1">
                                {subItems.map(item => (
                                    <Link
                                        key={item.path}
                                        to={item.path}
                                        onClick={() => {
                                            setActiveFlyout(null);
                                            closeMobile();
                                        }}
                                        className={clsx(
                                            'flex items-center px-2.5 py-1.5 rounded-lg text-xs font-medium transition-colors',
                                            isActive(item.path)
                                                ? 'bg-[#61183e] text-white'
                                                : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                                        )}
                                    >
                                        <item.icon className="w-3.5 h-3.5 mr-2 shrink-0" />
                                        <span className="truncate">{item.label}</span>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            );
        }

        // Expanded view
        return (
            <div key={pathPrefix} className="mb-0.5">
                <button
                    type="button"
                    onClick={() => setExpanded(e => !e)}
                    className={clsx(
                        'w-full flex items-center px-3 py-2 rounded-xl transition-all text-xs font-semibold group',
                        isPrefixActive
                            ? 'bg-[#fdf2f8] text-[#61183e]'
                            : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                    )}
                >
                    <Icon className={clsx(
                        'w-4 h-4 mr-2.5 shrink-0',
                        isPrefixActive ? 'text-[#61183e]' : 'text-gray-400 group-hover:text-[#61183e]'
                    )} />
                    <span className="flex-1 truncate text-left">{label}</span>
                    <ChevronDown className={clsx(
                        'w-3.5 h-3.5 transition-transform shrink-0',
                        expanded ? 'rotate-180' : '',
                        isPrefixActive ? 'text-[#61183e]' : 'text-gray-400'
                    )} />
                </button>

                {expanded && (
                    <div className="ml-4 mt-1 space-y-0.5 border-l-2 border-[#61183e]/15 pl-2">
                        {subItems.map(item => (
                            <Link
                                key={item.path}
                                to={item.path}
                                onClick={closeMobile}
                                className={clsx(
                                    'flex items-center px-2.5 py-1.5 rounded-lg transition-all text-xs font-medium group',
                                    isActive(item.path)
                                        ? 'bg-[#61183e] text-white shadow-sm'
                                        : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                                )}
                            >
                                <item.icon className={clsx(
                                    'w-3.5 h-3.5 mr-2 shrink-0',
                                    isActive(item.path) ? 'text-white' : 'text-gray-400 group-hover:text-[#61183e]'
                                )} />
                                <span className="truncate">{item.label}</span>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        );
    };

    return (
        <>
            {/* Mobile Backdrop Overlay */}
            {isMobileOpen && (
                <div
                    className="fixed inset-0 bg-black/50 backdrop-blur-xs z-40 lg:hidden transition-opacity duration-300"
                    onClick={closeMobile}
                    aria-hidden="true"
                />
            )}

            {/* Sidebar Element */}
            <aside
                className={clsx(
                    'fixed inset-y-0 left-0 z-50 bg-white border-r border-gray-100 flex flex-col h-full shadow-lg lg:shadow-xs transition-all duration-300 ease-in-out shrink-0 select-none',
                    // Mobile Drawer positioning:
                    isMobileOpen ? 'translate-x-0 w-72 max-w-[85vw]' : '-translate-x-full',
                    // Desktop positioning & width (unaffected by mobile drawer transform):
                    'lg:static lg:translate-x-0',
                    isCollapsed ? 'lg:w-20' : 'lg:w-64'
                )}
            >
                {/* Header / Logo section */}
                <div className={clsx(
                    'py-4 px-3 border-b border-gray-100 flex items-center justify-between shrink-0 h-16',
                    isCollapsed && 'lg:justify-center lg:px-2'
                )}>
                    {/* Brand / Logo */}
                    <div className="flex items-center gap-3 min-w-0">
                        <img
                            src="/white-pregnancy-logo.png"
                            alt="Mom Care Logo"
                            className="w-10 h-10 object-contain shrink-0"
                        />
                        {/* Only show title when expanded (or on mobile drawer) */}
                        <div className={clsx(
                            'flex flex-col justify-center min-w-0',
                            isCollapsed && 'lg:hidden'
                        )}>
                            <h1 className="text-[#61183e] font-bold text-base leading-tight truncate">Mom Care</h1>
                            <p className="text-gray-400 text-[11px] truncate">Admin Panel</p>
                        </div>
                    </div>

                    {/* Close button for Mobile drawer */}
                    <button
                        onClick={closeMobile}
                        className="lg:hidden p-2 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors"
                        title="Close sidebar"
                    >
                        <X className="w-5 h-5" />
                    </button>

                    {/* Desktop Collapse / Expand Toggle Button in sidebar header */}
                    <button
                        onClick={toggleCollapse}
                        className={clsx(
                            'hidden lg:flex p-1.5 rounded-lg text-gray-400 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors',
                            isCollapsed && 'hidden'
                        )}
                        title={isCollapsed ? 'Expand sidebar' : 'Contract sidebar'}
                    >
                        <PanelLeftClose className="w-4 h-4" />
                    </button>
                </div>

                {/* Navigation Links */}
                <nav className={clsx(
                    'flex-1 overflow-y-auto overflow-x-hidden py-3 space-y-2',
                    isCollapsed ? 'px-2' : 'px-3'
                )}>
                    {navSections.map(section => {
                        const isCollapsible = section.collapsible;
                        const expanded = isCollapsible ? (contentExpanded || isContentActive) : true;

                        return (
                            <div key={section.label} className="pt-1">
                                {/* Section title or divider */}
                                {isCollapsed ? (
                                    <div className="hidden lg:block w-full border-t border-gray-100 my-2" />
                                ) : (
                                    <>
                                        {isCollapsible ? (
                                            <button
                                                onClick={() => setContentExpanded(e => !e)}
                                                className="w-full flex items-center justify-between text-[10px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-1.5 hover:text-gray-600 transition-colors"
                                            >
                                                <span>{t(`nav.${section.label.toLowerCase().replace(/ /g, '')}`, { defaultValue: section.label })}</span>
                                                <ChevronRight className={`w-3 h-3 transition-transform ${expanded ? 'rotate-90' : ''}`} />
                                            </button>
                                        ) : (
                                            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-1.5">
                                                {t(`nav.${section.label.toLowerCase().replace(/ /g, '')}`, { defaultValue: section.label })}
                                            </p>
                                        )}
                                    </>
                                )}

                                {(expanded || isCollapsed) && (
                                    <div className="space-y-0.5">
                                        {/* Sub-menus for Content Library */}
                                        {section.collapsible && (
                                            <>
                                                {renderSubMenu(
                                                    t('nav.nutrition', { defaultValue: 'Nutrition Guide' }),
                                                    Apple,
                                                    '/nutrition',
                                                    nutritionExpanded,
                                                    setNutritionExpanded,
                                                    [
                                                        { label: 'Nutrition Week', path: '/nutrition/weeks', icon: ListChecks },
                                                        { label: 'Add Nutrient', path: '/nutrition/add', icon: PlusCircle },
                                                    ],
                                                    'nutrition'
                                                )}

                                                {renderSubMenu(
                                                    t('nav.exercise', { defaultValue: 'Exercise Recs' }),
                                                    Activity,
                                                    '/exercise',
                                                    exerciseExpanded,
                                                    setExerciseExpanded,
                                                    [
                                                        { label: 'Exercise Week', path: '/exercise/weeks', icon: ListChecks },
                                                        { label: 'Add Exercise', path: '/exercise/add', icon: PlusCircle },
                                                    ],
                                                    'exercise'
                                                )}

                                                {renderSubMenu(
                                                    t('nav.sleep', { defaultValue: 'Sleep Tips' }),
                                                    Moon,
                                                    '/sleep',
                                                    sleepExpanded,
                                                    setSleepExpanded,
                                                    [
                                                        { label: 'Sleep Week', path: '/sleep/weeks', icon: ListChecks },
                                                        { label: 'Add Sleep', path: '/sleep/add', icon: PlusCircle },
                                                    ],
                                                    'sleep'
                                                )}
                                            </>
                                        )}

                                        {/* Standard items */}
                                        {section.items.map(item => {
                                            const active = isActive(item.path);
                                            const itemLabel = item.key ? t(`nav.${item.key}`, { defaultValue: item.label }) : item.label;

                                            return (
                                                <Link
                                                    key={item.path}
                                                    to={item.path}
                                                    onClick={closeMobile}
                                                    className={clsx(
                                                        'flex items-center rounded-xl transition-all font-medium group relative',
                                                        isCollapsed ? 'justify-center p-2.5 lg:px-0' : 'px-3 py-2 text-xs',
                                                        active
                                                            ? 'bg-[#61183e] text-white shadow-xs font-semibold'
                                                            : 'text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e]'
                                                    )}
                                                    title={isCollapsed ? itemLabel : undefined}
                                                >
                                                    <item.icon className={clsx(
                                                        'shrink-0',
                                                        isCollapsed ? 'w-5 h-5' : 'w-4 h-4 mr-2.5',
                                                        active ? 'text-white' : 'text-gray-400 group-hover:text-[#61183e]'
                                                    )} />

                                                    {/* Expanded label */}
                                                    <span className={clsx(
                                                        'flex-1 truncate',
                                                        isCollapsed && 'lg:hidden'
                                                    )}>
                                                        {itemLabel}
                                                    </span>

                                                    {/* Badge */}
                                                    {item.badge > 0 && (
                                                        <>
                                                            {/* Normal pill badge in expanded mode */}
                                                            <span className={clsx(
                                                                'ml-1 text-[11px] rounded-full px-1.5 py-0.2 font-semibold min-w-[18px] text-center',
                                                                isCollapsed && 'lg:hidden',
                                                                active ? 'bg-white/20 text-white' : 'bg-red-100 text-red-600'
                                                            )}>
                                                                {item.badge}
                                                            </span>

                                                            {/* Compact dot badge in contracted mini mode */}
                                                            {isCollapsed && (
                                                                <span className="hidden lg:block absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white" />
                                                            )}
                                                        </>
                                                    )}

                                                    {/* Hover Tooltip in Collapsed Desktop Mode */}
                                                    {isCollapsed && (
                                                        <div className="hidden lg:group-hover:flex absolute left-full ml-3 px-2.5 py-1 bg-gray-900 text-white text-xs font-medium rounded-md shadow-md whitespace-nowrap z-50 pointer-events-none items-center gap-1.5">
                                                            <span>{itemLabel}</span>
                                                            {item.badge > 0 && (
                                                                <span className="bg-red-500 text-white text-[10px] rounded-full px-1.5 py-0.2 font-bold">
                                                                    {item.badge}
                                                                </span>
                                                            )}
                                                        </div>
                                                    )}
                                                </Link>
                                            );
                                        })}
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </nav>

                {/* Footer: User profile & Logout + Desktop Expand toggle */}
                <div className={clsx(
                    'p-2.5 border-t border-gray-100 bg-gray-50/50 shrink-0 space-y-1',
                    isCollapsed && 'lg:p-2'
                )}>
                    {user && (
                        <div className={clsx(
                            'flex items-center gap-2.5 px-2 py-1.5 rounded-xl',
                            isCollapsed && 'lg:justify-center lg:px-0'
                        )}>
                            <div className="w-8 h-8 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0 shadow-xs border border-rose-100">
                                {user.name.split(' ').map(n => n[0]).join('')}
                            </div>
                            <div className={clsx('flex-1 min-w-0', isCollapsed && 'lg:hidden')}>
                                <p className="text-xs font-bold text-gray-800 truncate">{user.name}</p>
                                <p className="text-[11px] text-gray-400 truncate capitalize">{user.role}</p>
                            </div>
                        </div>
                    )}

                    {/* Logout button */}
                    <button
                        onClick={logout}
                        className={clsx(
                            'flex items-center w-full rounded-xl text-xs font-medium text-red-500 hover:bg-red-50 transition-colors',
                            isCollapsed ? 'justify-center p-2' : 'px-2.5 py-1.5'
                        )}
                        title="Logout"
                    >
                        <LogOut className={clsx('w-4 h-4 shrink-0', !isCollapsed && 'mr-2')} />
                        <span className={clsx(isCollapsed && 'lg:hidden')}>Logout</span>
                    </button>

                    {/* Contracted Mode Expand Button at bottom */}
                    {isCollapsed && (
                        <button
                            onClick={toggleCollapse}
                            className="hidden lg:flex items-center justify-center w-full p-2 rounded-xl text-gray-400 hover:text-[#61183e] hover:bg-[#fdf2f8] transition-colors"
                            title="Expand sidebar"
                        >
                            <PanelLeftOpen className="w-4 h-4 text-[#61183e]" />
                        </button>
                    )}
                </div>
            </aside>
        </>
    );
}
