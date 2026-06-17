// Language switcher logic
const langSwitcher = document.getElementById('langSwitcher');

const setLanguage = (lang) => {
    if (!translations[lang]) return;

    document.querySelectorAll('[data-i18n]').forEach(element => {
        const key = element.getAttribute('data-i18n');
        if (translations[lang][key]) {
            element.innerHTML = translations[lang][key];
        }
    });

    // Update active state in switcher
    document.querySelectorAll('#langSwitcher span').forEach(span => {
        if (span.getAttribute('data-lang') === lang) {
            span.classList.add('active');
        } else {
            span.classList.remove('active');
        }
    });

    // Update HTML lang attribute
    document.documentElement.lang = lang;
    
    // Persist
    localStorage.setItem('stanomer_lang', lang);
};

langSwitcher.addEventListener('click', (e) => {
    const lang = e.target.getAttribute('data-lang');
    if (lang) {
        setLanguage(lang);
    }
});

// Initialize language
const initLanguage = () => {
    const savedLang = localStorage.getItem('stanomer_lang');
    const browserLang = navigator.language.split('-')[0];
    const defaultLang = savedLang || (translations[browserLang] ? browserLang : 'en');
    
    setLanguage(defaultLang);
};

// Navbar shadow on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (navbar) {
        if (window.scrollY > 50) {
            navbar.style.boxShadow = 'var(--shadow)';
        } else {
            navbar.style.boxShadow = 'none';
        }
    }
});

// ── OS Detection & Button Visibility ──────────────────────────────────────────
const applyOSVisibility = () => {
    const ua = window.navigator.userAgent || window.navigator.vendor || '';
    const platform = window.navigator.platform || '';

    const isIOS =
        /iPad|iPhone|iPod/.test(ua) ||
        (platform === 'MacIntel' && navigator.maxTouchPoints > 1);
    const isAndroid = /android/i.test(ua);

    const ids = {
        heroAppStore:    document.getElementById('heroAppStore'),
        heroGooglePlay:  document.getElementById('heroGooglePlay'),
        heroWebAppWrap:  document.getElementById('heroWebAppWrap'),
        footerAppStore:  document.getElementById('footerAppStore'),
        footerGooglePlay:document.getElementById('footerGooglePlay'),
        footerWebAppWrap:document.getElementById('footerWebAppWrap'),
    };

    if (isIOS) {
        // Show only App Store
        if (ids.heroGooglePlay)   ids.heroGooglePlay.style.display  = 'none';
        if (ids.heroWebAppWrap)   ids.heroWebAppWrap.style.display   = 'none';
        if (ids.footerGooglePlay) ids.footerGooglePlay.style.display = 'none';
        if (ids.footerWebAppWrap) ids.footerWebAppWrap.style.display  = 'none';
    } else if (isAndroid) {
        // Show only Google Play
        if (ids.heroAppStore)    ids.heroAppStore.style.display    = 'none';
        if (ids.heroWebAppWrap)  ids.heroWebAppWrap.style.display   = 'none';
        if (ids.footerAppStore)  ids.footerAppStore.style.display   = 'none';
        if (ids.footerWebAppWrap)ids.footerWebAppWrap.style.display  = 'none';
    }
    // Desktop: all three visible by default — no changes needed
};

// Initial load
document.addEventListener('DOMContentLoaded', () => {
    initLanguage();
    applyOSVisibility();
    if (window.lucide) lucide.createIcons();
});
