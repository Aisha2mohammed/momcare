import { useState, useEffect } from 'react';
import { Search, Download, Eye, UserX, UserCheck, ChevronDown, X, Check } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Drawer } from '../components/ui/Modal';
import { useMothers, useApprovedDoctors } from '../api/hooks/useUsers';
import { adminDoctorsApi } from '../services/api';
import type { Mother, Doctor, Status } from '../api/types';

type UserTab = 'Mothers' | 'Doctors';

type ConfirmModal = {
    open: boolean;
    targetId: string;
    targetName: string;
    action: 'Suspend' | 'Reactivate' | 'Approve' | 'Reject';
    reason: string;
};

export default function UsersManager() {
    const [tab, setTab] = useState<UserTab>('Mothers');
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState<'All' | Status>('All');
    const [selectedMother, setSelectedMother] = useState<Mother | null>(null);
    const [selectedDoctor, setSelectedDoctor] = useState<Doctor | null>(null);
    const [confirm, setConfirm] = useState<ConfirmModal>({
        open: false, targetId: '', targetName: '', action: 'Suspend', reason: '',
    });
    const [actionLoading, setActionLoading] = useState(false);

    const {
        mothers,
        isLoading,
        error,
        updateMotherStatus,
        approveMother,
        rejectMother,
        reactivateMother,
        loadAllUsers,
    } = useMothers();
    const { doctors, refresh: refreshDoctors } = useApprovedDoctors();

    // Load every real mother and doctor into the table.
    useEffect(() => {
        loadAllUsers();
        refreshDoctors();
    }, [loadAllUsers, refreshDoctors]);

    // ─── Filter logic ───────────────────────────────────────────────────
    const filteredMothers = mothers.filter(m => {
        const matchSearch = m.name.toLowerCase().includes(search.toLowerCase()) || m.phone.includes(search);
        const matchStatus = statusFilter === 'All' || m.status === statusFilter;
        return matchSearch && matchStatus;
    });

    const filteredDoctors = doctors.filter(d => {
        const matchSearch = d.name.toLowerCase().includes(search.toLowerCase()) || d.specialization.toLowerCase().includes(search.toLowerCase());
        const matchStatus = statusFilter === 'All' || d.status === statusFilter;
        return matchSearch && matchStatus;
    });

    // ─── Action handlers ─────────────────────────────────────────────────
    const openConfirm = (id: string, name: string, action: ConfirmModal['action']) => {
        setConfirm({
            open: true,
            targetId: id,
            targetName: name,
            action,
            reason: '',
        });
    };

    const applyAction = async () => {
        setActionLoading(true);
        try {
            if (tab === 'Doctors') {
                if (confirm.action === 'Approve') {
                    await adminDoctorsApi.adminApproveDoctor(confirm.targetId);
                } else if (confirm.action === 'Reject') {
                    await adminDoctorsApi.adminRejectDoctor(confirm.targetId, confirm.reason);
                } else if (confirm.action === 'Suspend') {
                    await adminDoctorsApi.adminSuspendDoctor(confirm.targetId);
                } else if (confirm.action === 'Reactivate') {
                    await adminDoctorsApi.adminReactivateDoctor(confirm.targetId);
                }
                await refreshDoctors();
            } else if (confirm.action === 'Approve') {
                await approveMother(confirm.targetId);
            } else if (confirm.action === 'Reject') {
                await rejectMother(confirm.targetId);
            } else if (confirm.action === 'Reactivate') {
                await reactivateMother(confirm.targetId);
            } else {
                await updateMotherStatus(confirm.targetId, 'Suspended', confirm.reason);
            }
        } finally {
            setActionLoading(false);
            setConfirm(c => ({ ...c, open: false }));
        }
    };

    const exportCSV = () => {
        const rows = tab === 'Mothers'
            ? filteredMothers.map(m => `"${m.id}","${m.name}","${m.phone}","${m.email}","${m.language}","Week ${m.week}","${m.dueDate}","${m.status}"`)
            : filteredDoctors.map(d => `"${d.id}","${d.name}","${d.email}","${d.specialization}","${d.providerName}","${d.status}"`);
        const header = tab === 'Mothers'
            ? '"ID","Name","Phone","Email","Language","Week","Due Date","Status"'
            : '"ID","Name","Email","Specialization","Provider","Status"';
        const csv = [header, ...rows].join('\n');
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${tab.toLowerCase()}-export.csv`;
        a.click();
        URL.revokeObjectURL(url);
    };

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                    <h2 className="text-xl sm:text-2xl font-bold text-[#61183e]">Users Management</h2>
                    <p className="text-gray-500 text-xs sm:text-sm mt-0.5">
                        {tab === 'Mothers' ? `${filteredMothers.length} mothers` : `${filteredDoctors.length} approved doctors`}
                    </p>
                </div>
                <Button variant="secondary" size="sm" icon={<Download className="w-4 h-4" />} onClick={exportCSV} className="w-fit">
                    Export CSV
                </Button>
            </div>

            {/* Tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-xl w-fit max-w-full overflow-x-auto">
                {(['Mothers', 'Doctors'] as UserTab[]).map(t => (
                    <button
                        key={t}
                        onClick={() => { setTab(t); setSearch(''); setStatusFilter('All'); }}
                        className={`px-5 py-2 rounded-lg text-sm font-medium transition-all shrink-0 ${tab === t ? 'bg-white text-[#61183e] shadow-sm' : 'text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        {t}
                    </button>
                ))}
            </div>

            <Card>
                {/* Filters */}
                <div className="flex flex-wrap gap-3 mb-6">
                    <div className="flex-1 min-w-[200px] relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                            placeholder={tab === 'Mothers' ? 'Search by name or phone...' : 'Search by name or specialization...'}
                            value={search}
                            onChange={e => setSearch(e.target.value)}
                        />
                    </div>
                    <div className="relative">
                        <select
                            value={statusFilter}
                            onChange={e => setStatusFilter(e.target.value as 'All' | Status)}
                            className="pl-3 pr-8 py-2 text-sm border border-gray-200 rounded-lg appearance-none bg-white focus:outline-none focus:border-[#61183e] cursor-pointer"
                        >
                            <option value="All">All Status</option>
                            <option value="Active">Active</option>
                            <option value="Pending">Pending</option>
                            <option value="Rejected">Rejected</option>
                            <option value="Suspended">Suspended</option>
                            <option value="Inactive">Inactive</option>
                        </select>
                        <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                    </div>
                </div>

                {/* Mothers Table */}
                {tab === 'Mothers' && (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm min-w-[650px]">
                            <thead>
                                <tr className="border-b border-gray-100">
                                    {['Name', 'Phone', 'Language', 'Week', 'Due Date', 'Status', 'Actions'].map(h => (
                                        <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {isLoading && mothers.length === 0 ? (
                                    <tr><td colSpan={7} className="py-10 text-center text-gray-400">
                                        <span className="inline-flex items-center gap-2">
                                            <span className="w-4 h-4 border-2 border-[#61183e]/30 border-t-[#61183e] rounded-full animate-spin" />
                                            Loading mothers…
                                        </span>
                                    </td></tr>
                                ) : error ? (
                                    <tr><td colSpan={7} className="py-10 text-center">
                                        <p className="text-sm text-red-600 mb-2">{error}</p>
                                        <Button variant="primary" size="sm" onClick={loadAllUsers}>Retry</Button>
                                    </td></tr>
                                ) : mothers.length === 0 ? (
                                    <tr><td colSpan={7} className="text-center text-gray-400 py-10">No mothers yet</td></tr>
                                ) : filteredMothers.length === 0 ? (
                                    <tr><td colSpan={7} className="text-center text-gray-400 py-10">No mothers match your filters.</td></tr>
                                ) : filteredMothers.map(m => (
                                    <tr key={m.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                        <td className="py-3 pr-4">
                                            <div className="flex items-center gap-2">
                                                <div className="w-7 h-7 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center shrink-0">{m.name[0]}</div>
                                                <span className="font-medium text-gray-800 whitespace-nowrap">{m.name}</span>
                                            </div>
                                        </td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs">{m.phone}</td>
                                        <td className="py-3 pr-4"><Badge variant={m.language === 'Amharic' ? 'pink' : 'blue'}>{m.language}</Badge></td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs">Wk {m.week}</td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs whitespace-nowrap">{m.dueDate}</td>
                                        <td className="py-3 pr-4">
                                            <Badge variant={m.status === 'Active' ? 'green' : m.status === 'Pending' ? 'yellow' : m.status === 'Suspended' || m.status === 'Rejected' ? 'red' : 'gray'}>{m.status}</Badge>
                                        </td>
                                        <td className="py-3">
                                            <div className="flex gap-1.5">
                                                <button onClick={() => setSelectedMother(m)} className="p-1.5 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors" title="View">
                                                    <Eye className="w-4 h-4" />
                                                </button>
                                                {m.status === 'Pending' && (
                                                    <>
                                                        <button onClick={() => openConfirm(m.id, m.name, 'Approve')} className="p-1.5 rounded-lg hover:bg-green-50 text-green-600 transition-colors" title="Approve">
                                                            <Check className="w-4 h-4" />
                                                        </button>
                                                        <button onClick={() => openConfirm(m.id, m.name, 'Reject')} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Reject">
                                                            <X className="w-4 h-4" />
                                                        </button>
                                                    </>
                                                )}
                                                {m.status === 'Active' && (
                                                    <button onClick={() => openConfirm(m.id, m.name, 'Suspend')} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Suspend">
                                                        <UserX className="w-4 h-4" />
                                                    </button>
                                                )}
                                                {(m.status === 'Suspended' || m.status === 'Rejected' || m.status === 'Inactive') && (
                                                    <button onClick={() => openConfirm(m.id, m.name, 'Reactivate')} className="p-1.5 rounded-lg hover:bg-green-50 text-green-600 transition-colors" title="Reactivate">
                                                        <UserCheck className="w-4 h-4" />
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Doctors Table */}
                {tab === 'Doctors' && (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm min-w-[650px]">
                            <thead>
                                <tr className="border-b border-gray-100">
                                    {['Name', 'Email', 'Specialization', 'Provider', 'Experience', 'Status', 'Actions'].map(h => (
                                        <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {filteredDoctors.length === 0 ? (
                                    <tr><td colSpan={7} className="text-center text-gray-400 py-10">No approved doctors match your filters.</td></tr>
                                ) : filteredDoctors.map(d => (
                                    <tr key={d.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                        <td className="py-3 pr-4">
                                            <div className="flex items-center gap-2">
                                                <div className="w-7 h-7 rounded-full bg-blue-50 text-blue-600 text-xs font-bold flex items-center justify-center shrink-0">
                                                    {d.name.split(' ').slice(1).map(n => n[0]).join('')}
                                                </div>
                                                <span className="font-medium text-gray-800 whitespace-nowrap">{d.name}</span>
                                            </div>
                                        </td>
                                        <td className="py-3 pr-4 text-gray-500 text-xs">{d.email}</td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs">{d.specialization}</td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs">{d.hospitalClinicName || d.providerName}</td>
                                        <td className="py-3 pr-4 text-gray-600 text-xs">{d.yearsExperience} yrs</td>
                                        <td className="py-3 pr-4">
                                            <Badge variant={d.status === 'Active' ? 'green' : d.status === 'Pending' ? 'yellow' : d.status === 'Suspended' ? 'red' : 'gray'}>{d.status}</Badge>
                                        </td>
                                        <td className="py-3">
                                            <div className="flex gap-1.5">
                                                <button onClick={() => setSelectedDoctor(d)} className="p-1.5 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors" title="View">
                                                    <Eye className="w-4 h-4" />
                                                </button>
                                                {d.status === 'Pending' ? (
                                                    <>
                                                        <button onClick={() => openConfirm(d.id, d.name, 'Approve')} className="p-1.5 rounded-lg hover:bg-green-50 text-green-600 transition-colors" title="Approve">
                                                            <Check className="w-4 h-4" />
                                                        </button>
                                                        <button onClick={() => openConfirm(d.id, d.name, 'Reject')} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Reject">
                                                            <X className="w-4 h-4" />
                                                        </button>
                                                    </>
                                                ) : d.status === 'Active' ? (
                                                    <button onClick={() => openConfirm(d.id, d.name, 'Suspend')} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Suspend">
                                                        <UserX className="w-4 h-4" />
                                                    </button>
                                                ) : (
                                                    <button onClick={() => openConfirm(d.id, d.name, 'Reactivate')} className="p-1.5 rounded-lg hover:bg-green-50 text-green-600 transition-colors" title="Reactivate">
                                                        <UserCheck className="w-4 h-4" />
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </Card>

            {/* Mother Profile Drawer */}
            <Drawer isOpen={!!selectedMother} onClose={() => setSelectedMother(null)} title="Mother Profile">
                {selectedMother && (
                    <div className="space-y-5">
                        <div className="flex items-center gap-4">
                            <div className="w-14 h-14 rounded-full bg-[#fdf2f8] text-[#61183e] text-xl font-bold flex items-center justify-center">{selectedMother.name[0]}</div>
                            <div>
                                <h4 className="text-lg font-bold text-gray-900">{selectedMother.name}</h4>
                                <p className="text-sm text-gray-500">{selectedMother.email}</p>
                                <Badge variant={selectedMother.status === 'Active' ? 'green' : selectedMother.status === 'Pending' ? 'yellow' : selectedMother.status === 'Suspended' || selectedMother.status === 'Rejected' ? 'red' : 'gray'} className="mt-1">{selectedMother.status}</Badge>
                            </div>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            {[
                                { label: 'Phone', value: selectedMother.phone },
                                { label: 'Language', value: selectedMother.language },
                                { label: 'Gestational Week', value: `Week ${selectedMother.week}` },
                                { label: 'Due Date', value: selectedMother.dueDate },
                                { label: 'Registered', value: selectedMother.registered },
                            ].map(item => (
                                <div key={item.label} className="bg-gray-50 rounded-xl p-3">
                                    <p className="text-xs text-gray-500 mb-0.5">{item.label}</p>
                                    <p className="font-semibold text-gray-800 text-sm">{item.value}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </Drawer>

            {/* Doctor Profile Drawer */}
            <Drawer isOpen={!!selectedDoctor} onClose={() => setSelectedDoctor(null)} title="Doctor Profile">
                {selectedDoctor && (
                    <div className="space-y-5">
                        <div className="flex items-center gap-4">
                            <div className="w-14 h-14 rounded-full bg-blue-50 text-blue-600 text-xl font-bold flex items-center justify-center">
                                {selectedDoctor.name.split(' ').slice(1).map(n => n[0]).join('')}
                            </div>
                            <div>
                                <h4 className="text-lg font-bold text-gray-900">{selectedDoctor.name}</h4>
                                <p className="text-sm text-gray-500">{selectedDoctor.specialization}</p>
                                <Badge variant={selectedDoctor.status === 'Active' ? 'green' : 'red'} className="mt-1">{selectedDoctor.status}</Badge>
                            </div>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            {[
                                { label: 'Email', value: selectedDoctor.email || 'N/A' },
                                { label: 'Phone', value: selectedDoctor.phone },
                                { label: 'Medical License', value: selectedDoctor.licenseNumber },
                                { label: 'License Expiry', value: selectedDoctor.licenseExpiryDate || 'N/A' },
                                { label: 'National ID', value: selectedDoctor.nationalId || 'N/A' },
                                { label: 'Hospital / Clinic', value: selectedDoctor.hospitalClinicName || selectedDoctor.providerName || 'N/A' },
                                { label: 'Practice Location', value: selectedDoctor.location || 'N/A' },
                                { label: 'Experience', value: `${selectedDoctor.yearsExperience} years` },
                            ].map(item => (
                                <div key={item.label} className="bg-gray-50 rounded-xl p-3">
                                    <p className="text-xs text-gray-500 mb-0.5">{item.label}</p>
                                    <p className="font-semibold text-gray-800 text-sm">{item.value}</p>
                                </div>
                            ))}
                        </div>
                        <div className="bg-gray-50 rounded-xl p-4">
                            <p className="text-xs text-gray-500 mb-1">Bio</p>
                            <p className="text-sm text-gray-700 leading-relaxed">{selectedDoctor.bio}</p>
                        </div>
                        {(selectedDoctor.nationalIdUrl || selectedDoctor.credentialDocumentUrl) && (
                            <div className="flex gap-2 pt-1">
                                {selectedDoctor.nationalIdUrl && (
                                    <a
                                        href={selectedDoctor.nationalIdUrl}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="flex-1 text-center py-2 px-3 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-xl text-xs font-semibold transition-colors"
                                    >
                                        View National ID ↗
                                    </a>
                                )}
                                {selectedDoctor.credentialDocumentUrl && (
                                    <a
                                        href={selectedDoctor.credentialDocumentUrl}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="flex-1 text-center py-2 px-3 bg-[#61183e] hover:bg-[#4a122f] text-white rounded-xl text-xs font-semibold transition-colors"
                                    >
                                        View Certificate ↗
                                    </a>
                                )}
                            </div>
                        )}
                    </div>
                )}
            </Drawer>

            {/* Suspend / Reactivate Confirmation Modal */}
            {confirm.open && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-2xl shadow-xl max-w-sm w-full p-6">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-lg font-bold text-gray-900">
                                {confirm.action} Account
                            </h3>
                            <button onClick={() => setConfirm(c => ({ ...c, open: false }))} className="p-1.5 rounded-lg hover:bg-gray-100">
                                <X className="w-4 h-4 text-gray-400" />
                            </button>
                        </div>
                        <p className="text-sm text-gray-600 mb-4">
                            Are you sure you want to <strong>{confirm.action.toLowerCase()}</strong> <strong>{confirm.targetName}</strong>'s account?
                        </p>
                        <div className="mb-4">
                            <label className="block text-sm font-medium text-gray-700 mb-1.5">Reason (optional)</label>
                            <textarea
                                rows={3}
                                placeholder="Provide a reason for this action..."
                                value={confirm.reason}
                                onChange={e => setConfirm(c => ({ ...c, reason: e.target.value }))}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 resize-none"
                            />
                            <p className="text-xs text-gray-400 mt-1">This reason will be recorded in the audit log.</p>
                        </div>
                        <div className="flex gap-3">
                            <Button
                                variant={confirm.action === 'Suspend' || confirm.action === 'Reject' ? 'danger' : 'primary'}
                                size="sm"
                                className="flex-1"
                                onClick={applyAction}
                                disabled={actionLoading}
                            >
                                {actionLoading ? 'Processing...' : confirm.action}
                            </Button>
                            <Button
                                variant="secondary"
                                size="sm"
                                className="flex-1"
                                onClick={() => setConfirm(c => ({ ...c, open: false }))}
                            >
                                Cancel
                            </Button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
