import { useState } from 'react';
import { Plus, Edit2, Trash2, Eye, EyeOff } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';

interface ExerciseEntry {
    id: number;
    nameAm: string;
    nameOr: string;
    trimesters: string[];
    videoUrl: string;
    duration: string;
    safetyAm: string;
    safetyOr: string;
    published: boolean;
}

const initialEntries: ExerciseEntry[] = [
    { id: 1, nameAm: 'ዕምቢ ወይ ዕርቅ እርምጃ', nameOr: 'Deemsa Laafaa', trimesters: ['1st', '2nd'], videoUrl: '', duration: '15 min', safetyAm: 'ቀስ ብሎ ይጀምሩ', safetyOr: 'Fooya fooya jalqabi', published: true },
    { id: 2, nameAm: 'ዮጋ', nameOr: 'Yoga', trimesters: ['1st', '2nd', '3rd'], videoUrl: '', duration: '20 min', safetyAm: 'ሲቆሙ ይጠንቀቁ', safetyOr: 'Yeroo ka\'an of eeggadhu', published: true },
    { id: 3, nameAm: 'ዋና', nameOr: 'Daakuu', trimesters: ['2nd', '3rd'], videoUrl: '', duration: '30 min', safetyAm: 'ቅዝቃዜ ከሌለ ብቻ', safetyOr: 'Qorra yoo hin jiraatin qofa', published: false },
];

const empty: Omit<ExerciseEntry, 'id'> = { nameAm: '', nameOr: '', trimesters: [], videoUrl: '', duration: '', safetyAm: '', safetyOr: '', published: false };
const allTrimesters = ['1st', '2nd', '3rd'];

export default function ExerciseManager() {
    const [entries, setEntries] = useState(initialEntries);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<ExerciseEntry | null>(null);
    const [form, setForm] = useState<Omit<ExerciseEntry, 'id'>>(empty);

    function toggleTrimester(t: string) {
        setForm(f => ({ ...f, trimesters: f.trimesters.includes(t) ? f.trimesters.filter(x => x !== t) : [...f.trimesters, t] }));
    }
    function openCreate() { setEditing(null); setForm(empty); setModalOpen(true); }
    function openEdit(e: ExerciseEntry) { setEditing(e); setForm(e); setModalOpen(true); }
    function handleDelete(id: number) { setEntries(prev => prev.filter(e => e.id !== id)); }
    function togglePublish(id: number) { setEntries(prev => prev.map(e => e.id === id ? { ...e, published: !e.published } : e)); }
    function handleSave() {
        if (editing) { setEntries(prev => prev.map(e => e.id === editing.id ? { ...form, id: editing.id } : e)); }
        else { setEntries(prev => [...prev, { ...form, id: Date.now() }]); }
        setModalOpen(false);
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Exercise Recommendations</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage recommended exercises for expectant mothers</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Exercise</Button>
            </div>

            <div className="grid gap-4">
                {entries.map(entry => (
                    <Card key={entry.id} className="flex items-start justify-between gap-4">
                        <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2 flex-wrap">
                                <h4 className="font-semibold text-gray-900">{entry.nameAm}</h4>
                                <span className="text-gray-400 text-sm">/ {entry.nameOr}</span>
                                <Badge variant={entry.published ? 'green' : 'gray'}>{entry.published ? 'Published' : 'Draft'}</Badge>
                                {entry.trimesters.map(t => <Badge key={t} variant="pink">{t} Tri</Badge>)}
                                <Badge variant="blue">{entry.duration}</Badge>
                            </div>
                            <p className="text-sm text-gray-500">⚠ {entry.safetyAm}</p>
                        </div>
                        <div className="flex gap-2 shrink-0">
                            <button onClick={() => togglePublish(entry.id)} className="p-2 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors">{entry.published ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}</button>
                            <button onClick={() => openEdit(entry)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"><Edit2 className="w-4 h-4" /></button>
                            <button onClick={() => handleDelete(entry.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors"><Trash2 className="w-4 h-4" /></button>
                        </div>
                    </Card>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Exercise' : 'New Exercise'} size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Name (Amharic)" value={form.nameAm} onChange={e => setForm(f => ({ ...f, nameAm: e.target.value }))} placeholder="ስም..." />
                        <Input label="Name (Afan Oromo)" value={form.nameOr} onChange={e => setForm(f => ({ ...f, nameOr: e.target.value }))} placeholder="Maqaa..." />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-700 mb-2">Trimester Suitability</p>
                        <div className="flex gap-3">
                            {allTrimesters.map(t => (
                                <button
                                    key={t}
                                    onClick={() => toggleTrimester(t)}
                                    className={`px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${form.trimesters.includes(t) ? 'bg-[#61183e] text-white border-[#61183e]' : 'border-gray-200 text-gray-600 hover:border-[#61183e]'}`}
                                >
                                    {t} Trimester
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Duration (e.g. '20 min')" value={form.duration} onChange={e => setForm(f => ({ ...f, duration: e.target.value }))} placeholder="20 min" />
                        <Input label="Video URL (optional)" value={form.videoUrl} onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value }))} placeholder="https://youtube.com/..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Safety Notes (Amharic)" value={form.safetyAm} onChange={e => setForm(f => ({ ...f, safetyAm: e.target.value }))} rows={3} placeholder="ጥንቃቄ..." />
                        <TextArea label="Safety Notes (Afan Oromo)" value={form.safetyOr} onChange={e => setForm(f => ({ ...f, safetyOr: e.target.value }))} rows={3} placeholder="Of eeggannoo..." />
                    </div>
                    <label className="flex items-center gap-3 cursor-pointer">
                        <div onClick={() => setForm(f => ({ ...f, published: !f.published }))} className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${form.published ? 'bg-[#61183e]' : 'bg-gray-300'}`}>
                            <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.published ? 'left-6' : 'left-1'}`} />
                        </div>
                        <span className="text-sm font-medium text-gray-700">{form.published ? 'Published' : 'Draft'}</span>
                    </label>
                    <div className="flex justify-end gap-3">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave}>{editing ? 'Save Changes' : 'Create'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
