import './HeroSection.css';

interface HeroSectionProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        badge: '🌸 Trusted by 50,000+ Ethiopian Mothers',
        headline: 'Your Smart Companion\nThrough Every Step of\n',
        highlight: 'Your Pregnancy',
        sub: 'Personalized nutrition, fetal growth tracking, exercise guidance, relaxing music, and emergency support — all in one beautiful app, available in Amharic & Afan Oromo.',
        cta: 'Download Free',
        ctaSecondary: 'Watch Demo',
        stat1: '50K+',
        stat1Label: 'Active Mothers',
        stat2: '8',
        stat2Label: 'Core Features',
        stat3: '2',
        stat3Label: 'Languages',
    },
    am: {
        badge: '🌸 በ50,000+ ኢትዮጵያዊ እናቶች የተደገፈ',
        headline: 'በእርግዝና ጉዞ ሁሉ\nዘመናዊ ጓደኛዎ\n',
        highlight: 'ብልህ እርግዝና',
        sub: 'ግላዊ አመጋገብ፣ የፅንስ ዕድገት ምርመራ፣ የአካል ብቃት መምሪያ፣ ዘና የሚያደርግ ሙዚቃ እና አደጋ ወቅት ድጋፍ — ሁሉም በአንድ ቆንጆ አፕ፣ በአማርኛ እና አፋን ኦሮሞ።',
        cta: 'ነፃ አውርድ',
        ctaSecondary: 'ዴሞ ይመልከቱ',
        stat1: '50K+',
        stat1Label: 'ንቁ እናቶች',
        stat2: '8',
        stat2Label: 'ዋና ባህሪያት',
        stat3: '2',
        stat3Label: 'ቋንቋዎች',
    },
};

export default function HeroSection({ lang }: HeroSectionProps) {
    const t = content[lang];

    return (
        <section className="hero" id="hero">
            {/* Background decorations */}
            <div className="hero__blob hero__blob--1" aria-hidden="true" />
            <div className="hero__blob hero__blob--2" aria-hidden="true" />
            <div className="hero__blob hero__blob--3" aria-hidden="true" />

            <div className="hero__container">
                <div className="hero__content">
                    {/* Badge */}
                    <div className="hero__badge" id="hero-badge">
                        {t.badge}
                    </div>

                    {/* Headline */}
                    <h1 className="hero__headline">
                        {t.headline}
                        <span className="hero__highlight">{t.highlight}</span>
                    </h1>

                    {/* Subtext */}
                    <p className="hero__sub">{t.sub}</p>

                    {/* CTAs */}
                    <div className="hero__ctas">
                        <a href="#download" className="hero__btn-primary" id="hero-cta-download">
                            <span>📱</span>
                            {t.cta}
                        </a>
                        <a href="#how-it-works" className="hero__btn-secondary" id="hero-cta-demo">
                            <span className="hero__play-icon">▶</span>
                            {t.ctaSecondary}
                        </a>
                    </div>

                    {/* Stats */}
                    <div className="hero__stats">
                        <div className="hero__stat">
                            <strong>{t.stat1}</strong>
                            <span>{t.stat1Label}</span>
                        </div>
                        <div className="hero__stat-divider" />
                        <div className="hero__stat">
                            <strong>{t.stat2}</strong>
                            <span>{t.stat2Label}</span>
                        </div>
                        <div className="hero__stat-divider" />
                        <div className="hero__stat">
                            <strong>{t.stat3}</strong>
                            <span>{t.stat3Label}</span>
                        </div>
                    </div>
                </div>

                {/* Phone mockup */}
                <div className="hero__mockup" id="hero-mockup">
                    <div className="hero__phone">
                        <div className="hero__phone-inner">
                            <div className="hero__phone-screen">
                                <div className="hero__app-header">
                                    <img src="/pregnancy-logo.png" alt="App" className="hero__app-logo" />
                                    <div>
                                        <div className="hero__app-title">Smart Pregnancy</div>
                                        <div className="hero__app-week">{lang === 'en' ? 'Week 24 · Baby is growing!' : 'ሳምንት 24 · ህፃን በማደግ ላይ!'}</div>
                                    </div>
                                </div>

                                <div className="hero__app-card">
                                    <div className="hero__app-card-label">{lang === 'en' ? "Today's Tip" : 'የዛሬ ምክር'}</div>
                                    <div className="hero__app-card-text">
                                        {lang === 'en'
                                            ? '🥗 Eat iron-rich foods like lentils & spinach to support your baby\'s growth.'
                                            : '🥗 የሕፃን ዕድገትን ለመደገፍ እቦ እና ስፒናቸ ያሉ ብረት ያዘሉ ምግቦችን ይብሉ።'}
                                    </div>
                                </div>

                                <div className="hero__app-grid">
                                    {[
                                        { icon: '🥗', label: lang === 'en' ? 'Nutrition' : 'አመጋገብ' },
                                        { icon: '👶', label: lang === 'en' ? 'Baby Growth' : 'የፅንስ ዕድገት' },
                                        { icon: '🏃‍♀️', label: lang === 'en' ? 'Exercise' : 'ልምምድ' },
                                        { icon: '😴', label: lang === 'en' ? 'Sleep' : 'እንቅልፍ' },
                                        { icon: '🎵', label: lang === 'en' ? 'Music' : 'ሙዚቃ' },
                                        { icon: '🚨', label: lang === 'en' ? 'Emergency' : 'አደጋ' },
                                    ].map(item => (
                                        <div key={item.label} className="hero__app-icon-btn">
                                            <span>{item.icon}</span>
                                            <span>{item.label}</span>
                                        </div>
                                    ))}
                                </div>

                                <div className="hero__app-progress-label">
                                    {lang === 'en' ? 'Pregnancy Progress' : 'የእርግዝና ሂደት'}
                                </div>
                                <div className="hero__app-progress-bar">
                                    <div className="hero__app-progress-fill" style={{ width: '60%' }}>
                                        <span className="hero__app-progress-emoji">👶</span>
                                    </div>
                                </div>
                                <div className="hero__app-progress-sub">
                                    {lang === 'en' ? '24 / 40 weeks — 2nd Trimester' : '24 / 40 ሳምንታት — 2ኛ ሦስት ወር'}
                                </div>
                            </div>
                        </div>
                        {/* Glow */}
                        <div className="hero__phone-glow" aria-hidden="true" />
                    </div>

                    {/* Floating cards */}
                    <div className="hero__float hero__float--1" aria-label="Notification card">
                        <span>🔔</span>
                        <div>
                            <div className="hero__float-title">{lang === 'en' ? 'Reminder' : 'ማስታወሻ'}</div>
                            <div className="hero__float-sub">{lang === 'en' ? 'Doctor visit today' : 'ዛሬ ዶክተር ጉብኝት'}</div>
                        </div>
                    </div>

                    <div className="hero__float hero__float--2" aria-label="Progress card">
                        <span>❤️</span>
                        <div>
                            <div className="hero__float-title">{lang === 'en' ? 'Heart Rate' : 'የልብ ምት'}</div>
                            <div className="hero__float-sub">142 bpm — {lang === 'en' ? 'Normal' : 'መደበኛ'}</div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Scroll arrow */}
            <a href="#features" className="hero__scroll" aria-label="Scroll to features">
                <div className="hero__scroll-arrow" />
            </a>
        </section>
    );
}
