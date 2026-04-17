// Language switcher logic
const langSelect = document.getElementById('langSelect');

const setLanguage = (lang) => {
    if (!translations[lang]) return;

    document.querySelectorAll('[data-i18n]').forEach(element => {
        const key = element.getAttribute('data-i18n');
        if (translations[lang][key]) {
            element.textContent = translations[lang][key];
        }
    });

    // Update HTML lang attribute
    document.documentElement.lang = lang;
    
    // Persist
    localStorage.setItem('stanomer_lang', lang);
    langSelect.value = lang;
};

langSelect.addEventListener('change', (e) => {
    setLanguage(e.target.value);
});

// Initialize language
const initLanguage = () => {
    const savedLang = localStorage.getItem('stanomer_lang');
    const browserLang = navigator.language.split('-')[0];
    const defaultLang = savedLang || (translations[browserLang] ? browserLang : 'tr');
    
    setLanguage(defaultLang);
};

// Navbar shadow on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.boxShadow = 'var(--shadow)';
    } else {
        navbar.style.boxShadow = 'none';
    }
});

// Mobile Menu Toggle
const menuToggle = document.getElementById('menuToggle');
const navLinks = document.getElementById('navLinks');
const menuIcon = document.getElementById('menuIcon');

menuToggle.addEventListener('click', () => {
    navLinks.classList.toggle('active');
    const isActive = navLinks.classList.contains('active');
    
    // Switch icon
    menuIcon.setAttribute('data-lucide', isActive ? 'x' : 'menu');
    if (window.lucide) {
        lucide.createIcons();
    }
});

// Close menu when clicking links
navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        menuIcon.setAttribute('data-lucide', 'menu');
        if (window.lucide) {
            lucide.createIcons();
        }
    });
});

// Initial load
document.addEventListener('DOMContentLoaded', () => {
    initLanguage();
    if (window.lucide) lucide.createIcons();
});
