import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { SidebarProvider } from '../../context/SidebarContext';

export function Layout() {
    return (
        <SidebarProvider>
            <div className="flex h-screen bg-[#f9fafb] text-gray-900 font-sans overflow-hidden">
                <Sidebar />
                <div className="flex-1 flex flex-col h-screen min-w-0 overflow-hidden">
                    <Header />
                    <main className="flex-1 overflow-y-auto overflow-x-hidden p-3 sm:p-5 md:p-6 lg:p-8 min-w-0 w-full">
                        <div className="max-w-7xl mx-auto w-full min-w-0">
                            <Outlet />
                        </div>
                    </main>
                </div>
            </div>
        </SidebarProvider>
    );
}
