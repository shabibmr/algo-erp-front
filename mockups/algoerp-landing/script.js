/**
 * algoERP — Today’s Desk dashboard mockup
 * Light theme interactions: nav, reveals, notes, CTAs
 */

(() => {
  const reduceMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)",
  ).matches;

  /* Sticky island topbar state */
  const island = document.querySelector(".island");
  const onScroll = () => {
    island?.classList.toggle("is-scrolled", window.scrollY > 12);
  };
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* Mobile menu */
  const burger = document.getElementById("burger");
  const overlay = document.getElementById("mobile-menu");
  const menuLinks = overlay ? [...overlay.querySelectorAll(".menu-link")] : [];

  const setMenu = (open) => {
    if (!burger || !overlay) return;
    burger.classList.toggle("is-open", open);
    burger.setAttribute("aria-expanded", String(open));
    burger.setAttribute("aria-label", open ? "Close menu" : "Open menu");
    overlay.classList.toggle("is-open", open);
    if (open) {
      overlay.removeAttribute("hidden");
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
      window.setTimeout(() => {
        if (!overlay.classList.contains("is-open")) {
          overlay.setAttribute("hidden", "");
        }
      }, 550);
    }
  };

  burger?.addEventListener("click", () => {
    setMenu(!burger.classList.contains("is-open"));
  });
  menuLinks.forEach((l) => l.addEventListener("click", () => setMenu(false)));
  window.addEventListener("keydown", (e) => {
    if (e.key === "Escape") setMenu(false);
  });

  /* Scroll reveals */
  const reveals = [...document.querySelectorAll(".reveal")];
  if (reduceMotion) {
    reveals.forEach((el) => el.classList.add("is-in"));
  } else if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const delay = el.getAttribute("data-delay");
          if (delay) el.style.setProperty("--delay", `${delay}ms`);
          el.classList.add("is-in");
          io.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -6% 0px", threshold: 0.08 },
    );
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("is-in"));
  }

  /* Stagger sticky notes after needs panel enters */
  if (!reduceMotion) {
    const notes = [...document.querySelectorAll(".note")];
    notes.forEach((note, i) => {
      note.style.opacity = "0";
      note.style.transition = `opacity 0.7s cubic-bezier(0.32, 0.72, 0, 1), transform 0.7s cubic-bezier(0.32, 0.72, 0, 1)`;
      const base = getComputedStyle(note).getPropertyValue("--r") || "0deg";
      note.style.transform = `translateY(14px) rotate(${base})`;
      window.setTimeout(
        () => {
          note.style.opacity = "1";
          note.style.transform = `translateY(0) rotate(${base})`;
        },
        520 + i * 100,
      );
    });
  }

  /* Magnetic primary buttons */
  if (!reduceMotion) {
    document.querySelectorAll("[data-magnetic]").forEach((el) => {
      const strength = 8;
      el.addEventListener("pointermove", (e) => {
        const r = el.getBoundingClientRect();
        const x = e.clientX - r.left - r.width / 2;
        const y = e.clientY - r.top - r.height / 2;
        el.style.transform = `translate3d(${(x / r.width) * strength}px, ${(y / r.height) * strength}px, 0)`;
      });
      el.addEventListener("pointerleave", () => {
        el.style.transition = "transform 0.55s cubic-bezier(0.32, 0.72, 0, 1)";
        el.style.transform = "";
        window.setTimeout(() => {
          el.style.transition = "";
        }, 560);
      });
    });
  }

  /* Demo toast for mini actions */
  const toast = document.getElementById("toast");
  let toastTimer;
  const showToast = (msg) => {
    if (!toast) return;
    toast.textContent = msg;
    toast.hidden = false;
    void toast.offsetWidth;
    toast.classList.add("is-on");
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => {
      toast.classList.remove("is-on");
      window.setTimeout(() => {
        toast.hidden = true;
      }, 480);
    }, 2200);
  };

  document.querySelectorAll(".mini-btn, .btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      const href = btn.getAttribute("href");
      if (href === "#" || btn.tagName === "BUTTON") {
        e.preventDefault();
        const label =
          btn.querySelector("span")?.textContent?.trim() || "Action";
        showToast(`${label} — mock only.`);
      }
    });
  });

  /* Active nav mock */
  document.querySelectorAll(".nav-item").forEach((item) => {
    item.addEventListener("click", (e) => {
      e.preventDefault();
      document
        .querySelectorAll(".nav-item")
        .forEach((n) => n.classList.remove("is-active"));
      item.classList.add("is-active");
    });
  });
})();
