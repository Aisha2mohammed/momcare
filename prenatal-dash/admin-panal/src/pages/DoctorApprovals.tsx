import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Clock, CheckCircle, XCircle, Eye, ChevronRight } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useDoctors } from '../api/hooks/useDoctors';
import type { ApprovalStatus } from '../api/types';

const tabs: { label: string; value: ApprovalStatus | 'All'; icon: React.ReactNode }[] = [
    { label: 'Pending', value: 'Pending', icon: <Clock className="w-4 h-4" /> },
    { label: 'Approved', value: 'Approved', icon: <CheckCircle className="w-4 h-4" /> },
    { label: 'Rejected', value: 'Rejected', icon: <XCircle className="w-4 h-4" /> },
];

const statusVariantMap: Record<ApprovalStatus, 'yellow' | 'green' | 'red'> = {
    Pending: 'yellow',
    Approved: 'green',
    Rejected: 'red',
};

export default function DoctorApprovals() {
    const [activeTab, setActiveTab] = useState<ApprovalStatus>('Pending');
    const [search, setSearch] = useState('');
    const { doctors } = useDoctors(activeTab);
    const navigate = useNavigate();

    const filtered = doctors.filter(d =>
        d.name.toLowerCase().includes(search.toLowerCase()) ||
        d.specialization.toLowerCase().includes(search.toLowerCase()) ||
        d.providerName.toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Doctor Approvals</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Review and manage doctor registration requests</p>
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-xl w-fit">
                {tabs.map(tab => (
                    <button
                        key={tab.value}
                        onClick={() => setActiveTab(tab.value as ApprovalStatus)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${activeTab === tab.value
                                ? 'bg-white text-[#61183e] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        {tab.icon}
                        {tab.label}
                    </button>
                ))}
            </div>

            <Card>
                {/* Search Bar */}
                <div className="mb-5">
                    <div className="relative max-w-sm">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                            placeholder="Search by name, specialization, or provider..."
                            value={search}
                            onChange={e => setSearch(e.target.value)}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b border-gray-100">
                                {['', 'Doctor Name', 'Specialization', 'Health Provider', 'Submitted Date', 'Status', 'Action'].map(h => (
                                    <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {filtered.length === 0 ? (
                                <tr>
                                    <td colSpan={7} className="text-center text-gray-400 py-12">
                                        <div className="flex flex-col items-center gap-2">
                                            <CheckCircle className="w-10 h-10 text-gray-200" />
                                            <p>No {activeTab.toLowerCase()} applications found.</p>
                                        </div>
                                    </td>
                                </tr>
                            ) : filtered.map(doctor => (
                                <tr key={doctor.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                    <td className="py-3 pr-4">
                                        <div className="w-9 h-9 rounded-full bg-[#fdf2f8] text-[#61183e] text-sm font-bold flex items-center justify-center">
                                            {doctor.name.split(' ').map(n => n[0]).slice(1, 3).join('')}
                                        </div>
                                    </td>
                                    <td className="py-3 pr-4">
                                        <p className="font-medium text-gray-900">{doctor.name}</p>
                                        <p className="text-xs text-gray-400">{doctor.licenseNumber}</p>
                                    </td>
                                    <td className="py-3 pr-4 text-gray-600">{doctor.specialization}</td>
                                    <td className="py-3 pr-4 text-gray-600">{doctor.providerName}</td>
                                    <td className="py-3 pr-4 text-gray-500 whitespace-nowrap">{doctor.submittedDate}</td>
                                    <td className="py-3 pr-4">
                                        <Badge variant={statusVariantMap[doctor.approvalStatus]}>{doctor.approvalStatus}</Badge>
                                    </td>
                                    <td className="py-3">
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            icon={<Eye className="w-4 h-4" />}
                                            onClick={() => navigate(`/doctor-approvals/${doctor.id}`)}
                                        >
                                            Review <ChevronRight className="w-3 h-3 ml-1" />
                                        </Button>
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
