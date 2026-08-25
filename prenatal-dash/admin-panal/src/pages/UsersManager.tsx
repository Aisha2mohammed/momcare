import { useState } from 'react';
import { Search, Download, Eye, UserX, ChevronDown } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input } from '../components/ui/Input';
import { Drawer } from '../components/ui/Modal';

const mockUsers = [
    { id: 'U001', name: 'Tigist Alemu', phone: '+251911234567', language: 'Amharic', week: 24, dueDate: '2025-09-12', status: 'Active', registered: '2025-05-01' },
    { id: 'U002', name: 'Chaltu Gemechu', phone: '+251922345678', language: 'Afan Oromo', week: 16, dueDate: '2025-11-03', status: 'Active', registered: '2025-04-28' },
    { id: 'U003', name: 'Selam Bekele', phone: '+251933456789', language: 'Amharic', week: 30, dueDate: '2025-08-20', status: 'Active', registered: '2025-04-25' },
    { id: 'U004', name: 'Hirut Tadesse', phone: '+251944567890', language: 'Amharic', week: 20, dueDate: '2025-10-15', status: 'Inactive', registered: '2025-04-20' },
    { id: 'U005', name: 'Dinkinesh Haile', phone: '+251955678901', language: 'Afan Oromo', week: 8, dueDate: '2025-12-01', status: 'Active', registered: '2025-04-18' },
    { id: 'U006', name: 'Mekdes Worku', phone: '+251966789012', language: 'Amharic', week: 36, dueDate: '2025-07-05', status: 'Active', registered: '2025-04-10' },
    { id: 'U007', name: 'Hawi Gudeta', phone: '+251977890123', language: 'Afan Oromo', week: 12, dueDate: '2025-11-22', status: 'Inactive', registered: '2025-04-05' },
];

const notifHistory = [
    { date: '2025-05-03', title: 'Week 24 Checkup Reminder', status: 'Delivered' },
    { date: '2025-04-25', title: 'Iron-rich Foods Tip', status: 'Delivered' },
    { date: '2025-04-15', title: 'Sleep Position Advisory', status: 'Delivered' },
];

type User = typeof mockUsers[0];

export default function UsersManager() {
    const [search, setSearch] = useState('');
    const [langFilter, setLangFilter] = useState('All');
    const [statusFilter, setStatusFilter] = useState('All');
    const [selectedUser, setSelectedUser] = useState<User | null>(null);

    const filtered = mockUsers.filter(u => {
        const matchSearch = u.name.toLowerCase().includes(search.toLowerCase()) || u.phone.includes(search);
        const matchLang = langFilter === 'All' || u.language === langFilter;
        const matchStatus = statusFilter === 'All' || u.status === statusFilter;
        return matchSearch && matchLang && matchStatus;
    });

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Users Management</h2>
                    <p className="text-gray-500 text-sm mt-0.5">{mockUsers.length} total registered users</p>
                </div>
                <Button variant="secondary" size="sm" icon={<Download className="w-4 h-4" />}>Export CSV</Button>
            </div>

            <Card>
                <div className="flex flex-wrap gap-3 mb-6">
                    <div className="flex-1 min-w-[200px]">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                            <input
                                className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                                placeholder="Search by name or phone..."
                                value={search}
                                onChange={e => setSearch(e.target.value)}
                            />
                        </div>
                    </div>
                    <div className="relative">
                        <select
                            value={langFilter}
                            onChange={e => setLangFilter(e.target.value)}
                            className="pl-3 pr-8 py-2 text-sm border border-gray-200 rounded-lg appearance-none bg-white focus:outline-none focus:border-[#61183e] cursor-pointer"
                        >
                            <option value="All">All Languages</option>
                            <option value="Amharic">Amharic</option>
                            <option value="Afan Oromo">Afan Oromo</option>
                        </select>
                        <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                    </div>
                    <div className="relative">
                        <select
                            value={statusFilter}
                            onChange={e => setStatusFilter(e.target.value)}
                            className="pl-3 pr-8 py-2 text-sm border border-gray-200 rounded-lg appearance-none bg-white focus:outline-none focus:border-[#61183e] cursor-pointer"
                        >
                            <option value="All">All Status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                        </select>
                        <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b border-gray-100">
                                {['User ID', 'Name', 'Phone', 'Language', 'Gest. Week', 'Due Date', 'Registered', 'Status', 'Actions'].map(h => (
                                    <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {filtered.map(user => (
                                <tr key={user.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                    <td className="py-3 pr-4 text-gray-500 font-mono text-xs">{user.id}</td>
                                    <td className="py-3 pr-4">
                                        <div className="flex items-center gap-2">
                                            <div className="w-7 h-7 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">{user.name[0]}</div>
                                            <span className="font-medium text-gray-800 whitespace-nowrap">{user.name}</span>
                                        </div>
                                    </td>
                                    <td className="py-3 pr-4 text-gray-600">{user.phone}</td>
                                    <td className="py-3 pr-4">
                                        <Badge variant={user.language === 'Amharic' ? 'pink' : 'blue'}>{user.language}</Badge>
                                    </td>
                                    <td className="py-3 pr-4 text-gray-600">Week {user.week}</td>
                                    <td className="py-3 pr-4 text-gray-600 whitespace-nowrap">{user.dueDate}</td>
                                    <td className="py-3 pr-4 text-gray-600 whitespace-nowrap">{user.registered}</td>
                                    <td className="py-3 pr-4">
                                        <Badge variant={user.status === 'Active' ? 'green' : 'gray'}>{user.status}</Badge>
                                    </td>
                                    <td className="py-3">
                                        <div className="flex gap-2">
                                            <button onClick={() => setSelectedUser(user)} className="p-1.5 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors" title="View Profile">
                                                <Eye className="w-4 h-4" />
                                            </button>
                                            <button className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Deactivate">
                                                <UserX className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {filtered.length === 0 && (
                        <p className="text-center text-gray-400 py-8">No users match your filters.</p>
                    )}
                </div>
            </Card>

            {/* User Profile Drawer */}
            <Drawer isOpen={!!selectedUser} onClose={() => setSelectedUser(null)} title="User Profile">
                {selectedUser && (
                    <div className="space-y-6">
                        <div className="flex items-center gap-4">
                            <div className="w-16 h-16 rounded-full bg-[#fdf2f8] text-[#61183e] text-2xl font-bold flex items-center justify-center">
                                {selectedUser.name[0]}
                            </div>
                            <div>
                                <h4 className="text-lg font-bold text-gray-900">{selectedUser.name}</h4>
                                <p className="text-sm text-gray-500">{selectedUser.id}</p>
                                <Badge variant={selectedUser.status === 'Active' ? 'green' : 'gray'} className="mt-1">{selectedUser.status}</Badge>
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            {[
                                { label: 'Phone', value: selectedUser.phone },
                                { label: 'Language', value: selectedUser.language },
                                { label: 'Gestational Week', value: `Week ${selectedUser.week}` },
                                { label: 'Due Date', value: selectedUser.dueDate },
                                { label: 'Registered', value: selectedUser.registered },
                            ].map(item => (
                                <div key={item.label} className="bg-[#fdf2f8]/50 rounded-xl p-4">
                                    <p className="text-xs text-gray-500 mb-1">{item.label}</p>
                                    <p className="font-semibold text-gray-800">{item.value}</p>
                                </div>
                            ))}
                        </div>

                        <div>
                            <h5 className="font-semibold text-gray-800 mb-3">Notification History</h5>
                            <div className="space-y-2">
                                {notifHistory.map((n, i) => (
                                    <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg text-sm">
                                        <div>
                                            <p className="font-medium text-gray-700">{n.title}</p>
                                            <p className="text-xs text-gray-400">{n.date}</p>
                                        </div>
                                        <Badge variant="green">{n.status}</Badge>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="flex gap-3 pt-2">
                            <Button variant="danger" size="sm" icon={<UserX className="w-4 h-4" />} className="flex-1">
                                Deactivate Account
                            </Button>
                            <Button variant="primary" size="sm" icon={<Bell className="w-4 h-4" />} className="flex-1">
                                Send Notification
                            </Button>
                        </div>
                    </div>
                )}
            </Drawer>
        </div>
    );
}

function Bell(props: { className: string }) {
    return <svg {...props} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" /></svg>;
}
