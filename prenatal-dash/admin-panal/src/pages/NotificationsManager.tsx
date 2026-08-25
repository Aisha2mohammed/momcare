import { useState } from 'react';
import { Plus, Send, Clock, Users, ChevronDown } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';

interface Notification {
    id: number;
    titleAm: string;
    titleOr: string;
    bodyAm: string;
    bodyOr: string;
    audience: string;
    schedule: string;
    type: string;
    status: string;
    openRate?: string;
}

const initial: Notification[] = [
    { id: 1, titleAm: 'ሳምንት 20 ጥቆማ', titleOr: 'Torbanicha 20 Yaadannoo', bodyAm: 'ሀኪምዎን ለሁለተኛ ጊዜ ጎብኝ', bodyOr: 'Murtoo lammaffaa argadhuu', audience: 'All', schedule: '2025-05-10 09:00', type: 'Reminder', status: 'Sent', openRate: '78%' },
    { id: 2, titleAm: 'አዲስ የምግብ ምክር', titleOr: 'Gorsa Nyaataa Haaraa', bodyAm: 'ብረት የበለፀጉ ምግቦችን ያካትቱ', bodyOr: 'Nyaata birrii guutuu dabalaa', audience: '2nd Trimester', schedule: '2025-05-08 08:00', type: 'Tip', status: 'Sent', openRate: '65%' },
    { id: 3, titleAm: 'አስቀድሞ ያቅዱ', titleOr: 'Dursaa Karoorfadhu', bodyAm: 'ለምጥዎ ዝግጁ ሁን', bodyOr: 'Dhalachaaf of qopheessi', audience: '3rd Trimester', schedule: '2025-05-15 10:00', type: 'Alert', status: 'Scheduled', openRate: undefined },
];

const empty: Omit<Notification, 'id' | 'status' | 'openRate'> = { titleAm: '', titleOr: '', bodyAm: '', bodyOr: '', audience: 'All', schedule: '', type: 'Reminder' };

const typeVariant: Record<string, 'pink' | 'blue' | 'yellow'> = { Reminder: 'pink', Tip: 'blue', Alert: 'yellow' };

export default function NotificationsManager() {
    const [notifications, setNotifications] = useState(initial);
    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState<Omit<Notification, 'id' | 'status' | 'openRate'>>(empty);

    function handleSend() {
        setNotifications(prev => [...prev, { ...form, id: Date.now(), status: 'Scheduled' }]);
        setModalOpen(false);
        setForm(empty);
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Pregnancy Tracker & Notifications</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Schedule and send push notifications to users</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={() => { setForm(empty); setModalOpen(true); }}>New Notification</Button>
            </div>

            {/* Stats Row */}
            <div className="grid grid-cols-3 gap-4">
                {[
                    { label: 'Total Sent', value: '128', icon: Send },
                    { label: 'Scheduled', value: '12', icon: Clock },
                    { label: 'Users Reached', value: '1,142', icon: Users },
                ].map(s => (
                    <Card key={s.label} className="flex items-center gap-4">
                        <div className="p-3 bg-[#fdf2f8] rounded-xl"><s.icon className="w-5 h-5 text-[#61183e]" /></div>
                        <div>
                            <p className="text-xs text-gray-500">{s.label}</p>
                            <p className="text-xl font-bold text-gray-900">{s.value}</p>
                        </div>
                    </Card>
                ))}
            </div>

            {/* Notification History */}
            <Card>
                <h3 className="font-semibold text-gray-800 mb-4">Notification History</h3>
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b border-gray-100">
                                {['Title', 'Audience', 'Scheduled', 'Type', 'Status', 'Open Rate'].map(h => (
                                    <th key={h} className="text-left pb-3 text-xs text-gray-500 font-medium pr-4">{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {notifications.map(n => (
                                <tr key={n.id} className="hover:bg-[#fdf2f8]/40 transition-colors">
                                    <td className="py-3 pr-4">
                                        <p className="font-medium text-gray-800">{n.titleAm}</p>
                                        <p className="text-xs text-gray-400">{n.titleOr}</p>
                                    </td>
                                    <td className="py-3 pr-4 text-gray-600 text-xs">
                                        <div className="flex items-center gap-1"><Users className="w-3 h-3" />{n.audience}</div>
                                    </td>
                                    <td className="py-3 pr-4 text-gray-500 text-xs whitespace-nowrap">
                                        <div className="flex items-center gap-1"><Clock className="w-3 h-3" />{n.schedule}</div>
                                    </td>
                                    <td className="py-3 pr-4">
                                        <Badge variant={typeVariant[n.type] || 'gray'}>{n.type}</Badge>
                                    </td>
                                    <td className="py-3 pr-4">
                                        <Badge variant={n.status === 'Sent' ? 'green' : 'yellow'}>{n.status}</Badge>
                                    </td>
                                    <td className="py-3 font-semibold text-gray-700 text-sm">{n.openRate || '—'}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </Card>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="New Push Notification" size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="ርዕስ..." />
                        <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Mata duree..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Message Body (Amharic)" value={form.bodyAm} onChange={e => setForm(f => ({ ...f, bodyAm: e.target.value }))} rows={3} placeholder="ዝርዝር መልዕክት..." />
                        <TextArea label="Message Body (Afan Oromo)" value={form.bodyOr} onChange={e => setForm(f => ({ ...f, bodyOr: e.target.value }))} rows={3} placeholder="Ergaa..." />
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                        <div className="relative">
                            <Select label="Target Audience" value={form.audience} onChange={e => setForm(f => ({ ...f, audience: e.target.value }))} options={['All', '1st Trimester', '2nd Trimester', '3rd Trimester', 'Amharic Users', 'Afan Oromo Users'].map(v => ({ value: v, label: v }))} />
                            <ChevronDown className="absolute right-3 top-8 w-4 h-4 text-gray-400 pointer-events-none" />
                        </div>
                        <Select label="Type" value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))} options={['Reminder', 'Alert', 'Tip'].map(v => ({ value: v, label: v }))} />
                        <Input label="Schedule Date & Time" type="datetime-local" value={form.schedule} onChange={e => setForm(f => ({ ...f, schedule: e.target.value }))} />
                    </div>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button icon={<Send className="w-4 h-4" />} onClick={handleSend}>Schedule Notification</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
