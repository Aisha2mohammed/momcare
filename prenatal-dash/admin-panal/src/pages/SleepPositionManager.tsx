import { useState } from 'react';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select, FileInput } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';

interface SleepTip {
    id: number;
    titleAm: string;
    titleOr: string;
    descOr: string;
    videoUrl?: string;
    week?: string;
    videoFile?: File | null;
}

const initial: SleepTip[] = [
    { id: 1, titleAm: 'ወደ ግራ ጎን ተኛ', titleOr: 'Bitaa Ciisi', trimester: '2nd', week: 'Week 20+', descAm: 'ወደ ግራ መተኛት የደም ዝውውርን ያሻሽላል።', descOr: 'Bitaa ciisun dhiiga gudeelcha.', videoUrl: 'https://vimeo.com/example' },
    { id: 2, titleAm: 'ትራስ ይጠቀሙ', titleOr: 'Carraa Fayyadami', trimester: '3rd', week: 'Week 28+', descAm: 'በሆዳቸው ስር ትራስ ያስቀምጡ', descOr: 'Garaa jalatti carraa kaa\'i.' },
];
const empty: Omit<SleepTip, 'id'> = { titleAm: '', titleOr: '', trimester: '1st', week: '', descAm: '', descOr: '', videoUrl: '', videoFile: null };

export default function SleepPositionManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState(initial);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<SleepTip | null>(null);
    const [form, setForm] = useState<Omit<SleepTip, 'id'>>(empty);

    function openCreate() { setEditing(null); setForm(empty); setModalOpen(true); }
    function openEdit(e: SleepTip) { setEditing(e); setForm(e); setModalOpen(true); }
    function handleDelete(id: number) {
        setEntries(prev => prev.filter(e => e.id !== id));
        showToast('Sleep tip deleted.', 'error');
    }
    function handleSave() {
        if (editing) { setEntries(prev => prev.map(e => e.id === editing.id ? { ...form, id: editing.id } : e)); }
        else { setEntries(prev => [...prev, { ...form, id: Date.now() }]); }
        showToast(editing ? 'Tip updated!' : 'Tip created!', 'success');
        setModalOpen(false);
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Sleep Position Tips</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage sleep position tip cards for mothers</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Tip</Button>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
                {entries.map(entry => (
                    <Card key={entry.id} className="relative">
                        <div className="flex items-start justify-between mb-3">
                            <div>
                                <h4 className="font-semibold text-gray-900">{entry.titleAm}</h4>
                                <p className="text-sm text-gray-500">{entry.titleOr}</p>
                            </div>
                            <div className="flex gap-2">
                                <Badge variant="pink">{entry.trimester} Tri.</Badge>
                                {entry.week && <Badge variant="yellow">{entry.week}</Badge>}
                            </div>
                        </div>
                        <p className="text-sm text-gray-600 mb-4">{entry.descAm}</p>
                        <p className="text-sm text-gray-400 italic mb-4">{entry.descOr}</p>
                        {(entry.videoUrl || entry.videoFile) && (
                            <p className="text-xs text-[#61183e] font-medium mb-4 truncate font-mono">
                                Video: {entry.videoFile ? entry.videoFile.name : entry.videoUrl}
                            </p>
                        )}
                        <div className="flex gap-2">
                            <button onClick={() => openEdit(entry)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"><Edit2 className="w-4 h-4" /></button>
                            <button onClick={() => handleDelete(entry.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors"><Trash2 className="w-4 h-4" /></button>
                        </div>
                    </Card>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Sleep Tip' : 'New Sleep Tip'} size="xl">
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="ርዕስ..." />
                        <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Mata duree..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select label="Trimester" value={form.trimester} onChange={e => setForm(f => ({ ...f, trimester: e.target.value }))} options={[{ value: '1st', label: '1st Trimester' }, { value: '2nd', label: '2nd Trimester' }, { value: '3rd', label: '3rd Trimester' }, { value: 'All', label: 'All Trimesters' }]} />
                        <Input label="Specific Week (Optional)" value={form.week || ''} onChange={e => setForm(f => ({ ...f, week: e.target.value }))} placeholder="e.g. Week 20+" />
                    </div>
                    <div className="space-y-4 border-y border-gray-100 py-4 my-2">
                        <p className="text-sm font-medium text-gray-700">Media Content</p>
                        <div className="grid grid-cols-2 gap-4">
                            <Input label="Video URL" value={form.videoUrl || ''} onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value }))} placeholder="https://youtube.com/..." />
                            <FileInput label="Or Upload Local File" onChange={e => setForm(f => ({ ...f, videoFile: e.target.files?.[0] || null }))} />
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Description (Amharic)" value={form.descAm} onChange={e => setForm(f => ({ ...f, descAm: e.target.value }))} rows={4} placeholder="ዝርዝር..." />
                        <TextArea label="Description (Afan Oromo)" value={form.descOr} onChange={e => setForm(f => ({ ...f, descOr: e.target.value }))} rows={4} placeholder="Ibsa..." />
                    </div>
                    <div className="flex justify-end gap-3">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave}>{editing ? 'Save Changes' : 'Create Tip'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
