import { useState } from 'react';
import { Plus, Edit2, Trash2, AlertTriangle } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input, TextArea } from '../components/ui/Input';
import { Modal } from '../components/ui/Modal';

interface HealthTip {
    id: number;
    titleAm: string;
    titleOr: string;
    warningSigns: string;
    firstAidAm: string;
    firstAidOr: string;
}



const initialTips: HealthTip[] = [
    { id: 1, titleAm: 'ቅድመ ምጥ ምልክቶች', titleOr: 'Mallattoowwan Dhalchaa', warningSigns: 'Sudden bleeding, severe headache, blurred vision', firstAidAm: 'ወዲያው ሀኪም ቤት ሂጂ', firstAidOr: 'Gabatee dhaabbadhuu hospitaala deemi' },
];


const emptyT: Omit<HealthTip, 'id'> = { titleAm: '', titleOr: '', warningSigns: '', firstAidAm: '', firstAidOr: '' };

export default function EmergencyContactsManager() {

    const [tips, setTips] = useState(initialTips);
  
    const [tipModal, setTipModal] = useState(false);
 
    const [editingT, setEditingT] = useState<HealthTip | null>(null);
 
    const [formT, setFormT] = useState<Omit<HealthTip, 'id'>>(emptyT);

    return (
        <div className="space-y-8">
            <div>
                <h2 className="text-2xl font-bold text-[#61183e]">Emergency Contacts & Health Tips</h2>
                <p className="text-gray-500 text-sm mt-0.5">Manage hospital contacts and warning sign tips</p>
            </div>

      
        

            {/* Health Tips Section */}
            <div className="space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <h3 className="text-base sm:text-lg font-bold text-gray-800">Health Tip Cards</h3>
                    <Button size="sm" icon={<Plus className="w-4 h-4" />} onClick={() => { setEditingT(null); setFormT(emptyT); setTipModal(true); }} className="w-fit">Add Health Tip</Button>
                </div>
                <div className="grid gap-4">
                    {tips.map(tip => (
                        <Card key={tip.id} className="border-l-4 border-l-amber-400">
                            <div className="flex items-start justify-between mb-2">
                                <div className="flex items-center gap-2">
                                    <AlertTriangle className="w-5 h-5 text-amber-500" />
                                    <h4 className="font-semibold text-gray-900">{tip.titleAm}</h4>
                                    <span className="text-gray-400 text-sm">/ {tip.titleOr}</span>
                                </div>
                                <div className="flex gap-1 shrink-0">
                                    <button onClick={() => { setEditingT(tip); setFormT(tip); setTipModal(true); }} className="p-1.5 rounded-lg hover:bg-blue-50 text-blue-600"><Edit2 className="w-3.5 h-3.5" /></button>
                                    <button onClick={() => setTips(prev => prev.filter(t => t.id !== tip.id))} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500"><Trash2 className="w-3.5 h-3.5" /></button>
                                </div>
                            </div>
                            <div className="bg-amber-50 rounded-lg p-3 mb-3">
                                <p className="text-xs font-semibold text-amber-700 mb-1">⚠ Warning Signs:</p>
                                <p className="text-sm text-amber-800">{tip.warningSigns}</p>
                            </div>
                            <p className="text-sm text-gray-600">First Aid (AM): {tip.firstAidAm}</p>
                        </Card>
                    ))}
                </div>
            </div>

         

            {/* Health Tip Modal */}
            <Modal isOpen={tipModal} onClose={() => setTipModal(false)} title={editingT ? 'Edit Health Tip' : 'Add Health Tip'} size="xl">
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <Input label="Title (Amharic)" value={formT.titleAm} onChange={e => setFormT(f => ({ ...f, titleAm: e.target.value }))} placeholder="ርዕስ..." />
                        <Input label="Title (Afan Oromo)" value={formT.titleOr} onChange={e => setFormT(f => ({ ...f, titleOr: e.target.value }))} placeholder="Mata duree..." />
                    </div>
                    <TextArea label="Warning Signs (English / Bilingual)" value={formT.warningSigns} onChange={e => setFormT(f => ({ ...f, warningSigns: e.target.value }))} rows={3} placeholder="List warning signs..." />
                    <div className="grid grid-cols-2 gap-4">
                        <TextArea label="First Aid Steps (Amharic)" value={formT.firstAidAm} onChange={e => setFormT(f => ({ ...f, firstAidAm: e.target.value }))} rows={3} placeholder="ምጥ ደጋፊ..." />
                        <TextArea label="First Aid Steps (Afan Oromo)" value={formT.firstAidOr} onChange={e => setFormT(f => ({ ...f, firstAidOr: e.target.value }))} rows={3} placeholder="Gargaarsa..." />
                    </div>
                    <div className="flex justify-end gap-3">
                        <Button variant="secondary" onClick={() => setTipModal(false)}>Cancel</Button>
                        <Button onClick={() => {
                            if (editingT) setTips(prev => prev.map(t => t.id === editingT.id ? { ...formT, id: editingT.id } : t));
                            else setTips(prev => [...prev, { ...formT, id: Date.now() }]);
                            setTipModal(false);
                        }}>{editingT ? 'Save Changes' : 'Add Health Tip'}</Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
