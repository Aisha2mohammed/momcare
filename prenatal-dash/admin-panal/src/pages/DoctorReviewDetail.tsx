import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, CheckCircle, XCircle, FileText, User, Stethoscope, Building2, Phone, Mail } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useDoctors } from '../api/hooks/useDoctors';

export default function DoctorReviewDetail() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { getDoctorById, approveDoctor, rejectDoctor } = useDoctors();
    const doctor = getDoctorById(id ?? '');

    const [showRejectModal, setShowRejectModal] = useState(false);
    const [rejectReason, setRejectReason] = useState('');
    const [actionLoading, setActionLoading] = useState<'approve' | 'reject' | null>(null);
    const [actionDone, setActionDone] = useState<'approved' | 'rejected' | null>(null);

    const handleApprove = async () => {
        if (!doctor) return;
        setActionLoading('approve');
        await approveDoctor(doctor.id);
        setActionLoading(null);
        setActionDone('approved');
        setTimeout(() => navigate('/doctor-approvals'), 1500);
    };

    const handleReject = async () => {
        if (!doctor || !rejectReason.trim()) return;
        setActionLoading('reject');
        await rejectDoctor(doctor.id, rejectReason);
        setActionLoading(null);
        setActionDone('rejected');
        setTimeout(() => navigate('/doctor-approvals'), 1500);
    };

    if (!doctor) {
        return (
            <div className="flex flex-col items-center justify-center py-24 text-gray-400 gap-3">
                <User className="w-12 h-12" />
                <p className="text-lg font-medium">Doctor not found.</p>
                <Button variant="ghost" onClick={() => navigate('/doctor-approvals')}>
                    <ArrowLeft className="w-4 h-4 mr-2" /> Back to Approvals
                </Button>
            </div>
        );
    }

    const statusVariant = doctor.approvalStatus === 'Approved' ? 'green' : doctor.approvalStatus === 'Rejected' ? 'red' : 'yellow';

    return (
        <div className="space-y-6 max-w-4xl">
            {/* Header */}
            <div className="flex items-center gap-4">
                <button onClick={() => navigate('/doctor-approvals')} className="p-2 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors">
                    <ArrowLeft className="w-5 h-5" />
                </button>
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Doctor Review</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Review credentials and make an approval decision</p>
                </div>
                <div className="ml-auto">
                    <Badge variant={statusVariant}>{doctor.approvalStatus}</Badge>
                </div>
            </div>

            {actionDone && (
                <div className={`rounded-xl p-4 flex items-center gap-3 ${actionDone === 'approved' ? 'bg-green-50 border border-green-200 text-green-800' : 'bg-red-50 border border-red-200 text-red-800'}`}>
                    {actionDone === 'approved' ? <CheckCircle className="w-5 h-5" /> : <XCircle className="w-5 h-5" />}
                    <p className="font-medium">Doctor has been {actionDone}. Redirecting...</p>
                </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left column: profile */}
                <div className="lg:col-span-2 space-y-5">
                    {/* Doctor Profile Card */}
                    <Card>
                        <div className="flex items-start gap-4 mb-6">
                            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#fdf2f8] to-pink-100 text-[#61183e] text-2xl font-bold flex items-center justify-center shrink-0">
                                {doctor.name.split(' ').slice(1).map(n => n[0]).join('')}
                            </div>
                            <div>
                                <h3 className="text-lg font-bold text-gray-900">{doctor.name}</h3>
                                <p className="text-sm text-gray-500">{doctor.specialization}</p>
                                <p className="text-xs text-gray-400 mt-0.5">License: {doctor.licenseNumber}</p>
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            {[
                                { icon: Mail, label: 'Email', value: doctor.email },
                                { icon: Phone, label: 'Phone', value: doctor.phone },
                                { icon: Building2, label: 'Health Provider', value: doctor.providerName },
                                { icon: Stethoscope, label: 'Specialization', value: doctor.specialization },
                                { icon: User, label: 'Experience', value: `${doctor.yearsExperience} years` },
                                { icon: FileText, label: 'Submitted', value: doctor.submittedDate },
                            ].map(field => (
                                <div key={field.label} className="bg-gray-50 rounded-xl p-4">
                                    <div className="flex items-center gap-2 mb-1">
                                        <field.icon className="w-3.5 h-3.5 text-gray-400" />
                                        <p className="text-xs text-gray-500">{field.label}</p>
                                    </div>
                                    <p className="font-semibold text-gray-800 text-sm">{field.value}</p>
                                </div>
                            ))}
                        </div>

                        <div className="mt-4 bg-gray-50 rounded-xl p-4">
                            <p className="text-xs text-gray-500 mb-1">Professional Bio</p>
                            <p className="text-sm text-gray-700 leading-relaxed">{doctor.bio}</p>
                        </div>

                        {doctor.rejectionReason && (
                            <div className="mt-4 bg-red-50 border border-red-100 rounded-xl p-4">
                                <p className="text-xs font-medium text-red-600 mb-1">Rejection Reason</p>
                                <p className="text-sm text-red-700">{doctor.rejectionReason}</p>
                            </div>
                        )}
                    </Card>
                </div>

                {/* Right column: document viewer + actions */}
                <div className="space-y-5">
                    {/* Credential Document Viewer */}
                    <Card>
                        <h4 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                            <FileText className="w-4 h-4 text-[#61183e]" />
                            Submitted Credentials
                        </h4>
                        <div className="bg-gray-100 rounded-xl h-52 flex flex-col items-center justify-center text-gray-400 border-2 border-dashed border-gray-200">
                            <FileText className="w-10 h-10 mb-2" />
                            <p className="text-sm font-medium">License Document</p>
                            <p className="text-xs mt-1">{doctor.licenseNumber}.pdf</p>
                            <button className="mt-3 text-xs text-[#61183e] font-medium hover:underline flex items-center gap-1">
                                View Full Document ↗
                            </button>
                        </div>
                    </Card>

                    {/* Actions */}
                    {doctor.approvalStatus === 'Pending' && !actionDone && (
                        <Card>
                            <h4 className="font-semibold text-gray-800 mb-4">Decision</h4>
                            <div className="space-y-3">
                                <Button
                                    variant="primary"
                                    size="sm"
                                    className="w-full"
                                    icon={<CheckCircle className="w-4 h-4" />}
                                    onClick={handleApprove}
                                    disabled={!!actionLoading}
                                >
                                    {actionLoading === 'approve' ? 'Approving...' : 'Approve Doctor'}
                                </Button>
                                <Button
                                    variant="danger"
                                    size="sm"
                                    className="w-full"
                                    icon={<XCircle className="w-4 h-4" />}
                                    onClick={() => setShowRejectModal(true)}
                                    disabled={!!actionLoading}
                                >
                                    Reject Application
                                </Button>
                            </div>
                        </Card>
                    )}
                </div>
            </div>

            {/* Reject Modal */}
            {showRejectModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-2xl shadow-xl max-w-md w-full p-6">
                        <h3 className="text-lg font-bold text-gray-900 mb-2">Reject Application</h3>
                        <p className="text-sm text-gray-500 mb-4">Please provide a reason for rejecting this doctor's registration. This will be sent to the doctor via email.</p>
                        <textarea
                            value={rejectReason}
                            onChange={e => setRejectReason(e.target.value)}
                            placeholder="e.g., License number could not be verified..."
                            rows={4}
                            className="w-full px-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-red-400 focus:ring-2 focus:ring-red-100 resize-none"
                        />
                        <div className="flex gap-3 mt-4">
                            <Button
                                variant="danger"
                                size="sm"
                                className="flex-1"
                                onClick={handleReject}
                                disabled={!rejectReason.trim() || !!actionLoading}
                            >
                                {actionLoading === 'reject' ? 'Rejecting...' : 'Confirm Rejection'}
                            </Button>
                            <Button variant="secondary" size="sm" className="flex-1" onClick={() => setShowRejectModal(false)}>
                                Cancel
                            </Button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
