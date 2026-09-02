(function () {
  "use strict";

  var languageCodeAliases = {
    iw: "he",
    jw: "jv",
    tl: "fil"
  };

  var englishNameOverrides = {
    "zh-CN": "Chinese, Simplified",
    "zh-TW": "Chinese, Traditional"
  };

  var englishLanguageNames = typeof Intl.DisplayNames === "function"
    ? new Intl.DisplayNames(["en"], { type: "language" })
    : null;

  window.gtranslateSettings = {
    default_language: "en",
    native_language_names: true,
    detect_browser_language: true,
    wrapper_selector: ".gtranslate_wrapper",
    switcher_horizontal_position: "right"
  };

  function getEnglishLanguageName(languageCode) {
    if (englishNameOverrides[languageCode]) {
      return englishNameOverrides[languageCode];
    }

    if (!englishLanguageNames) {
      return languageCode;
    }

    try {
      return englishLanguageNames.of(languageCodeAliases[languageCode] || languageCode) || languageCode;
    } catch (error) {
      return languageCode;
    }
  }

  function addBilingualLanguageLabels() {
    document.querySelectorAll(".gtranslate_wrapper a[data-gt-lang]").forEach(function (languageLink) {
      if (languageLink.dataset.bilingualLabel === "true") {
        return;
      }

      var languageCode = languageLink.dataset.gtLang;
      var nativeName = languageLink.textContent.trim();
      var englishName = getEnglishLanguageName(languageCode);
      var label = englishName.toLocaleLowerCase("en") === nativeName.toLocaleLowerCase("en")
        ? englishName
        : englishName + " (" + nativeName + ")";
      var flagImage = languageLink.querySelector("img");

      languageLink.dataset.bilingualLabel = "true";
      languageLink.setAttribute("aria-label", label);
      languageLink.replaceChildren(
        flagImage ? flagImage.cloneNode(true) : document.createTextNode(""),
        document.createTextNode(label)
      );
    });

    document.querySelectorAll(".gtranslate_wrapper .gt_options").forEach(function (languageList) {
      var currentOrder = Array.from(languageList.children).filter(function (item) {
        return item.matches("a[data-gt-lang]");
      });
      var alphabeticalOrder = currentOrder.slice().sort(function (firstLanguage, secondLanguage) {
        return firstLanguage.textContent.trim().localeCompare(secondLanguage.textContent.trim(), "en");
      });
      var orderChanged = alphabeticalOrder.some(function (languageLink, index) {
        return languageLink !== currentOrder[index];
      });

      if (orderChanged) {
        alphabeticalOrder.forEach(function (languageLink) {
          languageList.appendChild(languageLink);
        });
      }
    });
  }

  window.addEventListener("load", function () {
    var wrapper = document.querySelector(".gtranslate_wrapper");

    if (!wrapper) {
      return;
    }

    new MutationObserver(addBilingualLanguageLabels).observe(wrapper, {
      childList: true,
      subtree: true
    });

    addBilingualLanguageLabels();
  });
}());
