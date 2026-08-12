(function () {
  const languageNames = {
    ar: 'Arabic / العربية',
    de: 'German / Deutsch',
    en: 'English / English',
    es: 'Spanish / Español',
    fr: 'French / Français',
    hi: 'Hindi / हिन्दी',
    it: 'Italian / Italiano',
    ja: 'Japanese / 日本語',
    ko: 'Korean / 한국어',
    nl: 'Dutch / Nederlands',
    pl: 'Polish / Polski',
    pt: 'Portuguese / Português',
    ru: 'Russian / Русский',
    tr: 'Turkish / Türkçe',
    uk: 'Ukrainian / Українська',
    vi: 'Vietnamese / Tiếng Việt',
    zh: 'Chinese / 中文'
  };

  window.gtranslateSettings = {
    default_language: 'en',
    native_language_names: true,
    detect_browser_language: false,
    languages: Object.keys(languageNames),
    wrapper_selector: '.gtranslate_wrapper',
    flag_size: 24,
    horizontal_position: 'right',
    vertical_position: 'bottom'
  };

  function updateSelector() {
    const select = document.querySelector('.gtranslate_wrapper select');
    if (!select || select.dataset.datPrepared === 'true') return;
    const options = Array.from(select.options);
    options.forEach(function (option) {
      const code = (option.value || '').split('|').pop().toLowerCase();
      if (languageNames[code]) option.textContent = languageNames[code];
    });
    options.sort(function (left, right) {
      return left.textContent.localeCompare(right.textContent, 'en');
    });
    options.forEach(function (option) { select.appendChild(option); });
    select.dataset.datPrepared = 'true';
    select.setAttribute('aria-label', 'Website language');
  }

  const observer = new MutationObserver(updateSelector);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  document.addEventListener('DOMContentLoaded', updateSelector);
})();
