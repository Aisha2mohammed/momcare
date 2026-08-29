import { useTranslation } from 'react-i18next';
import { Globe, ChevronDown } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

const languages = [
    { code: 'en', label: 'English', flag: '🇬🇧' },
    { code: 'am', label: 'አማርኛ', flag: '🇪🇹' },
    { code: 'om', label: 'Afan Oromo', flag: '🇪🇹' },
];

export function LanguageSwitcher() {
    const { i18n } = useTranslation();
    const [open, setOpen] = useState(false);
    const ref = useRef<HTMLDivElement>(null);

    const current = languages.find(l => l.code === i18n.language) ?? languages[0];

    useEffect(() => {
        function handler(e: MouseEvent) {
            if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
        }
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, []);

    return (
        <div className="relative" ref={ref}>
            <button
                onClick={() => setOpen(!open)}
                className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium text-gray-600 hover:bg-[#fdf2f8] hover:text-[#61183e] transition-colors"
                aria-haspopup="listbox"
                aria-expanded={open}
                title="Change language"
            >
                <Globe className="w-4 h-4" />
                <span className="hidden sm:inline">{current.flag} {current.label}</span>
                <ChevronDown className={`w-3 h-3 transition-transform ${open ? 'rotate-180' : ''}`} />
            </button>

            {open && (
                <div
                    role="listbox"
                    className="absolute right-0 top-full mt-1 w-44 bg-white border border-gray-200 rounded-xl shadow-lg py-1 z-50"
                >
                    {languages.map(lang => (
                        <button
                            key={lang.code}
                            role="option"
                            aria-selected={i18n.language === lang.code}
                            onClick={() => {
                                i18n.changeLanguage(lang.code);
                                setOpen(false);
                            }}
                            className={`w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-left transition-colors ${i18n.language === lang.code
                                    ? 'bg-[#fdf2f8] text-[#61183e] font-semibold'
                                    : 'text-gray-700 hover:bg-gray-50'
                                }`}
                        >
                            <span>{lang.flag}</span>
                            <span>{lang.label}</span>
                            {i18n.language === lang.code && <span className="ml-auto text-[#61183e]">✓</span>}
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
}
