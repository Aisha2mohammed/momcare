import { useState, useEffect } from 'react';
import './Navbar.css';

interface NavbarProps {
    lang: 'en' | 'am';
    onLangToggle: () => void;
}

const labels = {
    en: {
        features: 'Features',
        howItWorks: 'How It Works',
        testimonials: 'Testimonials',
        download: 'Download App',
        langLabel: 'አማርኛ',
    },
    am: {
        features: 'ባህሪያት',
        howItWorks: 'እንዴት ይሠራል',
        testimonials: 'ምስክርነቶች',
        download: 'አፕ አውርድ',
        langLabel: 'English',
    },
};

export default function Navbar({ lang, onLangToggle }: NavbarProps) {
    const [scrolled, setScrolled] = useState(false);
    const [menuOpen, setMenuOpen] = useState(false);
    const t = labels[lang];

    useEffect(() => {
        const onScroll = () => setScrolled(window.scrollY > 20);
        window.addEventListener('scroll', onScroll, { passive: true });
        return () => window.removeEventListener('scroll', onScroll);
    }, []);

    const closeMenu = () => setMenuOpen(false);

    return (
        <nav className={`navbar${scrolled ? ' navbar--scrolled' : ''}`} id="navbar">
            <div className="navbar__inner">
                {/* Logo */}
                <a href="#" className="navbar__logo" onClick={closeMenu}>
                    <img src="/pregnancy-logo.png" alt="Smart Pregnancy Companion" className="navbar__logo-img" />
                    <span className="navbar__logo-text">
                        {lang === 'en' ? 'Smart Pregnancy' : 'ብልህ እርግዝና'}
                    </span>
                </a>

                {/* Desktop Links */}
                <ul className="navbar__links">
                    <li><a href="#features" className="navbar__link">{t.features}</a></li>
                    <li><a href="#how-it-works" className="navbar__link">{t.howItWorks}</a></li>
                    <li><a href="#testimonials" className="navbar__link">{t.testimonials}</a></li>
                </ul>

                {/* Right Actions */}
                <div className="navbar__actions">
                    <button className="navbar__lang-btn" onClick={onLangToggle} id="lang-toggle-btn" aria-label="Toggle language">
                        <span className="navbar__lang-icon">🌐</span>
                        {t.langLabel}
                    </button>
                    <a href="#download" className="navbar__cta" id="navbar-cta">
                        {t.download}
                    </a>
                </div>

                {/* Hamburger */}
                <button
                    className={`navbar__hamburger${menuOpen ? ' open' : ''}`}
                    onClick={() => setMenuOpen(v => !v)}
                    aria-label="Open menu"
                    id="hamburger-btn"
                >
                    <span /><span /><span />
                </button>
            </div>

            {/* Mobile Menu */}
            <div className={`navbar__mobile${menuOpen ? ' navbar__mobile--open' : ''}`} id="mobile-menu">
                <a href="#features" className="navbar__mobile-link" onClick={closeMenu}>{t.features}</a>
                <a href="#how-it-works" className="navbar__mobile-link" onClick={closeMenu}>{t.howItWorks}</a>
                <a href="#testimonials" className="navbar__mobile-link" onClick={closeMenu}>{t.testimonials}</a>
                <button className="navbar__lang-btn" onClick={() => { onLangToggle(); closeMenu(); }}>
                    🌐 {t.langLabel}
                </button>
                <a href="#download" className="navbar__cta navbar__cta--mobile" onClick={closeMenu}>
                    {t.download}
                </a>
            </div>
        </nav>
    );
}
