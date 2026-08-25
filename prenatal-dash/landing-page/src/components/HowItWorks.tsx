import { useEffect, useRef, useState } from 'react';
import './HowItWorks.css';

interface HowItWorksProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        badge: 'Simple & Easy',
        title: 'Get Started in\n3 Simple Steps',
        sub: 'Join thousands of Ethiopian mothers who are already using Smart Pregnancy Companion.',
        steps: [
            {
                num: '01',
                icon: '📲',
                title: 'Download the App',
                desc: 'Available free on Google Play Store. Install in under a minute on any Android device.',
            },
            {
                num: '02',
                icon: '👤',
                title: 'Set Up Your Profile',
                desc: 'Enter your due date, choose your language (Amharic or Afan Oromo), and personalize your experience.',
            },
            {
                num: '03',
                icon: '🌸',
                title: 'Start Your Journey',
                desc: 'Access all 8 features instantly. Track your baby\'s growth, get daily tips, and stay healthy.',
            },
        ],
    },
    am: {
        badge: 'ቀላል እና ፈጣን',
        title: 'በ3 ቀላል ደረጃዎች\nጀምሩ',
        sub: 'ቀድሞ የሚጠቀሙ ሺዎች ኢትዮጵያዊ እናቶች ይቀላቀሉ።',
        steps: [
            {
                num: '01',
                icon: '📲',
                title: 'አፕ አውርዱ',
                desc: 'በ Google Play Store ላይ ነፃ ይገኛል። በማንኛውም Android ላይ በደቂቃ ጫኑ።',
            },
            {
                num: '02',
                icon: '👤',
                title: 'መለያዎን ያዘጋጁ',
                desc: 'የወሊድ ቀንዎን ያስገቡ፣ ቋንቋ ይምረጡ (አማርኛ ወይም አፋን ኦሮሞ) እና ተሞክሮዎን ያስተካክሉ።',
            },
            {
                num: '03',
                icon: '🌸',
                title: 'ጉዞዎን ይጀምሩ',
                desc: 'ሁሉንም 8 ባህሪያት ወዲያው ይዳሰሱ። የህፃን ዕድገቱን ይከታተሉ፣ ዕለታዊ ምክሮች ያግኙ።',
            },
        ],
    },
};

export default function HowItWorks({ lang }: HowItWorksProps) {
    const t = content[lang];
    const sectionRef = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) { setVisible(true); observer.disconnect(); } },
            { threshold: 0.15 }
        );
        if (sectionRef.current) observer.observe(sectionRef.current);
        return () => observer.disconnect();
    }, []);

    return (
        <section className="hiw" id="how-it-works" ref={sectionRef}>
            <div className="hiw__bg-circle hiw__bg-circle--1" aria-hidden="true" />
            <div className="hiw__bg-circle hiw__bg-circle--2" aria-hidden="true" />

            <div className="hiw__container">
                <div className={`hiw__header${visible ? ' hiw__header--visible' : ''}`}>
                    <div className="section-badge">{t.badge}</div>
                    <h2 className="section-title" style={{ whiteSpace: 'pre-line' }}>{t.title}</h2>
                    <p className="section-sub">{t.sub}</p>
                </div>

                <div className="hiw__steps">
                    {t.steps.map((step, i) => (
                        <div
                            key={i}
                            className={`hiw__step${visible ? ' hiw__step--visible' : ''}`}
                            style={{ transitionDelay: `${i * 150 + 200}ms` }}
                            id={`hiw-step-${i}`}
                        >
                            {/* Connector line */}
                            {i < t.steps.length - 1 && (
                                <div className="hiw__connector" aria-hidden="true" />
                            )}

                            <div className="hiw__step-num">{step.num}</div>
                            <div className="hiw__step-icon-wrap">
                                <div className="hiw__step-icon">{step.icon}</div>
                                <div className="hiw__step-ring" aria-hidden="true" />
                            </div>
                            <div className="hiw__step-body">
                                <h3 className="hiw__step-title">{step.title}</h3>
                                <p className="hiw__step-desc">{step.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Phone visual bar */}
                <div className={`hiw__visual${visible ? ' hiw__visual--visible' : ''}`}>
                    <div className="hiw__visual-inner">
                        <span className="hiw__visual-icon">✅</span>
                        <div>
                            <div className="hiw__visual-title">
                                {lang === 'en' ? 'Ready to Go!' : 'ዝግጁ ነው!'}
                            </div>
                            <div className="hiw__visual-sub">
                                {lang === 'en'
                                    ? 'Your personalized pregnancy journey starts now.'
                                    : 'ግላዊ የእርግዝና ጉዞዎ አሁን ይጀምራል።'}
                            </div>
                        </div>
                        <a href="#download" className="hiw__visual-cta">
                            {lang === 'en' ? 'Download' : 'አውርድ'} →
                        </a>
                    </div>
                </div>
            </div>
        </section>
    );
}
