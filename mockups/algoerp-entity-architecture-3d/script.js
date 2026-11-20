/**
 * algoERP — Standard Entity Architecture (5-View)
 * Ambient Three.js scene + GSAP camera · Anime view transitions · wired chrome
 */

(() => {
  'use strict';

  const EASE_CSS = 'cubic-bezier(0.32, 0.72, 0, 1)';
  const EASE_GSAP = 'power3.out';
  const EASE_ANIME_OUT = 'cubicBezier(0.32, 0.72, 0, 1)';
  const EASE_ANIME_IN = 'cubicBezier(0.16, 1, 0.3, 1)';

  // ── WebGL detection ──────────────────────────────────────────────────
  function isWebGLAvailable() {
    try {
      const c = document.createElement('canvas');
      return !!(window.WebGLRenderingContext && (c.getContext('webgl') || c.getContext('experimental-webgl')));
    } catch {
      return false;
    }
  }

  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent) || window.innerWidth < 768;

  const loaderScreen = document.getElementById('loader');
  const loaderBar = document.getElementById('loader-bar');
  const loaderPercent = document.getElementById('loader-percent');
  const cabinetOverlay = document.getElementById('cabinet-overlay');
  const spotlightOverlay = document.getElementById('spotlight-overlay');
  const toast = document.getElementById('toast');
  const tooltip3D = document.getElementById('tooltip-3d');
  const tooltipCategory = document.getElementById('tooltip-category');
  const tooltipTitle = document.getElementById('tooltip-title');
  const tooltipVal = document.getElementById('tooltip-val');
  const tooltipTag = document.getElementById('tooltip-tag');

  // ── Loader (scaleX, GPU-safe) ────────────────────────────────────────
  let progress = 0;
  const loadInterval = setInterval(() => {
    progress = Math.min(100, progress + Math.floor(Math.random() * 18) + 10);
    if (loaderBar) loaderBar.style.transform = `scaleX(${progress / 100})`;
    if (loaderPercent) loaderPercent.textContent = `${progress}%`;
    if (progress >= 100) {
      clearInterval(loadInterval);
      setTimeout(() => {
        loaderScreen?.classList.add('is-done');
        revealInView();
      }, 280);
    }
  }, 55);

  // ── Toast ────────────────────────────────────────────────────────────
  let toastTimer;
  function showToast(msg) {
    if (!toast) return;
    toast.textContent = msg;
    toast.hidden = false;
    void toast.offsetWidth;
    toast.classList.add('is-on');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toast.classList.remove('is-on');
      setTimeout(() => {
        toast.hidden = true;
      }, 320);
    }, 2400);
  }

  // ── Reveal on enter ──────────────────────────────────────────────────
  function revealInView() {
    const section = document.querySelector('.entity-view-section:not([hidden])');
    if (!section) return;
    section.querySelectorAll('.reveal').forEach((el, i) => {
      el.classList.remove('is-in');
      requestAnimationFrame(() => {
        setTimeout(() => el.classList.add('is-in'), 40 + i * 70);
      });
    });
  }

  // ── Record catalog (list → record deep link) ─────────────────────────
  const RECORDS = {
    'INV/2408': {
      customer: 'Desert Motors LLC',
      branch: 'Dubai HQ',
      amount: 'AED 14,280.00',
      status: 'Approved',
      aging: '0–30 days',
      pay: 'Unpaid · overdue watch',
      lines: [
        ['Heavy Duty Brake Pad Set · SKU-4401', '10', 'AED 820.00', 'AED 8,200.00'],
        ['Synthetic Engine Oil 5L · SKU-1102', '20', 'AED 304.00', 'AED 6,080.00'],
      ],
    },
    'INV/2409': {
      customer: 'Gulf Spares LLC',
      branch: 'Riyadh Hub',
      amount: 'AED 42,100.00',
      status: 'Pending Seal',
      aging: '0–30 days',
      pay: 'Unpaid',
      lines: [
        ['Turbo Compressor Unit · SKU-8801', '2', 'AED 12,500.00', 'AED 25,000.00'],
        ['Filter Kit Premium · SKU-2204', '18', 'AED 950.00', 'AED 17,100.00'],
      ],
    },
    'INV/2410': {
      customer: 'Al Bustan Catering',
      branch: 'London Branch',
      amount: 'AED 8,950.00',
      status: 'Posted',
      aging: '—',
      pay: 'Settled',
      lines: [
        ['Catering Service Pack · SKU-C12', '1', 'AED 8,950.00', 'AED 8,950.00'],
      ],
    },
    'INV/2411': {
      customer: 'Oasis Retail Group',
      branch: 'Dubai HQ',
      amount: 'AED 22,150.00',
      status: 'Draft',
      aging: '—',
      pay: 'Draft',
      lines: [
        ['POS Terminal Kit · SKU-901', '5', 'AED 3,100.00', 'AED 15,500.00'],
        ['Receipt Roll Case · SKU-112', '50', 'AED 133.00', 'AED 6,650.00'],
      ],
    },
    'INV/2412': {
      customer: 'Pearl Marine Co',
      branch: 'Riyadh Hub',
      amount: 'AED 6,750.00',
      status: 'Approved',
      aging: '31–60 days',
      pay: 'Partial',
      lines: [
        ['Marine Sealant 20L · SKU-M44', '15', 'AED 450.00', 'AED 6,750.00'],
      ],
    },
    'INV/2413': {
      customer: 'Desert Motors LLC',
      branch: 'Dubai HQ',
      amount: 'AED 9,800.00',
      status: 'Pending Seal',
      aging: '0–30 days',
      pay: 'Unpaid',
      lines: [
        ['Clutch Assembly · SKU-3310', '4', 'AED 2,450.00', 'AED 9,800.00'],
      ],
    },
  };

  function openRecord(inv) {
    const rec = RECORDS[inv] || RECORDS['INV/2408'];
    const invNo = RECORDS[inv] ? inv : 'INV/2408';

    const set = (id, text) => {
      const el = document.getElementById(id);
      if (el) el.textContent = text;
    };

    set('rec-header-inv', invNo);
    set('rec-title-inv', `${invNo} · ${rec.customer}`);
    set('rec-lede', `Issued by ${rec.branch} · Net payable ${rec.amount}`);
    set('rec-balance', rec.amount);
    set('rec-aging', rec.aging);
    set('rec-pay', rec.pay);
    set('rec-branch', rec.branch);
    set('rec-status-badge', rec.status);

    const steps = document.querySelectorAll('#view-record .status-step');
    const order = ['Draft', 'Pending Seal', 'Approved', 'Posted'];
    const idx = Math.max(0, order.indexOf(rec.status));
    steps.forEach((step, i) => {
      step.classList.remove('is-done', 'is-current');
      if (i < idx) step.classList.add('is-done');
      else if (i === idx) step.classList.add('is-current');
    });

    const tbody = document.getElementById('rec-lines-body');
    if (tbody) {
      tbody.innerHTML = rec.lines
        .map(
          ([item, qty, price, total]) =>
            `<tr><td>${item}</td><td class="money">${qty}</td><td class="money">${price}</td><td class="money">${total}</td></tr>`
        )
        .join('');
    }

    switchEntityView('record');
  }

  // ── View switching ───────────────────────────────────────────────────
  let currentViewId = 'hub';
  let camera = null;
  let cameraTarget = null;
  const cameraPresets = {
    hub: { pos: { x: 0.0, y: 4.5, z: 9.0 }, target: { x: 0, y: 0, z: 0 } },
    list: { pos: { x: -2.8, y: 3.5, z: 6.8 }, target: { x: -1.5, y: 0, z: 0 } },
    record: { pos: { x: 0.0, y: 2.2, z: 4.5 }, target: { x: 0, y: 0.2, z: 0 } },
    editor: { pos: { x: 0.0, y: 5.8, z: 3.4 }, target: { x: 0, y: -0.1, z: 0 } },
    reports: { pos: { x: 3.5, y: 4.8, z: 7.5 }, target: { x: 1.5, y: 0, z: 0 } },
  };

  let recordGroup = null;

  function switchEntityView(viewId) {
    if (!cameraPresets[viewId]) return;
    if (viewId === currentViewId) {
      revealInView();
      return;
    }

    const prev = currentViewId;
    currentViewId = viewId;

    document.querySelectorAll('.view-tab').forEach((tab) => {
      const on = tab.getAttribute('data-view') === viewId;
      tab.classList.toggle('is-active', on);
      tab.setAttribute('aria-selected', on ? 'true' : 'false');
    });

    if (camera && typeof gsap !== 'undefined') {
      const preset = cameraPresets[viewId];
      gsap.to(camera.position, {
        x: preset.pos.x,
        y: preset.pos.y,
        z: preset.pos.z,
        duration: 1.15,
        ease: EASE_GSAP,
      });
      gsap.to(cameraTarget, {
        x: preset.target.x,
        y: preset.target.y,
        z: preset.target.z,
        duration: 1.15,
        ease: EASE_GSAP,
      });
    }

    const oldSection = document.getElementById(`view-${prev}`);
    const newSection = document.getElementById(`view-${viewId}`);

    const finish = () => {
      if (oldSection) oldSection.hidden = true;
      if (newSection) {
        newSection.hidden = false;
        newSection.style.opacity = '0';
        newSection.style.transform = 'translateY(16px)';
        if (typeof anime !== 'undefined') {
          anime({
            targets: newSection,
            opacity: [0, 1],
            translateY: [16, 0],
            duration: 520,
            easing: EASE_ANIME_IN,
            complete: () => {
              newSection.style.opacity = '';
              newSection.style.transform = '';
              revealInView();
            },
          });
        } else {
          newSection.style.opacity = '';
          newSection.style.transform = '';
          revealInView();
        }
      }
    };

    if (oldSection && typeof anime !== 'undefined') {
      anime({
        targets: oldSection,
        opacity: [1, 0],
        translateY: [0, -12],
        duration: 240,
        easing: EASE_ANIME_OUT,
        complete: finish,
      });
    } else {
      finish();
    }

    showToast(`View · ${viewId.charAt(0).toUpperCase()}${viewId.slice(1)}`);
  }

  document.querySelectorAll('.view-tab').forEach((tab) => {
    tab.addEventListener('click', () => switchEntityView(tab.getAttribute('data-view')));
  });

  document.getElementById('btn-go-list')?.addEventListener('click', () => switchEntityView('list'));
  document.getElementById('btn-create-invoice')?.addEventListener('click', () => switchEntityView('editor'));
  document.getElementById('btn-list-new')?.addEventListener('click', () => switchEntityView('editor'));
  document.getElementById('btn-cancel-editor')?.addEventListener('click', () => switchEntityView('list'));
  document.getElementById('btn-edit-record')?.addEventListener('click', () => switchEntityView('editor'));

  document.querySelectorAll('[data-goto]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const goto = btn.getAttribute('data-goto');
      const inv = btn.getAttribute('data-inv');
      if (goto === 'record' && inv) openRecord(inv);
      else if (goto) switchEntityView(goto);
    });
  });

  document.querySelectorAll('.table-row-item, .inspect-btn').forEach((el) => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      const row = el.closest('[data-inv]') || el;
      const inv = row.getAttribute('data-inv');
      if (inv) openRecord(inv);
    });
  });

  // ── List filter ──────────────────────────────────────────────────────
  let listStatus = 'all';

  function applyListFilter() {
    const q = (document.getElementById('list-search')?.value || '').trim().toLowerCase();
    const rows = document.querySelectorAll('#entity-table-body .table-row-item');
    let visible = 0;
    rows.forEach((row) => {
      const blob = [
        row.getAttribute('data-inv'),
        row.getAttribute('data-customer'),
        row.getAttribute('data-branch'),
        row.getAttribute('data-status'),
      ]
        .join(' ')
        .toLowerCase();
      const statusOk = listStatus === 'all' || row.getAttribute('data-status') === listStatus;
      const textOk = !q || blob.includes(q);
      const show = statusOk && textOk;
      row.hidden = !show;
      if (show) visible += 1;
    });
    const meta = document.getElementById('list-visible-meta');
    if (meta) meta.textContent = `Showing ${visible} of 48 · filtered`;
  }

  document.getElementById('list-search')?.addEventListener('input', applyListFilter);
  document.querySelectorAll('.filter-pill').forEach((pill) => {
    pill.addEventListener('click', () => {
      document.querySelectorAll('.filter-pill').forEach((p) => p.classList.remove('is-active'));
      pill.classList.add('is-active');
      listStatus = pill.getAttribute('data-status') || 'all';
      applyListFilter();
    });
  });

  document.getElementById('btn-bulk-export')?.addEventListener('click', () => showToast('CSV export queued'));
  document.getElementById('btn-bulk-print')?.addEventListener('click', () => showToast('Print dialog (mock)'));
  document.getElementById('btn-export-csv')?.addEventListener('click', () => showToast('Aging report exported'));
  document.getElementById('btn-attach')?.addEventListener('click', () => showToast('Attachment picker (mock)'));

  // ── Editor line totals ───────────────────────────────────────────────
  function formatAed(n) {
    return `AED ${n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  }

  function recalcEditorLines() {
    let subtotal = 0;
    let taxTotal = 0;
    document.querySelectorAll('#editor-lines-body .editor-line').forEach((row) => {
      const qty = parseFloat(row.querySelector('.line-qty')?.value) || 0;
      const price = parseFloat(row.querySelector('.line-price')?.value) || 0;
      const taxPct = parseFloat(row.querySelector('.line-tax')?.value) || 0;
      const base = qty * price;
      const tax = base * (taxPct / 100);
      subtotal += base;
      taxTotal += tax;
      const cell = row.querySelector('.line-amount');
      if (cell) cell.textContent = formatAed(base + tax);
    });
    const set = (id, v) => {
      const el = document.getElementById(id);
      if (el) el.textContent = formatAed(v);
    };
    set('edit-subtotal', subtotal);
    set('edit-tax', taxTotal);
    set('edit-grand', subtotal + taxTotal);
  }

  function wireLineRow(row) {
    row.querySelectorAll('input').forEach((input) => {
      input.addEventListener('input', recalcEditorLines);
    });
    row.querySelector('.line-remove')?.addEventListener('click', () => {
      if (document.querySelectorAll('#editor-lines-body .editor-line').length <= 1) {
        showToast('Keep at least one line');
        return;
      }
      row.remove();
      recalcEditorLines();
    });
  }

  document.querySelectorAll('#editor-lines-body .editor-line').forEach(wireLineRow);
  recalcEditorLines();

  document.getElementById('btn-add-line')?.addEventListener('click', () => {
    const tbody = document.getElementById('editor-lines-body');
    if (!tbody) return;
    const tr = document.createElement('tr');
    tr.className = 'editor-line';
    tr.innerHTML = `
      <td><input type="text" class="line-desc" value="New line item" /></td>
      <td><input type="number" class="line-qty" value="1" min="0" step="1" /></td>
      <td><input type="number" class="line-price" value="0" min="0" step="0.01" /></td>
      <td><input type="number" class="line-tax" value="5" min="0" step="0.01" /></td>
      <td class="money-cell line-amount">AED 0.00</td>
      <td><button type="button" class="line-remove" aria-label="Remove line">×</button></td>
    `;
    tbody.appendChild(tr);
    wireLineRow(tr);
    recalcEditorLines();
  });

  document.getElementById('entity-editor-form')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const invNo = document.getElementById('edit-inv-no')?.value || 'INV/2414';
    if (recordGroup && typeof gsap !== 'undefined') {
      gsap
        .timeline()
        .to(recordGroup.position, { y: -0.15, duration: 0.28, ease: 'power3.in' })
        .to(recordGroup.position, { y: 0.5, duration: 0.55, ease: 'elastic.out(1, 0.45)' });
    }
    showToast(`Saved & sealed ${invNo}`);
    setTimeout(() => {
      openRecord('INV/2409');
    }, 700);
  });

  document.getElementById('btn-seal-this-record')?.addEventListener('click', () => {
    if (recordGroup && typeof gsap !== 'undefined') {
      gsap
        .timeline()
        .to(recordGroup.position, { y: -0.15, duration: 0.28, ease: 'power3.in' })
        .to(recordGroup.position, { y: 0.5, duration: 0.55, ease: 'elastic.out(1, 0.45)' });
    }
    showToast('Official brass seal applied');
  });

  // ── Reports picker ───────────────────────────────────────────────────
  const REPORT_DATA = {
    aging: {
      title: 'Receivables aging breakdown',
      bars: [
        { h: '88%', label: '0–30<br />62%' },
        { h: '48%', label: '31–60<br />22%' },
        { h: '28%', label: '61–90<br />11%' },
        { h: '16%', label: '90+<br />5%' },
      ],
      rows: [
        ['0–30 days', 'AED 880,900.00', '62%', '31'],
        ['31–60 days', 'AED 312,600.00', '22%', '9'],
        ['61–90 days', 'AED 156,300.00', '11%', '5'],
        ['90+ days', 'AED 71,050.00', '5%', '3'],
      ],
    },
    branch: {
      title: 'Volume by branch',
      bars: [
        { h: '92%', label: 'Dubai<br />58%' },
        { h: '52%', label: 'Riyadh<br />28%' },
        { h: '30%', label: 'London<br />14%' },
        { h: '8%', label: 'Other<br />—' },
      ],
      rows: [
        ['Dubai HQ', 'AED 824,100.00', '58%', '28'],
        ['Riyadh Hub', 'AED 397,800.00', '28%', '12'],
        ['London Branch', 'AED 198,950.00', '14%', '8'],
      ],
    },
    customer: {
      title: 'Top open balances',
      bars: [
        { h: '80%', label: 'Gulf<br />Sp.' },
        { h: '55%', label: 'Desert<br />Mot.' },
        { h: '35%', label: 'Oasis' },
        { h: '22%', label: 'Pearl' },
      ],
      rows: [
        ['Gulf Spares LLC', 'AED 42,100.00', '—', '2'],
        ['Desert Motors LLC', 'AED 24,080.00', '—', '2'],
        ['Oasis Retail Group', 'AED 22,150.00', '—', '1'],
        ['Pearl Marine Co', 'AED 6,750.00', '—', '1'],
      ],
    },
    series: {
      title: 'Voucher series mix',
      bars: [
        { h: '70%', label: 'Posted<br />61%' },
        { h: '40%', label: 'Appr.<br />22%' },
        { h: '28%', label: 'Seal<br />12%' },
        { h: '14%', label: 'Draft<br />5%' },
      ],
      rows: [
        ['Posted', 'AED 867,000.00', '61%', '29'],
        ['Approved', 'AED 312,400.00', '22%', '11'],
        ['Pending Seal', 'AED 170,500.00', '12%', '5'],
        ['Draft', 'AED 70,950.00', '5%', '3'],
      ],
    },
  };

  function renderReport(key) {
    const data = REPORT_DATA[key] || REPORT_DATA.aging;
    const title = document.getElementById('report-chart-title');
    if (title) title.textContent = data.title;
    const bars = document.getElementById('report-bars');
    if (bars) {
      bars.innerHTML = data.bars
        .map((b) => `<span style="--height: ${b.h}"><label>${b.label}</label></span>`)
        .join('');
    }
    const body = document.getElementById('report-detail-body');
    if (body) {
      body.innerHTML = data.rows
        .map(
          ([a, b, c, d]) =>
            `<tr><td>${a}</td><td class="money">${b}</td><td class="money">${c}</td><td class="money">${d}</td></tr>`
        )
        .join('');
    }
  }

  document.querySelectorAll('.report-card').forEach((card) => {
    card.addEventListener('click', () => {
      document.querySelectorAll('.report-card').forEach((c) => c.classList.remove('is-active'));
      card.classList.add('is-active');
      renderReport(card.getAttribute('data-report'));
    });
  });

  // ── Theme toggle ─────────────────────────────────────────────────────
  const themeBtn = document.getElementById('btn-theme-toggle');
  const iconSun = document.getElementById('theme-icon-sun');
  const iconMoon = document.getElementById('theme-icon-moon');

  function setNight(on) {
    document.body.classList.toggle('is-night', on);
    if (iconSun) iconSun.hidden = on;
    if (iconMoon) iconMoon.hidden = !on;
    if (window.__algoScene) {
      window.__algoScene.background = new THREE.Color(on ? 0x12171f : 0xf1ede6);
      window.__algoScene.fog = new THREE.FogExp2(on ? 0x12171f : 0xf1ede6, 0.022);
    }
  }

  themeBtn?.addEventListener('click', () => {
    setNight(!document.body.classList.contains('is-night'));
    showToast(document.body.classList.contains('is-night') ? 'Desk lamp · night' : 'Desk lamp · morning');
  });

  // ── Overlays ─────────────────────────────────────────────────────────
  function openOverlay(overlayEl) {
    if (!overlayEl) return;
    overlayEl.hidden = false;
    document.body.style.overflow = 'hidden';
    const scrim = overlayEl.querySelector('.overlay-scrim');
    const panel = overlayEl.querySelector('.cabinet-stage, .spotlight-panel');
    if (typeof anime !== 'undefined') {
      if (scrim) {
        anime({ targets: scrim, opacity: [0, 1], duration: 380, easing: EASE_ANIME_OUT });
      }
      if (panel) {
        anime({
          targets: panel,
          scale: [0.92, 1],
          opacity: [0, 1],
          translateY: [24, 0],
          duration: 520,
          easing: EASE_ANIME_IN,
        });
      }
      if (overlayEl === cabinetOverlay) {
        anime({
          targets: overlayEl.querySelectorAll('.mod-tile'),
          opacity: [0, 1],
          translateY: [18, 0],
          delay: anime.stagger(60, { start: 120 }),
          duration: 480,
          easing: EASE_ANIME_IN,
        });
      }
    }
    if (overlayEl === spotlightOverlay) {
      renderSpotlight('');
      setTimeout(() => document.getElementById('spotlight-input')?.focus(), 80);
    }
  }

  function closeOverlays() {
    [cabinetOverlay, spotlightOverlay].forEach((overlayEl) => {
      if (!overlayEl || overlayEl.hidden) return;
      if (typeof anime !== 'undefined') {
        anime({
          targets: overlayEl.querySelectorAll('.overlay-scrim, .cabinet-stage, .spotlight-panel'),
          opacity: 0,
          scale: 0.96,
          duration: 280,
          easing: EASE_ANIME_OUT,
          complete: () => {
            overlayEl.hidden = true;
            document.body.style.overflow = '';
          },
        });
      } else {
        overlayEl.hidden = true;
        document.body.style.overflow = '';
      }
    });
  }

  document.getElementById('seal-btn')?.addEventListener('click', () => openOverlay(cabinetOverlay));
  document.getElementById('close-cabinet-btn')?.addEventListener('click', closeOverlays);
  document.getElementById('close-cabinet-scrim')?.addEventListener('click', closeOverlays);
  document.getElementById('spotlight-trigger')?.addEventListener('click', () => openOverlay(spotlightOverlay));
  document.getElementById('close-spotlight-scrim')?.addEventListener('click', closeOverlays);

  document.querySelectorAll('.mod-tile').forEach((tile) => {
    tile.addEventListener('click', () => {
      const name = tile.getAttribute('data-name') || 'module';
      closeOverlays();
      showToast(`Opened ${name}`);
      if (name === 'sales invoice') switchEntityView('hub');
    });
  });

  // ── Spotlight commands ───────────────────────────────────────────────
  const COMMANDS = [
    { id: 'hub', label: 'Go to Hub Dashboard', hint: '⌘1', run: () => switchEntityView('hub') },
    { id: 'list', label: 'Go to Entity List', hint: '⌘2', run: () => switchEntityView('list') },
    { id: 'record', label: 'Go to Record Overview', hint: '⌘3', run: () => switchEntityView('record') },
    { id: 'editor', label: 'Go to Entity Editor', hint: '⌘4', run: () => switchEntityView('editor') },
    { id: 'reports', label: 'Go to Reports', hint: '⌘5', run: () => switchEntityView('reports') },
    { id: 'new', label: 'New Sales Invoice', hint: 'Editor', run: () => switchEntityView('editor') },
    { id: 'seal', label: 'Apply seal on current record', hint: 'Record', run: () => {
      switchEntityView('record');
      setTimeout(() => document.getElementById('btn-seal-this-record')?.click(), 400);
    } },
    { id: 'cabinet', label: 'Open The Cabinet', hint: '⌘.', run: () => openOverlay(cabinetOverlay) },
    { id: 'theme', label: 'Toggle desk lighting', hint: 'Theme', run: () => themeBtn?.click() },
    { id: 'inv2409', label: 'Open INV/2409 · Gulf Spares', hint: 'Record', run: () => openRecord('INV/2409') },
    { id: 'inv2408', label: 'Open INV/2408 · Desert Motors', hint: 'Record', run: () => openRecord('INV/2408') },
  ];

  let spotlightIndex = 0;

  function renderSpotlight(query) {
    const list = document.getElementById('spotlight-results');
    if (!list) return;
    const q = (query || '').trim().toLowerCase();
    const matches = COMMANDS.filter((c) => !q || c.label.toLowerCase().includes(q) || c.id.includes(q));
    spotlightIndex = 0;
    if (!matches.length) {
      list.innerHTML = '<li class="spotlight-empty">No commands match</li>';
      return;
    }
    list.innerHTML = matches
      .map(
        (c, i) =>
          `<li><button type="button" data-cmd="${c.id}" class="${i === 0 ? 'is-active' : ''}"><span class="cmd-label">${c.label}</span><span class="cmd-hint">${c.hint}</span></button></li>`
      )
      .join('');
    list.querySelectorAll('button').forEach((btn) => {
      btn.addEventListener('click', () => {
        const cmd = COMMANDS.find((c) => c.id === btn.getAttribute('data-cmd'));
        closeOverlays();
        cmd?.run();
      });
    });
  }

  document.getElementById('spotlight-input')?.addEventListener('input', (e) => {
    renderSpotlight(e.target.value);
  });

  document.getElementById('spotlight-input')?.addEventListener('keydown', (e) => {
    const buttons = [...document.querySelectorAll('#spotlight-results button')];
    if (!buttons.length) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      spotlightIndex = (spotlightIndex + 1) % buttons.length;
      buttons.forEach((b, i) => b.classList.toggle('is-active', i === spotlightIndex));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      spotlightIndex = (spotlightIndex - 1 + buttons.length) % buttons.length;
      buttons.forEach((b, i) => b.classList.toggle('is-active', i === spotlightIndex));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      buttons[spotlightIndex]?.click();
    }
  });

  // ── Keyboard ─────────────────────────────────────────────────────────
  window.addEventListener('keydown', (e) => {
    if (e.metaKey || e.ctrlKey) {
      if (e.key === '1') {
        e.preventDefault();
        switchEntityView('hub');
      } else if (e.key === '2') {
        e.preventDefault();
        switchEntityView('list');
      } else if (e.key === '3') {
        e.preventDefault();
        switchEntityView('record');
      } else if (e.key === '4') {
        e.preventDefault();
        switchEntityView('editor');
      } else if (e.key === '5') {
        e.preventDefault();
        switchEntityView('reports');
      } else if (e.key.toLowerCase() === 'k') {
        e.preventDefault();
        if (!spotlightOverlay.hidden) closeOverlays();
        else openOverlay(spotlightOverlay);
      } else if (e.key === '.' || e.key === '>') {
        e.preventDefault();
        if (!cabinetOverlay.hidden) closeOverlays();
        else openOverlay(cabinetOverlay);
      }
    } else if (e.key === 'Escape') {
      closeOverlays();
    }
  });

  // ── Three.js ambient scene ───────────────────────────────────────────
  if (!isWebGLAvailable() || typeof THREE === 'undefined') {
    document.getElementById('webgl-fallback').style.display = 'block';
    document.getElementById('canvas-3d-wrap').style.display = 'none';
    return;
  }

  const canvas = document.getElementById('webgl-canvas');
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf1ede6);
  scene.fog = new THREE.FogExp2(0xf1ede6, 0.02);
  window.__algoScene = scene;

  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(0, 4.5, 9);
  cameraTarget = new THREE.Vector3(0, 0, 0);

  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
    powerPreference: 'high-performance',
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, isMobile ? 1.0 : 1.5));
  renderer.shadowMap.enabled = !isMobile;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  const textureLoader = new THREE.TextureLoader();
  const linenDeskTexture = textureLoader.load('./assets/linen_paper_bg.jpg', (tex) => {
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(6, 6);
  });

  // Optional luxury desk accent plane (subtle, not full-scene takeover)
  textureLoader.load('./assets/luxury_desk_bg.jpg', (tex) => {
    tex.wrapS = THREE.ClampToEdgeWrapping;
    tex.wrapT = THREE.ClampToEdgeWrapping;
    const mat = new THREE.MeshStandardMaterial({
      map: tex,
      roughness: 0.55,
      metalness: 0.25,
    });
    const accent = new THREE.Mesh(new THREE.PlaneGeometry(4.2, 2.4), mat);
    accent.rotation.x = -Math.PI / 2;
    accent.position.set(2.4, -0.48, -1.2);
    accent.receiveShadow = true;
    scene.add(accent);
  });

  scene.add(new THREE.AmbientLight(0xfffbf5, 0.85));
  const sunLight = new THREE.DirectionalLight(0xfffaed, 1.35);
  sunLight.position.set(6, 12, 6);
  sunLight.castShadow = true;
  scene.add(sunLight);

  const cursorLight = new THREE.PointLight(0xb8843b, 1.2, 10);
  scene.add(cursorLight);

  const deskPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(32, 32),
    new THREE.MeshStandardMaterial({
      map: linenDeskTexture,
      color: 0xf1ede6,
      roughness: 0.78,
      metalness: 0.08,
    })
  );
  deskPlane.rotation.x = -Math.PI / 2;
  deskPlane.position.y = -0.5;
  deskPlane.receiveShadow = true;
  scene.add(deskPlane);

  const interactiveModuleObjects = [];
  const view3DObjects = {};

  // Hub globe
  const globeGroup = new THREE.Group();
  const globeMesh = new THREE.Mesh(
    new THREE.SphereGeometry(0.9, 28, 28),
    new THREE.MeshStandardMaterial({
      color: 0x0e6b68,
      metalness: 0.45,
      roughness: 0.22,
      emissive: 0x0e6b68,
      emissiveIntensity: 0.18,
    })
  );
  globeMesh.castShadow = true;
  globeMesh.userData = {
    name: 'Topology Globe',
    category: 'Hub Dashboard',
    val: 'Branch nodes',
    tag: 'Hub active',
  };
  globeGroup.add(globeMesh);
  const ringMesh = new THREE.Mesh(
    new THREE.RingGeometry(1.05, 1.2, 48),
    new THREE.MeshBasicMaterial({ color: 0xdfb26b, side: THREE.DoubleSide, transparent: true, opacity: 0.75 })
  );
  ringMesh.rotation.x = Math.PI / 3;
  globeGroup.add(ringMesh);
  globeGroup.position.set(-2.5, 0.6, 0);
  scene.add(globeGroup);
  view3DObjects.hub = globeGroup;
  interactiveModuleObjects.push(globeMesh);

  // List stack
  const listGroup = new THREE.Group();
  for (let i = 0; i < 4; i++) {
    const stackMesh = new THREE.Mesh(
      new THREE.BoxGeometry(1.4, 0.1, 1.8),
      new THREE.MeshStandardMaterial({ color: 0x1a2330, roughness: 0.35, metalness: 0.45 })
    );
    stackMesh.position.set((i % 2) * 0.1, i * 0.12, (i % 3) * 0.05);
    stackMesh.castShadow = true;
    listGroup.add(stackMesh);
  }
  listGroup.position.set(-3.2, 0.4, -1.2);
  scene.add(listGroup);
  view3DObjects.list = listGroup;

  // Record document + brass seal
  recordGroup = new THREE.Group();
  const docMesh = new THREE.Mesh(
    new THREE.BoxGeometry(1.3, 1.7, 0.08),
    new THREE.MeshStandardMaterial({ color: 0xfbf9f6, roughness: 0.4, metalness: 0.08 })
  );
  docMesh.castShadow = true;
  docMesh.userData = {
    name: 'Sales Invoice Record',
    category: 'Record Overview',
    val: 'INV · sealable',
    tag: 'Inspector',
  };
  recordGroup.add(docMesh);
  const sealBrass = new THREE.Mesh(
    new THREE.CylinderGeometry(0.35, 0.4, 0.18, 40),
    new THREE.MeshStandardMaterial({ color: 0xb8843b, metalness: 0.9, roughness: 0.18 })
  );
  sealBrass.rotation.x = Math.PI / 2;
  sealBrass.position.set(0.35, -0.45, 0.09);
  recordGroup.add(sealBrass);
  recordGroup.position.set(0.0, 0.5, 3.0);
  scene.add(recordGroup);
  view3DObjects.record = recordGroup;
  interactiveModuleObjects.push(docMesh);

  // Editor pen
  const editorGroup = new THREE.Group();
  const penMesh = new THREE.Mesh(
    new THREE.CylinderGeometry(0.06, 0.06, 1.8, 16),
    new THREE.MeshStandardMaterial({ color: 0x8f3535, metalness: 0.8, roughness: 0.2 })
  );
  penMesh.rotation.z = Math.PI / 4;
  penMesh.castShadow = true;
  editorGroup.add(penMesh);
  editorGroup.position.set(0.0, 0.8, 1.0);
  scene.add(editorGroup);
  view3DObjects.editor = editorGroup;

  // Reports bars
  const reportsGroup = new THREE.Group();
  [0.8, 1.4, 2.0, 1.1].forEach((h, i) => {
    const barMesh = new THREE.Mesh(
      new THREE.BoxGeometry(0.35, h, 0.35),
      new THREE.MeshStandardMaterial({
        color: i === 2 ? 0xb8843b : 0x0e6b68,
        metalness: 0.5,
        roughness: 0.22,
      })
    );
    barMesh.position.set(i * 0.45 - 0.7, h / 2, 0);
    barMesh.castShadow = true;
    reportsGroup.add(barMesh);
  });
  reportsGroup.position.set(3.2, 0.3, -1.0);
  scene.add(reportsGroup);
  view3DObjects.reports = reportsGroup;

  // Raycast (opt-in: enable pointer on canvas for hover only when idle)
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2(-999, -999);
  let hoveredObj = null;

  window.addEventListener('pointermove', (e) => {
    mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
    cursorLight.position.set(mouse.x * 6, 2, -mouse.y * 4 + 2);
  });

  function checkRaycast() {
    if (!tooltip3D) return;
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveModuleObjects);
    if (intersects.length > 0) {
      const hitObj = intersects[0].object;
      if (hoveredObj !== hitObj) {
        if (hoveredObj && typeof gsap !== 'undefined') {
          gsap.to(hoveredObj.scale, { x: 1, y: 1, z: 1, duration: 0.3, ease: EASE_GSAP });
        }
        hoveredObj = hitObj;
        if (typeof gsap !== 'undefined') {
          gsap.to(hoveredObj.scale, { x: 1.15, y: 1.15, z: 1.15, duration: 0.3, ease: EASE_GSAP });
        }
      }
      const vector = new THREE.Vector3();
      hitObj.getWorldPosition(vector);
      vector.y += 0.8;
      vector.project(camera);
      const x = (vector.x * 0.5 + 0.5) * window.innerWidth;
      const y = (-(vector.y * 0.5) + 0.5) * window.innerHeight;
      tooltipCategory.textContent = hitObj.userData.category || 'Object';
      tooltipTitle.textContent = hitObj.userData.name || 'Object';
      tooltipVal.textContent = hitObj.userData.val || 'Active';
      tooltipTag.textContent = hitObj.userData.tag || '';
      tooltip3D.style.left = `${x}px`;
      tooltip3D.style.top = `${y}px`;
      tooltip3D.hidden = false;
    } else {
      if (hoveredObj && typeof gsap !== 'undefined') {
        gsap.to(hoveredObj.scale, { x: 1, y: 1, z: 1, duration: 0.3, ease: EASE_GSAP });
        hoveredObj = null;
      }
      tooltip3D.hidden = true;
    }
  }

  const clock = new THREE.Clock();
  function animate() {
    requestAnimationFrame(animate);
    const time = clock.getElapsedTime();
    globeGroup.rotation.y = time * 0.28;
    listGroup.rotation.y = Math.sin(time * 0.45) * 0.08;
    recordGroup.rotation.y = Math.sin(time * 0.7) * 0.1;
    reportsGroup.rotation.y = time * 0.18;
    camera.lookAt(cameraTarget);
    checkRaycast();
    renderer.render(scene, camera);
  }
  animate();

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, isMobile ? 1.0 : 1.5));
  });
})();
