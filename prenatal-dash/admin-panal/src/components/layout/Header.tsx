import { Bell } from 'lucide-react';

export function Header() {
    return (
        <header className="h-16 bg-white border-b border-[#fdf2f8] flex items-center justify-between px-8 shadow-sm">
            <div className="flex-1">
                {/* Optional: Add search or breadcrumbs here */}
            </div>

            <div className="flex items-center space-x-6">
                <button className="relative text-gray-500 hover:text-[#61183e] transition-colors">
                    <Bell className="w-6 h-6" />
                    <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
                </button>

                <div className="flex items-center space-x-3 border-l pl-6 border-gray-200">
                    <div className="w-9 h-9 rounded-full bg-[#fdf2f8] text-[#61183e] flex items-center justify-center font-bold">
                        A
                    </div>
                    <div className="flex flex-col text-sm">
                        <span className="font-semibold text-gray-900">Admin User</span>
                        <span className="text-xs text-gray-500">Superadmin</span>
                    </div>
                </div>
            </div>
        </header>
    );
}
