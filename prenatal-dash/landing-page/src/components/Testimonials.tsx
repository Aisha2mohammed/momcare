import { useEffect, useRef, useState } from 'react';
import './Testimonials.css';

interface TestimonialsProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        badge: 'Real Mothers, Real Stories',
        title: 'Loved by Mothers\nAcross Ethiopia',
        sub: 'Read what real mothers are saying about their experience with Smart Pregnancy Companion.',
        testimonials: [
            {
                name: 'Tigist Alemu',
                location: 'Addis Ababa, Ethiopia',
                avatar: '👩🏾',
                stars: 5,
                text: 'This app changed my entire pregnancy experience. The nutrition guidance helped me eat better local foods, and the baby tracker made every week exciting. I felt supported every step of the way.',
            },
            {
                name: 'Amira Mohammed',
                location: 'Dire Dawa, Ethiopia',
                avatar: '👩🏾‍🦱',
                stars: 5,
                text: 'The Afan Oromo support means everything to me. For the first time, I could understand all the health information in my own language. The emergency contact feature gave me peace of mind.',
            },
            {
                name: 'Selamawit Bekele',
                location: 'Hawassa, Ethiopia',
                avatar: '👩🏿',
                stars: 5,
                text: 'As a first-time mother, I was very anxious. This app provided everything I needed — from safe exercises to sleep tips. The daily reminders ensured I never missed a vitamin or doctor visit.',
            },
            {
                name: 'Frehiwot Tadesse',
                location: 'Bahir Dar, Ethiopia',
                avatar: '👩🏾‍🦰',
                stars: 5,
                text: 'The music and relaxation features helped me manage pregnancy stress so well. My baby felt calm, and so did I. I\'ve recommended this app to every pregnant woman I know!',
            },
        ],
    },
    am: {
        badge: 'እውነተኛ እናቶች፣ እውነተኛ ታሪኮች',
        title: 'በኢትዮጵያ ሁሉ\nበእናቶች የተወደደ',
        sub: 'እናቶቹ ስለ ብልህ እርግዝና ጓደኛ ልምዳቸው ምን እንደሚሉ ያንብቡ።',
        testimonials: [
            {
                name: 'ትግስት አለሙ',
                location: 'አዲስ አበባ፣ ኢትዮጵያ',
                avatar: '👩🏾',
                stars: 5,
                text: 'ይህ አፕ ሙሉ የእርግዝና ልምዴን ቀይሮታል። የምግብ ምክሩ ጥሩ ኢትዮጵያዊ ምግቦችን እንዳበላ ረዳኝ። በእያንዳንዱ ደረጃ ስሜቱ ደስ ያለ ነበር።',
            },
            {
                name: 'አሚራ መሐመድ',
                location: 'ድሬ ዳዋ፣ ኢትዮጵያ',
                avatar: '👩🏾‍🦱',
                stars: 5,
                text: 'የአፋን ኦሮሞ ድጋፍ ሁሉን ነገር ይለውጣል። ለመጀመሪያ ጊዜ ሁሉንም የጤና መረጃ በቋንቋዬ ልረዳ ቻልኩ። የአደጋ ጊዜ ዕርዳታ ደህንነቱ እርጋታ ሰጥቶኛል።',
            },
            {
                name: 'ሰላማዊት በቀለ',
                location: 'ሃዋሳ፣ ኢትዮጵያ',
                avatar: '👩🏿',
                stars: 5,
                text: 'እንደ አዲስ እናት፣ እጅግ ስጋ ነበረኝ። ይህ አፕ ሁሉንም አስፈላጊ ነገሮች ሰጥቶኛል — ከደህንነቱ ከተጠበቀ ልምምድ እስከ የእንቅልፍ ምክሮች።',
            },
            {
                name: 'ፍሬህይወት ታደሰ',
                location: 'ባህር ዳር፣ ኢትዮጵያ',
                avatar: '👩🏾‍🦰',
                stars: 5,
                text: 'የሙዚቃ እና ዘና ማሰብ ባህሪዎቹ የእርግዝና ጭንቀቴን ለመቅረፍ ጥሩ ረድቶኛል። ለምታውቀው ነፍሰ ጡር ሴት ሁሉ ይህን አፕ ምክሬ ሰጥቻለሁ!',
            },
        ],
    },
};

export default function Testimonials({ lang }: TestimonialsProps) {
    const t = content[lang];
    const [active, setActive] = useState(0);
    const sectionRef = useRef<HTMLElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) setVisible(true); },
            { threshold: 0.15 }
        );
        if (sectionRef.current) observer.observe(sectionRef.current);
        return () => observer.disconnect();
    }, []);

    // Auto-rotate
    useEffect(() => {
        const interval = setInterval(() => {
            setActive(v => (v + 1) % t.testimonials.length);
        }, 5000);
        return () => clearInterval(interval);
    }, [t.testimonials.length]);

    return (
        <section className="testimonials" id="testimonials" ref={sectionRef}>
            <div className="testimonials__bg" aria-hidden="true" />

            <div className="testimonials__container">
                <div className={`testimonials__header${visible ? ' visible' : ''}`}>
                    <div className="section-badge">{t.badge}</div>
                    <h2 className="section-title" style={{ whiteSpace: 'pre-line', color: '#fff' }}>{t.title}</h2>
                    <p className="section-sub" style={{ color: 'rgba(255,255,255,0.75)' }}>{t.sub}</p>
                </div>

                <div className={`testimonials__cards${visible ? ' visible' : ''}`}>
                    {t.testimonials.map((item, i) => (
                        <button
                            key={i}
                            className={`testimonial-card${active === i ? ' testimonial-card--active' : ''}`}
                            onClick={() => setActive(i)}
                            id={`testimonial-${i}`}
                        >
                            <div className="testimonial-card__top">
                                <span className="testimonial-card__avatar">{item.avatar}</span>
                                <div>
                                    <div className="testimonial-card__name">{item.name}</div>
                                    <div className="testimonial-card__location">{item.location}</div>
                                </div>
                                <div className="testimonial-card__stars">
                                    {'⭐'.repeat(item.stars)}
                                </div>
                            </div>
                            <p className="testimonial-card__text">{item.text}</p>
                        </button>
                    ))}
                </div>

                {/* Dots */}
                <div className="testimonials__dots">
                    {t.testimonials.map((_, i) => (
                        <button
                            key={i}
                            className={`testimonials__dot${active === i ? ' testimonials__dot--active' : ''}`}
                            onClick={() => setActive(i)}
                            aria-label={`Testimonial ${i + 1}`}
                        />
                    ))}
                </div>
            </div>
        </section>
    );
}
