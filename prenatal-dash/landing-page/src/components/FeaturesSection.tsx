import { useEffect, useRef, useState } from 'react';
import './FeaturesSection.css';

interface FeaturesSectionProps {
    lang: 'en' | 'am';
}

const features = {
    en: {
        sectionBadge: 'Everything You Need',
        title: '8 Powerful Features\nfor a Healthy Pregnancy',
        sub: 'Designed with Ethiopian mothers in mind — culturally relevant, scientifically backed, beautifully simple.',
        items: [
            {
                icon: '🥗',
                color: '#e8f5e9',
                accent: '#2e7d32',
                title: 'Nutrition Guidance',
                desc: 'Personalized daily meal plans with locally available Ethiopian foods rich in iron, folate, and calcium.',
            },
            {
                icon: '👶',
                color: '#fce4ec',
                accent: '#c2185b',
                title: 'Fetal Development',
                desc: 'Week-by-week visual tracker showing your baby\'s size, development milestones, and what to expect.',
            },
            {
                icon: '🏃‍♀️',
                color: '#e3f2fd',
                accent: '#1565c0',
                title: 'Exercise & Wellness',
                desc: 'Safe, trimester-aware workouts and stretches designed specifically for pregnant women.',
            },
            {
                icon: '😴',
                color: '#ede7f6',
                accent: '#6a1b9a',
                title: 'Sleep Positions',
                desc: 'Expert guidance on the best sleeping positions to ensure your comfort and baby\'s safety.',
            },
            {
                icon: '🎵',
                color: '#fff3e0',
                accent: '#e65100',
                title: 'Music & Relaxation',
                desc: 'Curated calming playlists and guided breathing exercises to reduce stress and anxiety.',
            },
            {
                icon: '🔔',
                color: '#f3e5f5',
                accent: '#7b1fa2',
                title: 'Smart Reminders',
                desc: 'Never miss a doctor appointment, medication, or prenatal vitamin with intelligent notifications.',
            },
            {
                icon: '🚨',
                color: '#ffebee',
                accent: '#c62828',
                title: 'Emergency Contacts',
                desc: 'One-tap access to your doctor, nearest hospital, and emergency health guidance when you need it.',
            },
            {
                icon: '🌍',
                color: '#e8f5e9',
                accent: '#1b5e20',
                title: 'Multilingual Support',
                desc: 'Full support in Amharic and Afan Oromo — making maternal health accessible to every Ethiopian woman.',
            },
        ],
    },
    am: {
        sectionBadge: 'የሚያስፈልጉዎት ሁሉ',
        title: '8 ኃይለኛ ባህሪያት\nለጤናማ እርግዝና',
        sub: 'ለኢትዮጵያ እናቶች ታሳቢ ተደርጎ የተዘጋጀ — ባህላዊ፣ ሳይንሳዊ፣ እና ቀላል።',
        items: [
            {
                icon: '🥗',
                color: '#e8f5e9',
                accent: '#2e7d32',
                title: 'የአመጋገብ መምሪያ',
                desc: 'ብረት፣ ፎሌት እና ካልሲየም ያዘሉ ኢትዮጵያዊ ምግቦችን ያካተተ ግላዊ ዕለታዊ የምግብ ፕላን።',
            },
            {
                icon: '👶',
                color: '#fce4ec',
                accent: '#c2185b',
                title: 'የፅንስ ዕድገት',
                desc: 'ሳምንታዊ ምስላዊ ትራከር — የህፃን መጠን፣ ዕድገት ደረጃዎች እና ምን ማወቅ ይገባዎትን ያሳያል።',
            },
            {
                icon: '🏃‍♀️',
                color: '#e3f2fd',
                accent: '#1565c0',
                title: 'ልምምድ እና ጤናማነት',
                desc: 'ለነፍሰ ጡር ሴቶች በተለይ የተዘጋጁ ደህንነቱ የተጠበቀ ልምምዶችና ዳዛዎች።',
            },
            {
                icon: '😴',
                color: '#ede7f6',
                accent: '#6a1b9a',
                title: 'የእንቅልፍ ቦታ',
                desc: 'ምቾትዎን እና የህፃን ደህንነትን ለማረጋገጥ የምርጥ የእንቅልፍ ቀጠናዎች ምክር።',
            },
            {
                icon: '🎵',
                color: '#fff3e0',
                accent: '#e65100',
                title: 'ሙዚቃ እና ዘና ማለት',
                desc: 'ጭንቀትን ለመቀነስ የተዘጋጁ የሙዚቃ ዝርዝሮች እና መተንፈሻ ልምምዶች።',
            },
            {
                icon: '🔔',
                color: '#f3e5f5',
                accent: '#7b1fa2',
                title: 'ብልህ ማስታወሻዎች',
                desc: 'የዶክተር ቀጠሮዎን፣ ክኒናቸ እና ቅድመ ወሊድ ቫይታሚኖችን አትርሱ።',
            },
            {
                icon: '🚨',
                color: '#ffebee',
                accent: '#c62828',
                title: 'አደጋ ጊዜ ዕርዳታ',
                desc: 'ዶክተርዎን፣ ቅርብ ሆስፒታልን እና አደጋ ጊዜ ጤና ምክሮችን በአንድ ጠቅ ያግኙ።',
            },
            {
                icon: '🌍',
                color: '#e8f5e9',
                accent: '#1b5e20',
                title: 'የቋንቋ ድጋፍ',
                desc: 'ሁሉንም ኢትዮጵያዊ ሴቶች ለጤና ተደራሽ ለማድረግ በአማርኛ እና አፋን ኦሮሞ ሙሉ ድጋፍ።',
            },
        ],
    },
};

function FeatureCard({ icon, color, accent, title, desc, index }: {
    icon: string; color: string; accent: string;
    title: string; desc: string; index: number;
}) {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) { setVisible(true); observer.disconnect(); } },
            { threshold: 0.15 }
        );
        if (ref.current) observer.observe(ref.current);
        return () => observer.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`feature-card${visible ? ' feature-card--visible' : ''}`}
            style={{ transitionDelay: `${index * 80}ms` }}
            id={`feature-card-${index}`}
        >
            <div className="feature-card__icon" style={{ background: color }}>
                <span style={{ fontSize: '1.8rem' }}>{icon}</span>
                <div className="feature-card__icon-ring" style={{ borderColor: accent + '40' }} />
            </div>
            <h3 className="feature-card__title" style={{ color: accent }}>{title}</h3>
            <p className="feature-card__desc">{desc}</p>
        </div>
    );
}

export default function FeaturesSection({ lang }: FeaturesSectionProps) {
    const t = features[lang];
    const titleRef = useRef<HTMLDivElement>(null);
    const [titleVisible, setTitleVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) { setTitleVisible(true); observer.disconnect(); } },
            { threshold: 0.2 }
        );
        if (titleRef.current) observer.observe(titleRef.current);
        return () => observer.disconnect();
    }, []);

    return (
        <section className="features" id="features">
            <div className="features__container">
                <div ref={titleRef} className={`features__header${titleVisible ? ' features__header--visible' : ''}`}>
                    <div className="section-badge">{t.sectionBadge}</div>
                    <h2 className="section-title" style={{ whiteSpace: 'pre-line' }}>{t.title}</h2>
                    <p className="section-sub">{t.sub}</p>
                </div>

                <div className="features__grid">
                    {t.items.map((item, i) => (
                        <FeatureCard key={i} {...item} index={i} />
                    ))}
                </div>
            </div>
        </section>
    );
}
