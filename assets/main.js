// Links que o Gabriel ainda vai criar. Vazio = mostra "em breve".
const APP_LINKS = {
  youtube: '',
  whatsapp: '',
};

let currentLang = 'en';
let latestRelease = null;

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
  currentLang = lang;
  showRelease();
}

// Versao e data da Release mais nova; sem a API, fica o texto do HTML.
function showRelease() {
  if (!latestRelease) return;
  const date = new Date(latestRelease.published_at)
    .toLocaleDateString(currentLang === 'pt' ? 'pt-BR' : currentLang, { dateStyle: 'medium' });
  document.getElementById('app-version').textContent = `${latestRelease.tag_name} · ${date}`;
}

function loadRelease() {
  fetch('https://api.github.com/repos/gabuldev/bmcu-guide/releases/latest')
    .then(r => (r.ok ? r.json() : null))
    .then(release => {
      if (!release || !release.tag_name) return;
      latestRelease = release;
      showRelease();
    })
    .catch(() => {});
}

function setupAppLinks() {
  for (const [name, url] of Object.entries(APP_LINKS)) {
    const el = document.getElementById('link-' + name);
    if (!el) continue;
    if (url) {
      el.href = url;
      el.querySelector('.soon').remove();
    } else {
      el.classList.add('disabled');
      el.removeAttribute('target');
    }
  }
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
  setupAppLinks();
  setLang(detectLang());
  loadRelease();
});
