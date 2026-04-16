// Navbar shadow on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.boxShadow = 'var(--shadow)';
        navbar.style.background = 'rgba(255, 255, 255, 0.9)';
    } else {
        navbar.style.boxShadow = 'none';
        navbar.style.background = 'var(--glass)';
    }
});

// Simple Scroll Reveal Effect
const revealOnScroll = () => {
    const reveals = document.querySelectorAll('.role-card, .feature-item');
    
    reveals.forEach(element => {
        const windowHeight = window.innerHeight;
        const elementTop = element.getBoundingClientRect().top;
        const elementVisible = 150;
        
        if (elementTop < windowHeight - elementVisible) {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
        }
    });
};

// Set initial state for reveal
document.querySelectorAll('.role-card, .feature-item').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'all 0.8s ease-out';
});

window.addEventListener('scroll', revealOnScroll);
revealOnScroll(); // Trigger initial check
