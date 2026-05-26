function setLang(lang) {
  if (!translations[lang]) return;
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (translations[lang][key] !== undefined) {
      el.textContent = translations[lang][key];
    }
  });
  document.querySelectorAll('.lang-switcher button').forEach(btn => {
    btn.classList.toggle('active', btn.id === 'btn-' + lang);
  });
  localStorage.setItem('bmcu-lang', lang);
}

function detectLang() {
  const saved = localStorage.getItem('bmcu-lang');
  if (saved && translations[saved]) return saved;
  const nav = navigator.language || navigator.userLanguage || 'en';
  const code = nav.toLowerCase().substring(0, 2);
  if (code === 'pt') return 'pt';
  if (code === 'es') return 'es';
  return 'en';
}

document.addEventListener('DOMContentLoaded', () => {
  setLang(detectLang());
});
