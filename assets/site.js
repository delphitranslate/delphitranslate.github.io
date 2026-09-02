(function () {
  "use strict";

  const menuButton = document.querySelector(".menu-button");
  const navigation = document.querySelector(".site-nav");

  if (!menuButton || !navigation) {
    return;
  }

  function closeMenu() {
    navigation.classList.remove("open");
    menuButton.setAttribute("aria-expanded", "false");
  }

  menuButton.addEventListener("click", function () {
    const shouldOpen = !navigation.classList.contains("open");
    navigation.classList.toggle("open", shouldOpen);
    menuButton.setAttribute("aria-expanded", String(shouldOpen));
  });

  navigation.addEventListener("click", function (event) {
    if (event.target.closest("a")) {
      closeMenu();
    }
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      closeMenu();
    }
  });

  window.addEventListener("resize", function () {
    if (window.innerWidth > 820) {
      closeMenu();
    }
  });
})();
