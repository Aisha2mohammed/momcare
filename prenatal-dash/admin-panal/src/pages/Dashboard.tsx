import { useState } from 'react';
import {
    LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import { Users, FileText, Bell, TrendingUp, PlusCircle, Send, BarChart2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';

const userGrowth = [
    { month: 'Dec', users: 120 },
    { month: 'Jan', users: 215 },
    { month: 'Feb', users: 280 },
    { month: 'Mar', users: 390 },
    { month: 'Apr', users: 475 },
    { month: 'May', users: 612 },
];

const contentUsage = [
    { name: 'Nutrition', views: 1200 },
    { name: 'Fetal Dev', views: 980 },
    { name: 'Exercise', views: 750 },
    { name: 'Sleep Tips', views: 620 },
    { name: 'Music', views: 870 },
    { name: 'Emergency', views: 540 },
];

const recentUsers = [
    { id: 'U001', name: 'Tigist Alemu', language: 'Amharic', dueDate: '2025-09-12', registered: '2025-05-01', status: 'Active' },
    { id: 'U002', name: 'Chaltu Gemechu', language: 'Afan Oromo', dueDate: '2025-11-03', registered: '2025-04-28', status: 'Active' },
    { id: 'U003', name: 'Selam Bekele', language: 'Amharic', dueDate: '2025-08-20', registered: '2025-04-25', status: 'Active' },
    { id: 'U004', name: 'Hirut Tadesse', language: 'Amharic', dueDate: '2025-10-15', registered: '2025-04-20', status: 'Inactive' },
    { id: 'U005', name: 'Dinkinesh Haile', language: 'Afan Oromo', dueDate: '2025-12-01', registered: '2025-04-18', status: 'Active' },
];

const statsCards = [
    { label: 'Total Registered Users', value: '1,284', icon: Users, change: '+12%', color: 'bg-[#fdf2f8]', iconColor: 'text-[#61183e]' },
    { label: 'Active Users (This Week)', value: '612', icon: TrendingUp, change: '+8%', color: 'bg-blue-50', iconColor: 'text-blue-600' },
    { label: 'Total Content Entries', value: '342', icon: FileText, change: '+5%', color: 'bg-green-50', iconColor: 'text-green-600' },
    { label: 'Pending Notifications', value: '27', icon: Bell, change: '3 urgent', color: 'bg-amber-50', iconColor: 'text-amber-600' },
];

export default function Dashboard() {
    const [_tab, _setTab] = useState('overview');

    return (
        <div className="space-y-8">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Dashboard</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Welcome back, Admin — here's what's happening today</p>
                </div>
                <div className="flex gap-3">
                    <Button variant="secondary" size="sm" icon={<PlusCircle className="w-4 h-4" />}>Add Content</Button>
                    <Button variant="primary" size="sm" icon={<Send className="w-4 h-4" />}>Send Notification</Button>
                    <Button variant="ghost" size="sm" icon={<BarChart2 className="w-4 h-4" />}>Reports</Button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                {statsCards.map((stat) => (
                    <Card key={stat.label} className="flex items-center gap-4">
                        <div className={`p-3 rounded-xl ${stat.color} shrink-0`}>
                            <stat.icon className={`w-6 h-6 ${stat.iconColor}`} />
                        </div>
                        <div>
                            <p className="text-xs text-gray-500">{stat.label}</p>
                            <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                            <p className="text-xs text-green-600 font-medium">{stat.change} this month</p>
                        </div>
                    </Card>
                ))}
            </div>

            {/* Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-4">User Growth (Last 6 Months)</h3>
                    <ResponsiveContainer width="100%" height={220}>
                        <LineChart data={userGrowth}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                            <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                            <YAxis tick={{ fontSize: 12 }} />
                            <Tooltip />
                            <Line type="monotone" dataKey="users" stroke="#61183e" strokeWidth={2.5} dot={{ fill: '#61183e', r: 4 }} />
                        </LineChart>
                    </ResponsiveContainer>
                </Card>

                <Card>
                    <h3 className="font-semibold text-gray-800 mb-4">Content Usage by Feature</h3>
                    <ResponsiveContainer width="100%" height={220}>
                        <BarChart data={contentUsage}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                            <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 12 }} />
                            <Tooltip />
                            <Legend />
                            <Bar dataKey="views" fill="#61183e" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </Card>
            </div>

            {/* Recent Signups */}
            <Card>
                <div className="flex items-center justify-between mb-4">
                    <h3 className="font-semibold text-gray-800">Recent Signups</h3>
                    <Button variant="secondary" size="sm">View All Users</Button>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b border-gray-100">
                                <th className="text-left pb-3 text-xs text-gray-500 font-medium">Name</th>
                                <th className="text-left pb-3 text-xs text-gray-500 font-medium">Language</th>
                                <th className="text-left pb-3 text-xs text-gray-500 font-medium">Due Date</th>
                                <th className="text-left pb-3 text-xs text-gray-500 font-medium">Registered</th>
                                <th className="text-left pb-3 text-xs text-gray-500 font-medium">Status</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {recentUsers.map((user) => (
                                <tr key={user.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                    <td className="py-3">
                                        <div className="flex items-center gap-2">
                                            <div className="w-7 h-7 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center">
                                                {user.name[0]}
                                            </div>
                                            <span className="font-medium text-gray-800">{user.name}</span>
                                        </div>
                                    </td>
                                    <td className="py-3 text-gray-600">{user.language}</td>
                                    <td className="py-3 text-gray-600">{user.dueDate}</td>
                                    <td className="py-3 text-gray-600">{user.registered}</td>
                                    <td className="py-3">
                                        <Badge variant={user.status === 'Active' ? 'green' : 'gray'}>{user.status}</Badge>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </Card>
        </div>
    );
}
