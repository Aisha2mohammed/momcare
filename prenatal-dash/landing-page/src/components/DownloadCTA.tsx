import './DownloadCTA.css';

interface DownloadCTAProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        badge: 'Free Download',
        title: 'Start Your Healthy\nPregnancy Journey Today',
        sub: 'Download Smart Pregnancy Companion for free. Join over 50,000 Ethiopian mothers who are raising healthier babies.',
        google: 'Get it on Google Play',
        or: 'or scan to download',
        disclaimer: 'Free download • No credit card required • Available for Android',
        features: [
            { icon: '🔒', text: 'Private & Secure' },
            { icon: '📶', text: 'Works Offline' },
            { icon: '💰', text: '100% Free' },
            { icon: '🌍', text: 'Amharic & Oromo' },
        ],
    },
    am: {
        badge: 'ነፃ ያውርዱ',
        title: 'ዛሬ ጤናማ\nየእርግዝና ጉዞ ይጀምሩ',
        sub: 'ብልህ እርግዝና ጓደኛን ነፃ ያውርዱ። ጤናማ ልጆችን ከሚያሳዩ ከ50,000 ኢትዮጵያዊ እናቶች ጋር ይቀላቀሉ።',
        google: 'ከ Google Play ያውርዱ',
        or: 'ወይም ለማውረድ ስካን ያድርጉ',
        disclaimer: 'ነፃ ማውረድ • ምንም ክሬዲት ካርድ አያስፈልግም • ለ Android ይገኛል',
        features: [
            { icon: '🔒', text: 'ብቻዊ እና ደህንነቱ የተጠበቀ' },
            { icon: '📶', text: 'ያለ ኢንተርኔት ይሰራል' },
            { icon: '💰', text: '100% ነፃ' },
            { icon: '🌍', text: 'አማርኛ እና ኦሮሞ' },
        ],
    },
};

export default function DownloadCTA({ lang }: DownloadCTAProps) {
    const t = content[lang];

    return (
        <section className="cta" id="download">
            <div className="cta__glow cta__glow--1" aria-hidden="true" />
            <div className="cta__glow cta__glow--2" aria-hidden="true" />

            <div className="cta__container">
                <div className="cta__content">
                    <div className="section-badge" style={{ background: 'rgba(255,255,255,0.15)', color: '#fff', borderColor: 'rgba(255,255,255,0.3)' }}>
                        {t.badge}
                    </div>
                    <h2 className="section-title" style={{ color: '#fff', whiteSpace: 'pre-line', fontSize: 'clamp(1.8rem,4vw,2.8rem)' }}>
                        {t.title}
                    </h2>
                    <p className="section-sub" style={{ color: 'rgba(255,255,255,0.8)' }}>
                        {t.sub}
                    </p>

                    {/* Feature chips */}
                    <div className="cta__chips">
                        {t.features.map(f => (
                            <div key={f.text} className="cta__chip">
                                <span>{f.icon}</span>
                                <span>{f.text}</span>
                            </div>
                        ))}
                    </div>

                    {/* Download buttons */}
                    <div className="cta__btns">
                        <a
                            href="https://play.google.com/store"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="cta__btn-play"
                            id="google-play-btn"
                        >
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                                <path d="M3.18 23.4c.3.16.63.23.97.17l12.02-11.14L12 8.3 3.18 23.4z" />
                                <path d="M21.43 10.6l-3.04-1.73L14.5 12l3.9 3.6 3.03-1.72a1.75 1.75 0 000-3.28z" />
                                <path d="M2.25 1.27A1.75 1.75 0 002 2.1v19.8c0 .3.07.6.2.85L12 12 2.25 1.27z" />
                                <path d="M4.15.43l12.02 11.13L12 8.3 4.15.43c-.34-.06-.67 0-.97.17-.3.16-.54.4-.7.7A1.75 1.75 0 003 2.1V2c0-.3.08-.6.22-.85.17-.3.42-.55.73-.7.3-.17.65-.22.97-.17l-.77.15z" />
                            </svg>
                            <div>
                                <div className="cta__btn-sub">{lang === 'en' ? 'Get it on' : 'ያወርዱ'}</div>
                                <div className="cta__btn-main">Google Play</div>
                            </div>
                        </a>
                    </div>

                    <p className="cta__disclaimer">{t.disclaimer}</p>
                </div>

                {/* QR Code placeholder */}
                <div className="cta__qr-wrap">
                    <div className="cta__qr">
                        <div className="cta__qr-inner">
                            <div className="cta__qr-grid">
                                {Array.from({ length: 100 }).map((_, i) => (
                                    <div
                                        key={i}
                                        className="cta__qr-cell"
                                        style={{ opacity: Math.random() > 0.4 ? 1 : 0 }}
                                    />
                                ))}
                            </div>
                            <div className="cta__qr-logo">
                                <img src="/white-pregnancy-logo.png" alt="Logo" />
                            </div>
                        </div>
                    </div>
                    <p className="cta__qr-label">{t.or}</p>
                </div>
            </div>
        </section>
    );
}
