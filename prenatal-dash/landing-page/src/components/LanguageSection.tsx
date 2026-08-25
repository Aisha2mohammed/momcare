import { useState } from 'react';
import './LanguageSection.css';

interface LanguageSectionProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        badge: 'Language Inclusivity',
        title: 'Speak Your Language,\nUnderstand Your Health',
        sub: 'Health information is most powerful when it reaches you in your mother tongue. Smart Pregnancy Companion is built for Ethiopia\'s diversity.',
        amharic: {
            label: 'አማርኛ',
            title: 'Amharic',
            desc: 'The official language of Ethiopia — full app experience in Amharic script.',
            sample: 'ሳምንት 24 — ህፃንዎ አሁን 30 ሴ.ሜ ርዝማኔ አለው። 🌱',
            sampleLabel: 'App preview in Amharic',
        },
        oromo: {
            label: 'Afan Oromo',
            title: 'Afan Oromo',
            desc: 'Full support in Afan Oromo — the most widely spoken language in Ethiopia.',
            sample: 'Torbee 24 — Daa\'imni keessan ammaa gabaaba 30 cm qaba. 🌱',
            sampleLabel: 'App preview in Afan Oromo',
        },
        more: 'More languages coming soon',
    },
    am: {
        badge: 'የቋንቋ ልዩነት',
        title: 'ቋንቋዎን ይናገሩ፣\nጤናዎን ይረዱ',
        sub: 'የጤና መረጃ በእናቶ ቋንቋ ሲደርስዎ የበለጠ ኃይለኛ ነው። ብልህ እርግዝና ጓደኛ ለኢትዮጵያ ብዝሃነት ተዘጋጅቷል።',
        amharic: {
            label: 'አማርኛ',
            title: 'አማርኛ',
            desc: 'የኢትዮጵያ ኦፊሴላዊ ቋንቋ — የሙሉ አፕ ተሞክሮ በአማርኛ ፊደል።',
            sample: 'ሳምንት 24 — ህፃንዎ አሁን 30 ሴ.ሜ ርዝማኔ አለው። 🌱',
            sampleLabel: 'አፕ በአማርኛ',
        },
        oromo: {
            label: 'Afan Oromo',
            title: 'አፋን ኦሮሞ',
            desc: 'የሙሉ ድጋፍ በአፋን ኦሮሞ — በኢትዮጵያ ውስጥ በጣም ተደጋጋሚ ቋንቋ።',
            sample: 'Torbee 24 — Daa\'imni keessan ammaa gabaaba 30 cm qaba. 🌱',
            sampleLabel: 'አፕ በ Afan Oromo',
        },
        more: 'ሌሎች ቋንቋዎች በቅርቡ ይጨመራሉ',
    },
};

export default function LanguageSection({ lang }: LanguageSectionProps) {
    const t = content[lang];
    const [active, setActive] = useState<'am' | 'or'>('am');

    return (
        <section className="lang-sec" id="language">
            <div className="lang-sec__container">
                <div className="lang-sec__header">
                    <div className="section-badge">{t.badge}</div>
                    <h2 className="section-title" style={{ whiteSpace: 'pre-line' }}>{t.title}</h2>
                    <p className="section-sub">{t.sub}</p>
                </div>

                <div className="lang-sec__body">
                    {/* Toggle Tabs */}
                    <div className="lang-sec__tabs" id="lang-tabs">
                        <button
                            className={`lang-sec__tab${active === 'am' ? ' lang-sec__tab--active' : ''}`}
                            onClick={() => setActive('am')}
                            id="tab-amharic"
                        >
                            <span className="lang-sec__flag">🇪🇹</span>
                            {t.amharic.title}
                        </button>
                        <button
                            className={`lang-sec__tab${active === 'or' ? ' lang-sec__tab--active' : ''}`}
                            onClick={() => setActive('or')}
                            id="tab-oromo"
                        >
                            <span className="lang-sec__flag">🌿</span>
                            {t.oromo.title}
                        </button>
                    </div>

                    {/* Content Panel */}
                    <div className="lang-sec__panel" id="lang-panel">
                        <div className="lang-sec__panel-info">
                            <div className="lang-sec__panel-label">{active === 'am' ? t.amharic.label : t.oromo.label}</div>
                            <p className="lang-sec__panel-desc">{active === 'am' ? t.amharic.desc : t.oromo.desc}</p>

                            {/* Feature chips */}
                            <div className="lang-sec__chips">
                                {['✅ Full UI', '✅ Voice Guidance', '✅ Notifications', '✅ Health Tips'].map(chip => (
                                    <span key={chip} className="lang-sec__chip">{chip}</span>
                                ))}
                            </div>
                        </div>

                        {/* Sample preview */}
                        <div className="lang-sec__preview">
                            <div className="lang-sec__preview-label">
                                {active === 'am' ? t.amharic.sampleLabel : t.oromo.sampleLabel}
                            </div>
                            <div className="lang-sec__preview-card">
                                <div className="lang-sec__preview-icon">
                                    {active === 'am' ? '🇪🇹' : '🌿'}
                                </div>
                                <p className="lang-sec__preview-text">
                                    {active === 'am' ? t.amharic.sample : t.oromo.sample}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="lang-sec__more">{t.more} 🚀</div>
                </div>
            </div>
        </section>
    );
}
