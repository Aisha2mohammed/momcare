import { useState } from 'react';
import { Plus, Edit2, Trash2, Music, Play } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Input, Select, FileInput } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../context/ToastContext';

interface Track {
    id: number;
    titleAm: string;
    titleOr: string;
    category: string;
    duration: string;
    trimester?: string;
    week?: string;
    active: boolean;
    videoFile?: File | null;
}

const initial: Track[] = [
    { id: 1, titleAm: 'እናቶች ዝምታ', titleOr: 'Nagaa Haadhaa', category: 'Meditation', duration: '10:00', url: 'https://youtube.com/watch?v=example', trimester: 'All', active: true },
    { id: 2, titleAm: 'የፅንስ ዘፈን', titleOr: 'Faaruu Daa\'ima', category: 'Lullaby', duration: '5:30', url: 'https://youtube.com/watch?v=mock2', trimester: '3rd', week: 'Week 28+', active: true },
    { id: 3, titleAm: 'ሰላም', titleOr: 'Tasgabbii', category: 'Relaxation', duration: '15:00', url: '', trimester: '1st', active: false },
];
const empty: Omit<Track, 'id'> = { titleAm: '', titleOr: '', category: 'Relaxation', trimester: 'All', week: '', duration: '', url: '', active: true, videoFile: null };
const categoryColors: Record<string, 'pink' | 'purple' | 'blue'> = { Relaxation: 'pink', Meditation: 'purple', Lullaby: 'blue' };

export default function MusicLibraryManager() {
    const { showToast } = useToast();
    const [tracks, setTracks] = useState(initial);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<Track | null>(null);
    const [form, setForm] = useState<Omit<Track, 'id'>>(empty);

    function openCreate() { setEditing(null); setForm(empty); setModalOpen(true); }
    function openEdit(t: Track) { setEditing(t); setForm(t); setModalOpen(true); }
    function handleDelete(id: number) {
        setTracks(prev => prev.filter(t => t.id !== id));
        showToast('Track deleted.', 'error');
    }
    function toggleActive(id: number) {
        setTracks(prev => prev.map(t => t.id === id ? { ...t, active: !t.active } : t));
        showToast('Track status updated.', 'success');
    }
    function handleSave() {
        if (editing) { setTracks(prev => prev.map(t => t.id === editing.id ? { ...form, id: editing.id } : t)); }
        else { setTracks(prev => [...prev, { ...form, id: Date.now() }]); }
        showToast(editing ? 'Track updated!' : 'Track added!', 'success');
        setModalOpen(false);
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-[#61183e]">Music & Relaxation Library</h2>
                    <p className="text-gray-500 text-sm mt-0.5">Manage audio tracks and relaxation content</p>
                </div>
                <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Track</Button>
            </div>

            <div className="grid gap-4">
                {tracks.map(track => (
                    <Card key={track.id} className="flex items-center gap-5">
                        <div className="w-12 h-12 rounded-xl bg-[#fdf2f8] flex items-center justify-center shrink-0">
                            <Music className="w-6 h-6 text-[#61183e]" />
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2 flex-wrap mb-1">
                                <h4 className="font-semibold text-gray-900">{track.titleAm}</h4>
                                <span className="text-gray-400 text-sm">/ {track.titleOr}</span>
                                <Badge variant={categoryColors[track.category] || 'gray'}>{track.category}</Badge>
                                {track.trimester && track.trimester !== 'All' && <Badge variant="pink">{track.trimester} Tri</Badge>}
                                {track.week && <Badge variant="yellow">{track.week}</Badge>}
                                <Badge variant={track.active ? 'green' : 'gray'}>{track.active ? 'Active' : 'Inactive'}</Badge>
                            </div>
                            <p className="text-sm text-gray-500">Duration: {track.duration || '—'}</p>
                            {(track.url || track.videoFile) && (
                                <p className="text-sm text-[#61183e] flex items-center gap-1 mt-1 truncate">
                                    <Play className="w-3 h-3" /> {track.videoFile ? track.videoFile.name : 'Stream attached'}
                                </p>
                            )}
                        </div>
                        <div className="flex gap-2 shrink-0">
                            <button onClick={() => toggleActive(track.id)} className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${track.active ? 'bg-amber-50 text-amber-700' : 'bg-green-50 text-green-700'}`}>
                                {track.active ? 'Deactivate' : 'Activate'}
                            </button>
                            <button onClick={() => openEdit(track)} className="p-2 rounded-lg hover:bg-blue-50 text-blue-600 transition-colors"><Edit2 className="w-4 h-4" /></button>
                            <button onClick={() => handleDelete(track.id)} className="p-2 rounded-lg hover:bg-red-50 text-red-500 transition-colors"><Trash2 className="w-4 h-4" /></button>
                        </div>
                    </Card>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Track' : 'New Track'} size="lg">
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={form.titleAm} onChange={e => setForm(f => ({ ...f, titleAm: e.target.value }))} placeholder="ዘፈን ስም..." />
                        <Input label="Title (Afan Oromo)" value={form.titleOr} onChange={e => setForm(f => ({ ...f, titleOr: e.target.value }))} placeholder="Maqaa..." />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select label="Category" value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))} options={['Relaxation', 'Meditation', 'Lullaby'].map(c => ({ value: c, label: c }))} />
                        <Input label="Duration (e.g. '10:00')" value={form.duration} onChange={e => setForm(f => ({ ...f, duration: e.target.value }))} placeholder="mm:ss" />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <Select label="Trimester (Optional)" value={form.trimester || 'All'} onChange={e => setForm(f => ({ ...f, trimester: e.target.value }))} options={[{ value: 'All', label: 'All Trimesters' }, { value: '1st', label: '1st Trimester' }, { value: '2nd', label: '2nd Trimester' }, { value: '3rd', label: '3rd Trimester' }]} />
                        <Input label="Specific Week (Optional)" value={form.week || ''} onChange={e => setForm(f => ({ ...f, week: e.target.value }))} placeholder="e.g. Week 20+" />
                    </div>
                    <div className="space-y-4 border-y border-gray-100 py-4 my-2">
                        <p className="text-sm font-medium text-gray-700">Media Content</p>
                        <div className="grid grid-cols-2 gap-4">
                            <Input label="Stream URL" value={form.url} onChange={e => setForm(f => ({ ...f, url: e.target.value }))} placeholder="https://..." />
                            <FileInput label="Or Upload Audio/Video" onChange={e => setForm(f => ({ ...f, videoFile: e.target.files?.[0] || null }))} />
                        </div>
                    </div>
                    <label className="flex items-center gap-3 cursor-pointer">
                        <div onClick={() => setForm(f => ({ ...f, active: !f.active }))} className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${form.active ? 'bg-[#61183e]' : 'bg-gray-300'}`}>
                            <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${form.active ? 'left-6' : 'left-1'}`} />
                        </div>
                        <span className="text-sm font-medium text-gray-700">{form.active ? 'Active' : 'Inactive'}</span>
                    </label>
                    <div className="flex justify-end gap-3">
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
                        <Button onClick={handleSave}>{editing ? 'Save Changes' : 'Add Track'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
