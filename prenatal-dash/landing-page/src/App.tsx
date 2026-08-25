import { useState } from 'react';
import Navbar from './components/Navbar';
import HeroSection from './components/HeroSection';
import FeaturesSection from './components/FeaturesSection';
import HowItWorks from './components/HowItWorks';
import LanguageSection from './components/LanguageSection';
import Testimonials from './components/Testimonials';
import DownloadCTA from './components/DownloadCTA';
import Footer from './components/Footer';

type Lang = 'en' | 'am';

function App() {
  const [lang, setLang] = useState<Lang>('en');
  const toggleLang = () => setLang(l => l === 'en' ? 'am' : 'en');

  return (
    <>
      <Navbar lang={lang} onLangToggle={toggleLang} />
      <main>
        <HeroSection lang={lang} />
        <FeaturesSection lang={lang} />
        <HowItWorks lang={lang} />
        <LanguageSection lang={lang} />
        <Testimonials lang={lang} />
        <DownloadCTA lang={lang} />
      </main>
      <Footer lang={lang} />
    </>
  );
}

export default App;
