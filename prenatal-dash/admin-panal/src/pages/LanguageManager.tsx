import { useState } from 'react';

interface LanguageSection {
    section: string;
    keys: { key: string; am: string; or: string }[];
}

const initialSections: LanguageSection[] = [
    {
        section: 'Navigation',
        keys: [
            { key: 'nav.dashboard', am: 'ዳሽቦርድ', or: 'Daashboordii' },
            { key: 'nav.nutrition', am: 'አመጋገብ', or: 'Nyaata' },
            { key: 'nav.exercise', am: 'ልምምድ', or: 'Shaakala' },
            { key: 'nav.emergency', am: 'ድንገተኛ', or: 'Hatattama' },
        ]
    },
    {
        section: 'Home Screen',
        keys: [
            { key: 'home.welcome', am: 'እንኳን ደህና መጡ', or: 'Baga Nagana Dhuftan' },
            { key: 'home.due_date', am: 'የሚጠበቀው ቀን', or: 'Guyyaa Eegamu' },
            { key: 'home.week', am: 'ሳምንት', or: 'Torbanii' },
        ]
    },
    {
        section: 'Fetal Development',
        keys: [
            { key: 'fetal.size', am: 'ህጻን መጠን', or: 'Hamma Daa\'ima' },
            { key: 'fetal.milestone', am: 'ምዕራፍ', or: 'Milkii' },
            { key: 'fetal.tips', am: 'ምክሮች', or: 'Yaadannoo' },
        ]
    },
    {
        section: 'Buttons & Actions',
        keys: [
            { key: 'btn.save', am: 'አስቀምጥ', or: 'Kuusi' },
            { key: 'btn.cancel', am: 'ሰርዝ', or: 'Haqi' },
            { key: 'btn.learn_more', am: 'ተጨማሪ ይወቁ', or: 'Dabalata Baraa' },
        ]
    }
];

function getCompleteness(section: LanguageSection) {
    const total = section.keys.length;
    const filledAm = section.keys.filter(k => k.am.trim() !== '').length;
    const filledOr = section.keys.filter(k => k.or.trim() !== '').length;
    return { am: Math.round((filledAm / total) * 100), or: Math.round((filledOr / total) * 100) };
}

export default function LanguageManager() {
    const [sections, setSections] = useState(initialSections);

    function updateKey(si: number, ki: number, lang: 'am' | 'or', value: string) {
        setSections(prev => {
            const updated = prev.map((s, i) => i !== si ? s : {
                ...s, keys: s.keys.map((k, j) => j !== ki ? k : { ...k, [lang]: value })
            });
            return updated;
        });
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-2xl font-bold text-[#61183e]">Language & Localization</h2>
                <p className="text-gray-500 text-sm mt-0.5">Manage all UI strings in Amharic and Afan Oromo side-by-side</p>
            </div>

            {/* Legend */}
            <div className="flex gap-6 text-sm text-gray-600">
                <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-[#61183e] inline-block" /> Amharic (አማርኛ)</div>
                <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-green-500 inline-block" /> Afan Oromo (Afaan Oromoo)</div>
            </div>

            {sections.map((section, si) => {
                const comp = getCompleteness(section);
                return (
                    <div key={section.section} className="bg-white rounded-2xl border border-rose-50 shadow-sm overflow-hidden">
                        {/* Section Header */}
                        <div className="flex items-center justify-between px-6 py-4 bg-[#fdf2f8]/60 border-b border-rose-100">
                            <h3 className="font-semibold text-[#61183e]">{section.section}</h3>
                            <div className="flex gap-6 text-xs">
                                <div className="flex items-center gap-2">
                                    <span className="text-gray-500">Amharic</span>
                                    <div className="w-24 h-2 rounded-full bg-gray-200 overflow-hidden">
                                        <div style={{ width: `${comp.am}%` }} className="h-full bg-[#61183e] rounded-full transition-all" />
                                    </div>
                                    <span className="font-bold text-[#61183e]">{comp.am}%</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="text-gray-500">Afan Oromo</span>
                                    <div className="w-24 h-2 rounded-full bg-gray-200 overflow-hidden">
                                        <div style={{ width: `${comp.or}%` }} className="h-full bg-green-500 rounded-full transition-all" />
                                    </div>
                                    <span className="font-bold text-green-600">{comp.or}%</span>
                                </div>
                            </div>
                        </div>

                        {/* Keys */}
                        <div className="divide-y divide-gray-50">
                            {/* Column Headers */}
                            <div className="grid grid-cols-[200px_1fr_1fr] gap-4 px-6 py-2 bg-gray-50 text-xs font-medium text-gray-500">
                                <span>Key</span>
                                <span>🇪🇹 Amharic</span>
                                <span>🟢 Afan Oromo</span>
                            </div>
                            {section.keys.map((kv, ki) => (
                                <div key={kv.key} className="grid grid-cols-[200px_1fr_1fr] gap-4 px-6 py-3 items-center hover:bg-[#fdf2f8]/30 transition-colors">
                                    <code className="text-xs text-gray-400 bg-gray-100 px-2 py-1 rounded font-mono">{kv.key}</code>
                                    <input
                                        value={kv.am}
                                        onChange={e => updateKey(si, ki, 'am', e.target.value)}
                                        className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white transition"
                                        placeholder="Amharic text..."
                                    />
                                    <input
                                        value={kv.or}
                                        onChange={e => updateKey(si, ki, 'or', e.target.value)}
                                        className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-green-400 focus:ring-2 focus:ring-green-400/20 bg-white transition"
                                        placeholder="Afan Oromo text..."
                                    />
                                </div>
                            ))}
                        </div>

                        <div className="px-6 py-3 border-t border-gray-100 flex justify-end">
                            <button className="text-sm font-medium text-[#61183e] hover:text-[#7a1f4f] transition-colors">
                                + Add Key to {section.section}
                            </button>
                        </div>
                    </div>
                );
            })}
        </div>
    );
}
