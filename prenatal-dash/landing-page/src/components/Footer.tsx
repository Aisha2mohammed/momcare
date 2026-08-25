import './Footer.css';

interface FooterProps {
    lang: 'en' | 'am';
}

const content = {
    en: {
        tagline: 'Smart Pregnancy Companion — empowering Ethiopian mothers with knowledge, care, and digital innovation.',
        links: [
            { label: 'Features', href: '#features' },
            { label: 'How It Works', href: '#how-it-works' },
            { label: 'Testimonials', href: '#testimonials' },
            { label: 'Download', href: '#download' },
        ],
        legal: [
            { label: 'Privacy Policy', href: '#' },
            { label: 'Terms of Service', href: '#' },
        ],
        copy: `© ${new Date().getFullYear()} Smart Pregnancy Companion. All rights reserved.`,
        madeWith: 'Made with ❤️ for Ethiopian Mothers',
    },
    am: {
        tagline: 'ብልህ እርግዝና ጓደኛ — ኢትዮጵያዊ እናቶችን በዕውቀት፣ ጥንቃቄ እና ዲጂታል ፈጠራ የሚያበረታ።',
        links: [
            { label: 'ባህሪያት', href: '#features' },
            { label: 'እንዴት ይሠራል', href: '#how-it-works' },
            { label: 'ምስክርነቶች', href: '#testimonials' },
            { label: 'አውርድ', href: '#download' },
        ],
        legal: [
            { label: 'የግለኝነት ፖሊሲ', href: '#' },
            { label: 'የአገልግሎት ውሎች', href: '#' },
        ],
        copy: `© ${new Date().getFullYear()} ብልህ እርግዝና ጓደኛ። ሁሉም መብቶች የተጠበቁ።`,
        madeWith: 'ለኢትዮጵያዊ እናቶች በፍቅር የተሠራ ❤️',
    },
};

export default function Footer({ lang }: FooterProps) {
    const t = content[lang];
    const year = new Date().getFullYear();

    return (
        <footer className="footer" id="footer">
            <div className="footer__container">
                <div className="footer__top">
                    {/* Brand */}
                    <div className="footer__brand">
                        <div className="footer__logo">
                            <img src="/pregnancy-logo.png" alt="Smart Pregnancy Companion" />
                            <span>{lang === 'en' ? 'Smart Pregnancy' : 'ብልህ እርግዝና'}</span>
                        </div>
                        <p className="footer__tagline">{t.tagline}</p>
                        {/* Social links */}
                        <div className="footer__socials">
                            <a href="#" className="footer__social" aria-label="Facebook">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" /></svg>
                            </a>
                            <a href="#" className="footer__social" aria-label="Twitter">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
                            </a>
                            <a href="#" className="footer__social" aria-label="Telegram">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" /></svg>
                            </a>
                        </div>
                    </div>

                    {/* Nav Links */}
                    <div className="footer__nav">
                        <div className="footer__nav-title">{lang === 'en' ? 'Quick Links' : 'ፈጣን ማስፈንጠሪያ'}</div>
                        <ul>
                            {t.links.map(link => (
                                <li key={link.href}>
                                    <a href={link.href} className="footer__nav-link">{link.label}</a>
                                </li>
                            ))}
                        </ul>
                    </div>

                    {/* Contact */}
                    <div className="footer__nav">
                        <div className="footer__nav-title">{lang === 'en' ? 'Contact' : 'ያነጋግሩን'}</div>
                        <ul>
                            <li><a href="mailto:hello@smartpregnancy.app" className="footer__nav-link">hello@smartpregnancy.app</a></li>
                            <li><a href="tel:+251911000000" className="footer__nav-link">+251 911 000 000</a></li>
                            <li><span className="footer__nav-link" style={{ cursor: 'default' }}>Addis Ababa, Ethiopia</span></li>
                        </ul>
                    </div>
                </div>

                <div className="footer__divider" />

                <div className="footer__bottom">
                    <p className="footer__copy">{t.copy.replace(String(year), String(year))}</p>
                    <div className="footer__legal">
                        {t.legal.map(link => (
                            <a key={link.label} href={link.href} className="footer__legal-link">{link.label}</a>
                        ))}
                    </div>
                    <p className="footer__made">{t.madeWith}</p>
                </div>
            </div>
        </footer>
    );
}
