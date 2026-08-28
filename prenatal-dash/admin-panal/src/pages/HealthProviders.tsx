import { useState } from 'react';
import { Plus, Edit2, ToggleLeft, ToggleRight, MapPin, Phone, Mail, Building2, Users, X, Check } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { useProviders } from '../api/hooks/useProviders';
import { mockDoctors } from '../api/mockData';
import type { HealthProvider } from '../api/types';

type FormData = Omit<HealthProvider, 'id' | 'linkedDoctorCount' | 'linkedDoctors' | 'createdAt'>;

const emptyForm: FormData = {
    name: '',
    address: '',
    city: '',
    region: '',
    phone: '',
    email: '',
    serviceDescription: '',
    status: 'Active',
};

export default function HealthProviders() {
    const { providers, toggleStatus, addProvider, updateProvider } = useProviders();
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [form, setForm] = useState<FormData>(emptyForm);
    const [saving, setSaving] = useState(false);
    const [selectedProvider, setSelectedProvider] = useState<string | null>(null);

    const startAdd = () => {
        setForm(emptyForm);
        setEditingId(null);
        setShowForm(true);
    };

    const startEdit = (p: HealthProvider) => {
        setForm({
            name: p.name, address: p.address, city: p.city, region: p.region,
            phone: p.phone, email: p.email, serviceDescription: p.serviceDescription, status: p.status,
        });
        setEditingId(p.id);
        setShowForm(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);
        if (editingId) {
            await updateProvider(editingId, form);
        } else {
            await addProvider(form);
        }
        setSaving(false);
        setShowForm(false);
        setEditingId(null);
    };

    const linkedDoctors = (p: HealthProvider) =>
        mockDoctors.filter(d => p.linkedDoctors.includes(d.id));

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Health Providers</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage registered health facilities</p>
                </div>
                <Button variant="primary" size="sm" icon={<Plus className="w-4 h-4" />} onClick={startAdd}>
                    Add Provider
                </Button>
            </div>

            {/* Provider Cards Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                {providers.map(p => (
                    <Card key={p.id} className="relative">
                        <div className="flex items-start justify-between mb-4">
                            <div className="flex items-start gap-3">
                                <div className="w-10 h-10 rounded-xl bg-[#fdf2f8] flex items-center justify-center shrink-0">
                                    <Building2 className="w-5 h-5 text-[#61183e]" />
                                </div>
                                <div>
                                    <h3 className="font-semibold text-gray-900">{p.name}</h3>
                                    <p className="text-xs text-gray-500 mt-0.5">{p.city}, {p.region}</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <Badge variant={p.status === 'Active' ? 'green' : 'gray'}>{p.status}</Badge>
                            </div>
                        </div>

                        <div className="space-y-2 mb-4">
                            <div className="flex items-center gap-2 text-sm text-gray-600">
                                <MapPin className="w-3.5 h-3.5 text-gray-400" />
                                {p.address}
                            </div>
                            <div className="flex items-center gap-2 text-sm text-gray-600">
                                <Phone className="w-3.5 h-3.5 text-gray-400" />
                                {p.phone}
                            </div>
                            <div className="flex items-center gap-2 text-sm text-gray-600">
                                <Mail className="w-3.5 h-3.5 text-gray-400" />
                                {p.email}
                            </div>
                        </div>

                        <p className="text-xs text-gray-500 bg-gray-50 rounded-lg p-3 mb-4 line-clamp-2">{p.serviceDescription}</p>

                        <div className="flex items-center justify-between">
                            <button
                                onClick={() => setSelectedProvider(selectedProvider === p.id ? null : p.id)}
                                className="flex items-center gap-1.5 text-xs text-[#61183e] font-medium hover:underline"
                            >
                                <Users className="w-3.5 h-3.5" />
                                {p.linkedDoctorCount} linked doctor{p.linkedDoctorCount !== 1 ? 's' : ''}
                            </button>
                            <div className="flex gap-2">
                                <button
                                    onClick={() => startEdit(p)}
                                    className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors"
                                    title="Edit"
                                >
                                    <Edit2 className="w-4 h-4" />
                                </button>
                                <button
                                    onClick={() => toggleStatus(p.id)}
                                    className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
                                    title={p.status === 'Active' ? 'Deactivate' : 'Activate'}
                                >
                                    {p.status === 'Active'
                                        ? <ToggleRight className="w-5 h-5 text-green-500" />
                                        : <ToggleLeft className="w-5 h-5 text-gray-400" />}
                                </button>
                            </div>
                        </div>

                        {/* Linked doctors drawer */}
                        {selectedProvider === p.id && (
                            <div className="mt-4 pt-4 border-t border-gray-100">
                                <p className="text-xs font-semibold text-gray-500 mb-2">Linked Doctors</p>
                                {linkedDoctors(p).length === 0 ? (
                                    <p className="text-xs text-gray-400">No doctors linked.</p>
                                ) : (
                                    <div className="space-y-2">
                                        {linkedDoctors(p).map(d => (
                                            <div key={d.id} className="flex items-center gap-2">
                                                <div className="w-6 h-6 rounded-full bg-[#fdf2f8] text-[#61183e] text-xs font-bold flex items-center justify-center">
                                                    {d.name.split(' ').slice(1).map(n => n[0]).join('')}
                                                </div>
                                                <div>
                                                    <p className="text-xs font-medium text-gray-700">{d.name}</p>
                                                    <p className="text-xs text-gray-400">{d.specialization}</p>
                                                </div>
                                                <Badge variant={d.approvalStatus === 'Approved' ? 'green' : 'yellow'} className="ml-auto">
                                                    {d.approvalStatus}
                                                </Badge>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        )}
                    </Card>
                ))}
            </div>

            {/* Add/Edit Form Modal */}
            {showForm && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-2xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between p-6 border-b border-gray-100">
                            <h3 className="text-lg font-bold text-gray-900">
                                {editingId ? 'Edit Provider' : 'Add Health Provider'}
                            </h3>
                            <button onClick={() => setShowForm(false)} className="p-2 rounded-lg hover:bg-gray-100">
                                <X className="w-5 h-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            {[
                                { label: 'Facility Name', key: 'name', placeholder: 'e.g. Black Lion Hospital' },
                                { label: 'Address', key: 'address', placeholder: 'Street address...' },
                                { label: 'City', key: 'city', placeholder: 'e.g. Addis Ababa' },
                                { label: 'Region', key: 'region', placeholder: 'e.g. Oromia' },
                                { label: 'Phone', key: 'phone', placeholder: '+251...' },
                                { label: 'Email', key: 'email', placeholder: 'info@facility.et' },
                            ].map(({ label, key, placeholder }) => (
                                <div key={key}>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">{label}</label>
                                    <input
                                        required
                                        type="text"
                                        placeholder={placeholder}
                                        value={(form as Record<string, string>)[key]}
                                        onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                                        className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20"
                                    />
                                </div>
                            ))}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1.5">Service Description</label>
                                <textarea
                                    rows={3}
                                    placeholder="Describe services provided..."
                                    value={form.serviceDescription}
                                    onChange={e => setForm(f => ({ ...f, serviceDescription: e.target.value }))}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 resize-none"
                                />
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="submit" variant="primary" size="sm" className="flex-1" icon={<Check className="w-4 h-4" />} disabled={saving}>
                                    {saving ? 'Saving...' : editingId ? 'Save Changes' : 'Add Provider'}
                                </Button>
                                <Button type="button" variant="secondary" size="sm" className="flex-1" onClick={() => setShowForm(false)}>
                                    Cancel
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
