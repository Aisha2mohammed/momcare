import { useState } from 'react';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';

interface FetalEntry {
    id: number;
    week: number;
    sizeComparison: string;
    milestoneAm: string;
    milestoneOr: string;
    tipsAm: string;
    tipsOr: string;
}

const initialEntries: FetalEntry[] = [
    { id: 1, week: 8, sizeComparison: 'Raspberry', milestoneAm: 'ልቡ ይሰማል', milestoneOr: 'Onneen dhagayama', tipsAm: 'ዶክተርህን ጎብኝ', tipsOr: 'Doktora kee daaw\'adhu' },
    { id: 2, week: 16, sizeComparison: 'Avocado', milestoneAm: 'ህፃኑ ይንቀሳቀሳል', milestoneOr: 'Daa\'imni socho\'a', tipsAm: 'ብዙ ውሃ ጠጣ', tipsOr: 'Bishaan hedduu dhugu' },
    { id: 3, week: 24, sizeComparison: 'Corn', milestoneAm: 'ዓይኖቹ ይከፈታሉ', milestoneOr: 'Ijji isaa banama', tipsAm: 'ምቹ ቦታ ተጠቀም', tipsOr: 'Bakka mitooftuu fayyadami' },
    { id: 4, week: 32, sizeComparison: 'Butternut Squash', milestoneAm: 'እንቅልፍ ዓይን ይንቀሳቀሳل', milestoneOr: 'Ijji rakkachuu eegala', tipsAm: 'ወደ ግራ ጎን ተኛ', tipsOr: 'Bitaa ciisi' },
];

const empty: Omit<FetalEntry, 'id'> = { week: 1, sizeComparison: '', milestoneAm: '', milestoneOr: '', tipsAm: '', tipsOr: '' };

export default function FetalDevelopmentManager() {
    const [entries, setEntries] = useState(initialEntries);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<FetalEntry | null>(null);
    const [form, setForm] = useState<Omit<FetalEntry, 'id'>>(empty);

    function openCreate() { setEditing(null); setForm(empty); setModalOpen(true); }
    function openEdit(e: FetalEntry) { setEditing(e); setForm(e); setModalOpen(true); }
    function handleDelete(id: number) { setEntries(prev => prev.filter(e => e.id !== id)); }
    function handleSave() {
        if (editing) { setEntries(prev => prev.map(e => e.id === editing.id ? { ...form, id: editing.id } : e)); }
        else { setEntries(prev => [...prev, { ...form, id: Date.now() }]); }
        setModalOpen(false);
    }

    const sorted = [...entries].sort((a, b) => a.week - b.week);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Fetal Development Tracker</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage week-by-week development content (Weeks 1–42)</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Week Entry</Button>
            </div>

            <div className="grid gap-4">
                {sorted.map(entry => (
                    <Card key={entry.id} className="flex items-start gap-6">
                        <div className="shrink-0 w-20 h-20 rounded-2xl bg-[#fdf2f8] flex flex-col items-center justify-center">
                            <span className="text-2xl font-black text-[#61183e]">{entry.week}</span>
                            <span className="text-xs text-gray-500">wks</span>
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1 flex-wrap">
                                <Badge variant="pink">Size: {entry.sizeComparison}</Badge>
                            </div>
                            <p className="text-sm font-medium text-gray-800">{entry.milestoneAm}</p>
                            <p className="text-sm text-gray-500">{entry.milestoneOr}</p>
                            <p className="text-xs text-gray-400 mt-1">Tip: {entry.tipsAm}</p>
                        </div>
                        <div className="flex gap-2 shrink-0">
                            <button onClick={() => openEdit(entry)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"><Edit2 className="w-4 h-4" /></button>
                            <button onClick={() => handleDelete(entry.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors"><Trash2 className="w-4 h-4" /></button>
                        </div>
                    </Card>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Week Entry' : 'New Week Entry'} size="xl">
                <div className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Week Number (1–42)" type="number" min={1} max={42} value={form.week} onChange={e => setForm(f => ({ ...f, week: parseInt(e.target.value) || 1 }))} />
                        <Input label="Baby Size Comparison (e.g. 'Lemon')" value={form.sizeComparison} onChange={e => setForm(f => ({ ...f, sizeComparison: e.target.value }))} placeholder="e.g. Avocado" />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Developmental Milestone (Amharic)" value={form.milestoneAm} onChange={e => setForm(f => ({ ...f, milestoneAm: e.target.value }))} rows={3} placeholder="ምዕራፍ..." />
                        <TextArea label="Developmental Milestone (Afan Oromo)" value={form.milestoneOr} onChange={e => setForm(f => ({ ...f, milestoneOr: e.target.value }))} rows={3} placeholder="Barruu..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="Tips for Mother (Amharic)" value={form.tipsAm} onChange={e => setForm(f => ({ ...f, tipsAm: e.target.value }))} rows={3} placeholder="ምክሮች..." />
                        <TextArea label="Tips for Mother (Afan Oromo)" value={form.tipsOr} onChange={e => setForm(f => ({ ...f, tipsOr: e.target.value }))} rows={3} placeholder="Yaadannoo..." />
                    </div>
                    <div className="flex justify-end gap-3">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave}>{editing ? 'Save Changes' : 'Create Entry'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
