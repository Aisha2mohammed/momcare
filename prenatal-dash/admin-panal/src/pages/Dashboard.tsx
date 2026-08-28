import { useState } from 'react';
import {
    LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
    ResponsiveContainer, Legend, PieChart, Pie, Cell
} from 'recharts';
import { Users, FileText, TrendingUp, UserCheck, Activity, Calendar } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';

// ─── Mock data by date range ───────────────────────────────────────────
const userGrowthData: Record<string, { month: string; mothers: number; doctors: number }[]> = {
    '7d': [
        { month: 'Mon', mothers: 5, doctors: 0 },
        { month: 'Tue', mothers: 8, doctors: 1 },
        { month: 'Wed', mothers: 12, doctors: 0 },
        { month: 'Thu', mothers: 7, doctors: 2 },
        { month: 'Fri', mothers: 15, doctors: 0 },
        { month: 'Sat', mothers: 9, doctors: 1 },
        { month: 'Sun', mothers: 11, doctors: 0 },
    ],
    '30d': [
        { month: 'Dec', mothers: 120, doctors: 1 },
        { month: 'Jan', mothers: 215, doctors: 2 },
        { month: 'Feb', mothers: 280, doctors: 1 },
        { month: 'Mar', mothers: 390, doctors: 3 },
        { month: 'Apr', mothers: 475, doctors: 2 },
        { month: 'May', mothers: 612, doctors: 3 },
    ],
};

const appointmentData: Record<string, { status: string; count: number }[]> = {
    '7d': [
        { status: 'Scheduled', count: 42 },
        { status: 'Completed', count: 68 },
        { status: 'Cancelled', count: 9 },
    ],
    '30d': [
        { status: 'Scheduled', count: 184 },
        { status: 'Completed', count: 271 },
        { status: 'Cancelled', count: 38 },
    ],
};

const featureUsageData = [
    { name: 'Nutrition', value: 1200, color: '#61183e' },
    { name: 'Fetal Dev', value: 980, color: '#e879a8' },
    { name: 'Exercise', value: 750, color: '#8b2563' },
    { name: 'Sleep Tips', value: 620, color: '#c45a8e' },
    { name: 'Music', value: 870, color: '#f0aad0' },
    { name: 'Emergency', value: 540, color: '#fce7f3' },
];

const recentUsers = [
    { id: 'M001', name: 'Tigist Alemu', language: 'Amharic', dueDate: '2025-09-12', registered: '2025-05-01', status: 'Active' },
    { id: 'M002', name: 'Chaltu Gemechu', language: 'Afan Oromo', dueDate: '2025-11-03', registered: '2025-04-28', status: 'Active' },
    { id: 'M003', name: 'Selam Bekele', language: 'Amharic', dueDate: '2025-08-20', registered: '2025-04-25', status: 'Suspended' },
    { id: 'M004', name: 'Hirut Tadesse', language: 'Amharic', dueDate: '2025-10-15', registered: '2025-04-20', status: 'Inactive' },
    { id: 'M005', name: 'Dinkinesh Haile', language: 'Afan Oromo', dueDate: '2025-12-01', registered: '2025-04-18', status: 'Active' },
];

type DateRange = '7d' | '30d';

export default function Dashboard() {
    const [dateRange, setDateRange] = useState<DateRange>('30d');

    const userGrowth = userGrowthData[dateRange];
    const appointments = appointmentData[dateRange];
    const totalAppts = appointments.reduce((s, a) => s + a.count, 0);
    const completedAppts = appointments.find(a => a.status === 'Completed')?.count ?? 0;

    const statsCards = [
        { label: 'Active Mothers', value: '612', icon: Users, change: '+8%', color: 'bg-[#fdf2f8]', iconColor: 'text-[#61183e]' },
        { label: 'Active Doctors', value: '12', icon: UserCheck, change: '+2', color: 'bg-blue-50', iconColor: 'text-blue-600' },
        { label: `Appointments (${dateRange === '7d' ? 'Week' : 'Month'})`, value: String(totalAppts), icon: Calendar, change: `${completedAppts} completed`, color: 'bg-green-50', iconColor: 'text-green-600' },
        { label: 'Doctor Approval Rate', value: '62%', icon: TrendingUp, change: '5 of 8 approved', color: 'bg-amber-50', iconColor: 'text-amber-600' },
        { label: 'Total Content Entries', value: '342', icon: FileText, change: '+5%', color: 'bg-purple-50', iconColor: 'text-purple-600' },
        { label: 'Most-Used Feature', value: 'Nutrition', icon: Activity, change: '1,200 views', color: 'bg-rose-50', iconColor: 'text-rose-600' },
    ];

    return (
        <div className="space-y-7">
            {/* Header */}
            <div className="flex items-center justify-between flex-wrap gap-3">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Dashboard</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Welcome back, Admin — here's today's overview</p>
                </div>
                {/* Date Range Filter */}
                <div className="flex bg-gray-100 p-1 rounded-xl gap-1">
                    {(['7d', '30d'] as DateRange[]).map(r => (
                        <button
                            key={r}
                            onClick={() => setDateRange(r)}
                            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${dateRange === r ? 'bg-white text-[#61183e] shadow-sm' : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            {r === '7d' ? 'Last 7 Days' : 'Last 30 Days'}
                        </button>
                    ))}
                </div>
            </div>

            {/* KPI Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
                {statsCards.map((stat) => (
                    <Card key={stat.label} className="flex items-center gap-4">
                        <div className={`p-3 rounded-xl ${stat.color} shrink-0`}>
                            <stat.icon className={`w-6 h-6 ${stat.iconColor}`} />
                        </div>
                        <div>
                            <p className="text-xs text-gray-500 mb-0.5">{stat.label}</p>
                            <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                            <p className="text-xs text-gray-400 mt-0.5">{stat.change}</p>
                        </div>
                    </Card>
                ))}
            </div>

            {/* Charts Row 1 */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Line Chart */}
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-4">User Growth</h3>
                    <ResponsiveContainer width="100%" height={220}>
                        <LineChart data={userGrowth}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                            <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 11 }} />
                            <Tooltip />
                            <Legend />
                            <Line type="monotone" dataKey="mothers" name="Mothers" stroke="#61183e" strokeWidth={2.5} dot={{ fill: '#61183e', r: 3 }} />
                            <Line type="monotone" dataKey="doctors" name="Doctors" stroke="#3b82f6" strokeWidth={2.5} dot={{ fill: '#3b82f6', r: 3 }} />
                        </LineChart>
                    </ResponsiveContainer>
                </Card>

                {/* Bar Chart */}
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-4">Appointments by Status</h3>
                    <ResponsiveContainer width="100%" height={220}>
                        <BarChart data={appointments} layout="vertical">
                            <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" horizontal={false} />
                            <XAxis type="number" tick={{ fontSize: 11 }} />
                            <YAxis dataKey="status" type="category" tick={{ fontSize: 11 }} />
                            <Tooltip />
                            <Bar dataKey="count" name="Count" radius={[0, 6, 6, 0]}>
                                {appointments.map((entry) => (
                                    <Cell
                                        key={entry.status}
                                        fill={entry.status === 'Completed' ? '#16a34a' : entry.status === 'Scheduled' ? '#61183e' : '#ef4444'}
                                    />
                                ))}
                            </Bar>
                        </BarChart>
                    </ResponsiveContainer>
                </Card>
            </div>

            {/* Charts Row 2: Donut + Recent Users */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Donut Chart */}
                <Card>
                    <h3 className="font-semibold text-gray-800 mb-4">Feature Usage Breakdown</h3>
                    <ResponsiveContainer width="100%" height={200}>
                        <PieChart>
                            <Pie
                                data={featureUsageData}
                                dataKey="value"
                                nameKey="name"
                                cx="50%"
                                cy="50%"
                                innerRadius={55}
                                outerRadius={80}
                                paddingAngle={3}
                            >
                                {featureUsageData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.color} />
                                ))}
                            </Pie>
                            <Tooltip />
                        </PieChart>
                    </ResponsiveContainer>
                    <div className="grid grid-cols-2 gap-1.5 mt-2">
                        {featureUsageData.map(f => (
                            <div key={f.name} className="flex items-center gap-1.5 text-xs text-gray-600">
                                <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: f.color }} />
                                {f.name}
                            </div>
                        ))}
                    </div>
                </Card>

                {/* Recent Signups */}
                <Card className="lg:col-span-2">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="font-semibold text-gray-800">Recent Signups</h3>
                        <a href="/users" className="text-xs text-[#61183e] font-medium hover:underline">View All →</a>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="border-b border-gray-100">
                                    <th className="text-left pb-2.5 text-xs text-gray-500 font-medium">Name</th>
                                    <th className="text-left pb-2.5 text-xs text-gray-500 font-medium">Language</th>
                                    <th className="text-left pb-2.5 text-xs text-gray-500 font-medium">Due Date</th>
                                    <th className="text-left pb-2.5 text-xs text-gray-500 font-medium">Status</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {recentUsers.map((user) => (
                                    <tr key={user.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                        <td className="py-2.5">
                                            <div className="flex items-center gap-2">
                                                <div className="w-7 h-7 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">
                                                    {user.name[0]}
                                                </div>
                                                <span className="font-medium text-gray-800">{user.name}</span>
                                            </div>
                                        </td>
                                        <td className="py-2.5 text-gray-500 text-xs">{user.language}</td>
                                        <td className="py-2.5 text-gray-500 text-xs">{user.dueDate}</td>
                                        <td className="py-2.5">
                                            <Badge variant={user.status === 'Active' ? 'green' : user.status === 'Suspended' ? 'red' : 'gray'}>
                                                {user.status}
                                            </Badge>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </Card>
            </div>
        </div>
    );
}
