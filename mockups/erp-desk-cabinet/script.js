/**
 * algoERP desk — Cabinet (Launchpad) + Spotlight
 * No persistent navbar / sidebar.
 */

(() => {
  const reduceMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)",
  ).matches;

  const cabinet = document.getElementById("cabinet");
  const spotlight = document.getElementById("spotlight");
  const cabinetFilter = document.getElementById("cabinet-filter");
  const spotlightInput = document.getElementById("spotlight-input");
  const toast = document.getElementById("toast");
  let toastTimer;
  let activeFolder = "all";

  const isOpen = (el) => el?.classList.contains("is-open");

  const setOverlay = (el, open) => {
    if (!el) return;
    if (open) {
      el.hidden = false;
      // reflow for transition
      void el.offsetWidth;
      el.classList.add("is-open");
      document.body.classList.add("is-overlay-open");
      if (el === cabinet) {
        refreshTiles();
        window.setTimeout(() => cabinetFilter?.focus(), 80);
      }
      if (el === spotlight) {
        window.setTimeout(() => spotlightInput?.focus(), 80);
      }
    } else {
      el.classList.remove("is-open");
      window.setTimeout(() => {
        if (!isOpen(el)) el.hidden = true;
        if (!isOpen(cabinet) && !isOpen(spotlight)) {
          document.body.classList.remove("is-overlay-open");
        }
      }, 480);
    }
  };

  const closeAll = () => {
    setOverlay(cabinet, false);
    setOverlay(spotlight, false);
  };

  const openCabinet = () => {
    setOverlay(spotlight, false);
    setOverlay(cabinet, true);
  };

  const openSpotlight = () => {
    setOverlay(cabinet, false);
    setOverlay(spotlight, true);
  };

  /* Seal + buttons */
  document.getElementById("seal")?.addEventListener("click", openCabinet);
  document.getElementById("open-cabinet-btn")?.addEventListener("click", openCabinet);

  document.querySelectorAll("[data-open-spotlight]").forEach((el) => {
    el.addEventListener("click", (e) => {
      e.preventDefault();
      openSpotlight();
    });
  });

  document.querySelectorAll("[data-close]").forEach((el) => {
    el.addEventListener("click", () => {
      const id = el.getAttribute("data-close");
      if (id === "cabinet") setOverlay(cabinet, false);
      if (id === "spotlight") setOverlay(spotlight, false);
    });
  });

  /* Keyboard */
  window.addEventListener("keydown", (e) => {
    const meta = e.metaKey || e.ctrlKey;
    if (meta && e.key.toLowerCase() === "k") {
      e.preventDefault();
      if (isOpen(spotlight)) setOverlay(spotlight, false);
      else openSpotlight();
      return;
    }
    // Optional: Ctrl/Cmd+L style for cabinet — use period
    if (meta && e.key === ".") {
      e.preventDefault();
      if (isOpen(cabinet)) setOverlay(cabinet, false);
      else openCabinet();
      return;
    }
    if (e.key === "Escape") closeAll();
  });

  /* Cabinet filter + folders */
  const tiles = [...document.querySelectorAll(".mod-tile")];

  const refreshTiles = () => {
    const q = (cabinetFilter?.value || "").trim().toLowerCase();
    tiles.forEach((tile, i) => {
      const folder = tile.getAttribute("data-folder") || "";
      const name = tile.getAttribute("data-name") || "";
      const folderOk = activeFolder === "all" || folder === activeFolder;
      const textOk = !q || name.includes(q) || folder.includes(q);
      const show = folderOk && textOk;
      tile.classList.toggle("is-hidden", !show);
      tile.style.setProperty("--i", String(i % 12));
      if (show) {
        // re-trigger stagger when opening
        tile.classList.remove("is-visible");
        void tile.offsetWidth;
        if (reduceMotion || isOpen(cabinet)) {
          requestAnimationFrame(() => tile.classList.add("is-visible"));
        }
      } else {
        tile.classList.remove("is-visible");
      }
    });
  };

  cabinetFilter?.addEventListener("input", refreshTiles);

  document.querySelectorAll(".folder").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".folder").forEach((f) => {
        f.classList.remove("is-on");
        f.setAttribute("aria-selected", "false");
      });
      btn.classList.add("is-on");
      btn.setAttribute("aria-selected", "true");
      activeFolder = btn.getAttribute("data-folder") || "all";
      refreshTiles();
    });
  });

  tiles.forEach((tile) => {
    tile.addEventListener("click", () => {
      const name =
        tile.querySelector(".mod-name")?.textContent?.trim() || "Module";
      setOverlay(cabinet, false);
      showToast(`Open ${name} — mock only.`);
    });
  });

  /* Spotlight filter */
  const spotRows = [...document.querySelectorAll(".spot-row")];
  const filterSpotlight = () => {
    const q = (spotlightInput?.value || "").trim().toLowerCase();
    let any = false;
    spotRows.forEach((row) => {
      const text = row.textContent?.toLowerCase() || "";
      const show = !q || text.includes(q);
      row.style.display = show ? "" : "none";
      if (show) any = true;
    });
    document.querySelectorAll(".spot-group").forEach((g) => {
      let el = g.nextElementSibling;
      let visible = false;
      while (el && !el.classList.contains("spot-group")) {
        if (el.classList.contains("spot-row") && el.style.display !== "none") {
          visible = true;
        }
        el = el.nextElementSibling;
      }
      g.style.display = visible || !q ? "" : "none";
      if (!q) g.style.display = "";
    });
    void any;
  };

  spotlightInput?.addEventListener("input", filterSpotlight);

  /* Toasts */
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

  document.querySelectorAll("[data-toast]").forEach((el) => {
    el.addEventListener("click", (e) => {
      e.preventDefault();
      showToast(`${el.getAttribute("data-toast")} — mock only.`);
      if (isOpen(spotlight)) setOverlay(spotlight, false);
    });
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

  /* Note stagger */
  if (!reduceMotion) {
    document.querySelectorAll(".note").forEach((note, i) => {
      note.style.opacity = "0";
      note.style.transition = `opacity 0.7s cubic-bezier(0.32, 0.72, 0, 1), transform 0.7s cubic-bezier(0.32, 0.72, 0, 1)`;
      const base = getComputedStyle(note).getPropertyValue("--r") || "0deg";
      note.style.transform = `translateY(14px) rotate(${base})`;
      window.setTimeout(
        () => {
          note.style.opacity = "1";
          note.style.transform = `translateY(0) rotate(${base})`;
        },
        480 + i * 100,
      );
    });
  }

  /* Magnetic buttons */
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

  refreshTiles();
})();
