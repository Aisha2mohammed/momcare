import { useState } from 'react';
import { Plus, Edit2, Trash2, Eye, EyeOff } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea, Select, FileInput } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';

interface NutritionEntry {
    id: number;
    titleAm: string;
    titleOr: string;
    trimester: string;
    foodType: string;
    bodyOr: string;
    videoUrl?: string; // Optional video or video ID
    week?: string;     // Specific week mapped
    videoFile?: File | null;
}

const initialEntries: NutritionEntry[] = [
    { id: 1, titleAm: 'የብረት የበለፀጉ ምግቦች', titleOr: 'Nyaata Birrii Qabate', trimester: '1st', week: 'Week 4-8', foodType: 'Legumes', published: true, bodyAm: 'ምስር፣ አተር እና ባቄላ ጥሩ የብረት ምንጮች ናቸው።', bodyOr: 'Miisiraa, atrii fi baaqela madda birrii gaarii dha.', videoUrl: 'https://youtube.com/watch?v=mock' },
    { id: 2, titleAm: 'ካልሲየም ምግቦች', titleOr: 'Nyaata Kaalsiiyami', trimester: '2nd', week: 'Week 14', foodType: 'Dairy', published: true, bodyAm: 'ወተት እና አይብ ጥሩ የካልሲዮም ምንጮች ናቸው።', bodyOr: 'Aannan fi cheezing madda kaalsiiyami gaarii dha.', videoUrl: '' },
    { id: 3, titleAm: 'ፎሊክ አሲድ ምንጮች', titleOr: 'Madda Asidii Foolikii', trimester: '1st', week: 'Week 1-4', foodType: 'Vegetables', published: false, bodyAm: 'አትክልቶች ፎሊክ አሲድ ይሰጣሉ።', bodyOr: 'Kuduraaleen asidii foolikii ni kennu.' },
];

const empty: Omit<NutritionEntry, 'id'> = { titleAm: '', titleOr: '', trimester: '1st', week: '', foodType: '', published: false, bodyAm: '', bodyOr: '', videoUrl: '', videoFile: null };

export default function NutritionManager() {
    const { showToast } = useToast();
    const [entries, setEntries] = useState(initialEntries);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<NutritionEntry | null>(null);
    const [form, setForm] = useState<Omit<NutritionEntry, 'id'>>(empty);

    function openCreate() { setEditing(null); setForm(empty); setModalOpen(true); }
    function openEdit(e: NutritionEntry) { setEditing(e); setForm({ ...e }); setModalOpen(true); }
    function handleDelete(id: number) {
        setEntries(prev => prev.filter(e => e.id !== id));
        showToast('Nutrition entry deleted.', 'error');
    }
    function togglePublish(id: number) {
        setEntries(prev => prev.map(e => e.id === id ? { ...e, published: !e.published } : e));
        showToast('Visibility toggled.', 'success');
    }

    function handleSave() {
        if (editing) {
            setEntries(prev => prev.map(e => e.id === editing.id ? { ...editing, ...form } : e));
        } else {
            setEntries(prev => [...prev, { ...form, id: Date.now() }]);
        }
        showToast(editing ? 'Nutrition entry updated!' : 'New entry created!', 'success');
        setModalOpen(false);
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Nutrition Guide</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage nutritional articles and meal plans</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Entry</Button>
            </div>

            <div className="grid gap-4">
                {entries.map(entry => (
                    <Card key={entry.id} className="flex items-start justify-between gap-4">
                        <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2 flex-wrap">
                                <h4 className="font-semibold text-gray-900">{entry.titleAm}</h4>
                                <span className="text-gray-400 text-sm">/ {entry.titleOr}</span>
                                <Badge variant={entry.published ? 'green' : 'gray'}>{entry.published ? 'Published' : 'Draft'}</Badge>
                                <Badge variant="pink">{entry.trimester} Trimester</Badge>
                                {entry.week && <Badge variant="yellow">{entry.week}</Badge>}
                                <Badge variant="blue">{entry.foodType}</Badge>
                            </div>
                            <p className="text-sm text-gray-500 line-clamp-2">{entry.bodyAm}</p>
                            {(entry.videoUrl || entry.videoFile) && (
                                <p className="text-xs text-[#61183e] font-medium mt-1 font-mono truncate">
                                    Video: {entry.videoFile ? entry.videoFile.name : entry.videoUrl}
                                </p>
                            )}
                        </div>
                        <div className="flex gap-2 shrink-0">
                            <button onClick={() => togglePublish(entry.id)} className="p-2 rounded-lg hover:bg-[#fdf2f8] text-[#61183e] transition-colors" title={entry.published ? 'Unpublish' : 'Publish'}>
                                {entry.published ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                            </button>
                            <button onClick={() => openEdit(entry)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors" title="Edit">
                                <Edit2 className="w-4 h-4" />
                            </button>
                            <button onClick={() => handleDelete(entry.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors" title="Delete">
                                <Trash2 className="w-4 h-4" />
                            </button>
                        </div>
                    </Card>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Nutrition Entry' : 'New Nutrition Entry'} size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1">
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">🇪🇹 Amharic</p>
                            <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="አርዕስት..." />
                        </div>
                        <div className="space-y-1">
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">🟢 Afan Oromo</p>
                            <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Mata duree..." />
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select label="Trimester" value={form.trimester} onChange={e => setForm(f => ({ ...f, trimester: e.target.value }))} options={[{ value: '1st', label: '1st Trimester' }, { value: '2nd', label: '2nd Trimester' }, { value: '3rd', label: '3rd Trimester' }]} />
                        <Input label="Specific Week (Optional)" value={form.week || ''} onChange={e => setForm(f => ({ ...f, week: e.target.value }))} placeholder="e.g. Week 12" />
                    </div>
                    <div className="space-y-4 border-y border-gray-100 py-4 my-2">
                        <p className="text-sm font-medium text-gray-700">Media Content</p>
                        <div className="grid grid-cols-2 gap-4">
                            <Input label="Video URL" value={form.videoUrl || ''} onChange={e => setForm(f => ({ ...f, videoUrl: e.target.value }))} placeholder="https://youtube.com/..." />
                            <FileInput label="Or Upload Local File" onChange={e => setForm(f => ({ ...f, videoFile: e.target.files?.[0] || null }))} />
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Body Content (Amharic)" value={form.bodyAm} onChange={e => setForm(f => ({ ...f, bodyAm: e.target.value }))} rows={4} placeholder="ዝርዝር መረጃ..." />
                        <TextArea label="Body Content (Afan Oromo)" value={form.bodyOr} onChange={e => setForm(f => ({ ...f, bodyOr: e.target.value }))} rows={4} placeholder="Odeeffannoo..." />
                    </div>
                    <div className="flex items-center gap-3 p-4 bg-[#fdf2f8] rounded-xl">
                        <label className="flex items-center gap-3 cursor-pointer">
                            <div
                                onClick={() => setForm(f => ({ ...f, published: !f.published }))}
                                className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${form.published ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.published ? 'left-6' : 'left-1'}`} />
                            </div>
                            <span className="font-medium text-gray-800 text-sm">
                                {form.published ? 'Published — visible to users' : 'Draft — not visible to users'}
                            </span>
                        </label>
                    </div>
                    <div className="flex justify-end gap-3 pt-2">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave}>{editing ? 'Save Changes' : 'Create Entry'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
