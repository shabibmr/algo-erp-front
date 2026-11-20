/**
 * algoERP 3D — Refined Module Icon Foreground Scroll & 3D Container Motion Engine
 * Stack: Three.js (Module Icon Meshes + Scroll Foreground Focus) + 3D Tilt Cards + Anime.js
 */

(() => {
  'use strict';

  // 1. WebGL Feature Detection
  function isWebGLAvailable() {
    try {
      const canvas = document.createElement('canvas');
      return !!(window.WebGLRenderingContext && (canvas.getContext('webgl') || canvas.getContext('experimental-webgl')));
    } catch (e) {
      return false;
    }
  }

  if (!isWebGLAvailable()) {
    console.warn("WebGL not supported on this device. Switching to fallback image mode.");
    document.getElementById('webgl-fallback').style.display = 'block';
    document.getElementById('loader').classList.add('is-done');
    return;
  }

  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent) || window.innerWidth < 768;

  // UI Elements
  const loaderScreen = document.getElementById('loader');
  const loaderBar = document.getElementById('loader-bar');
  const loaderPercent = document.getElementById('loader-percent');
  const cabinetOverlay = document.getElementById('cabinet-overlay');
  const spotlightOverlay = document.getElementById('spotlight-overlay');
  const tooltip3D = document.getElementById('tooltip-3d');
  const tooltipCategory = document.getElementById('tooltip-category');
  const tooltipTitle = document.getElementById('tooltip-title');
  const tooltipVal = document.getElementById('tooltip-val');
  const tooltipTag = document.getElementById('tooltip-tag');
  const toast = document.getElementById('toast');

  // 2. Interactive Magic Ripple System Canvas
  const rippleCanvas = document.getElementById('magic-ripple-canvas');
  const rCtx = rippleCanvas?.getContext('2d');
  const ripples = [];

  function resizeRippleCanvas() {
    if (rippleCanvas) {
      rippleCanvas.width = window.innerWidth;
      rippleCanvas.height = window.innerHeight;
    }
  }
  resizeRippleCanvas();
  window.addEventListener('resize', resizeRippleCanvas);

  function spawnMagicRipple(x, y) {
    if (!rCtx) return;
    ripples.push({
      x: x,
      y: y,
      radius: 0,
      maxRadius: Math.random() * 40 + 50,
      opacity: 1,
      color: Math.random() > 0.5 ? '184, 132, 59' : '14, 107, 104'
    });
  }

  window.addEventListener('pointerdown', (e) => {
    spawnMagicRipple(e.clientX, e.clientY);
  });

  function animateRipples() {
    if (!rCtx) return;
    rCtx.clearRect(0, 0, rippleCanvas.width, rippleCanvas.height);

    for (let i = ripples.length - 1; i >= 0; i--) {
      const r = ripples[i];
      r.radius += 2.5;
      r.opacity -= 0.025;

      if (r.opacity <= 0) {
        ripples.splice(i, 1);
        continue;
      }

      rCtx.beginPath();
      rCtx.arc(r.x, r.y, r.radius, 0, Math.PI * 2);
      rCtx.strokeStyle = `rgba(${r.color}, ${r.opacity})`;
      rCtx.lineWidth = 2;
      rCtx.stroke();
    }
    requestAnimationFrame(animateRipples);
  }
  animateRipples();

  // 3. Anime.js Entrance Timeline
  const entranceTl = anime.timeline({
    autoplay: false,
    easing: 'spring(1, 85, 12, 0)'
  });

  entranceTl
    .add({
      targets: '.seal-dock',
      scale: [0.7, 1],
      opacity: [0, 1],
      duration: 800
    })
    .add({
      targets: '.greeting .anime-word',
      translateY: [25, 0],
      opacity: [0, 1],
      delay: anime.stagger(60)
    }, '-=600')
    .add({
      targets: '.bezel',
      translateY: [35, 0],
      opacity: [0, 1],
      delay: anime.stagger(100)
    }, '-=400');

  let progress = 0;
  const loadInterval = setInterval(() => {
    progress += Math.floor(Math.random() * 22) + 12;
    if (progress >= 100) {
      progress = 100;
      clearInterval(loadInterval);
      setTimeout(() => {
        loaderScreen.classList.add('is-done');
        entranceTl.play();
        triggerStatCounters();
        init3DCardTiltMotion();
      }, 300);
    }
    loaderBar.style.width = progress + '%';
    loaderPercent.textContent = progress + '%';
  }, 65);

  function triggerStatCounters() {
    document.querySelectorAll('.stat-counter').forEach(el => {
      const target = parseFloat(el.getAttribute('data-target')) || 0;
      const prefix = el.getAttribute('data-prefix') || '';

      anime({
        targets: el,
        innerHTML: [0, target],
        round: 1,
        duration: 1800,
        easing: 'easeOutExpo',
        update: (anim) => {
          const val = Math.round(anim.animations[0].currentValue);
          el.innerHTML = prefix + val.toLocaleString();
        }
      });
    });
  }

  // 4. Three.js WebGL Scene Setup
  const canvas = document.getElementById('webgl-canvas');

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf1ede6);
  scene.fog = new THREE.FogExp2(0xf1ede6, 0.02);

  const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(0, 4.5, 9);

  const renderer = new THREE.WebGLRenderer({
    canvas: canvas,
    antialias: true,
    alpha: true,
    powerPreference: "high-performance"
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, isMobile ? 1.0 : 1.5));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  // Texture Loader for High-Res Linen Desk Map
  const textureLoader = new THREE.TextureLoader();
  const linenDeskTexture = textureLoader.load('./assets/linen_paper_bg.jpg', (tex) => {
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(6, 6);
  });

  // Lights
  const ambientLight = new THREE.AmbientLight(0xfffbf5, 0.85);
  scene.add(ambientLight);

  const sunLight = new THREE.DirectionalLight(0xfffaed, 1.4);
  sunLight.position.set(6, 12, 6);
  sunLight.castShadow = true;
  scene.add(sunLight);

  const spotlightBeam = new THREE.SpotLight(0xdfb26b, 0, 16, Math.PI / 6, 0.5, 1);
  spotlightBeam.position.set(0, 10, 2);
  spotlightBeam.castShadow = true;
  scene.add(spotlightBeam);

  // Dust Swarm
  const dustCount = 60;
  const dustGeo = new THREE.BufferGeometry();
  const dustPos = new Float32Array(dustCount * 3);
  for (let i = 0; i < dustCount * 3; i++) {
    dustPos[i] = (Math.random() - 0.5) * 4;
  }
  dustGeo.setAttribute('position', new THREE.BufferAttribute(dustPos, 3));
  const dustMat = new THREE.PointsMaterial({ color: 0xdfb26b, size: 0.08, transparent: true, opacity: 0.7 });
  const dustSwarm = new THREE.Points(dustGeo, dustMat);
  dustSwarm.position.set(0, 3, 1);
  scene.add(dustSwarm);

  const cursorLight = new THREE.PointLight(0xb8843b, 1.5, 9);
  scene.add(cursorLight);

  // Desk Surface Plane (Grid Lines Removed for Clean Luxury Aesthetic)
  const planeGeo = new THREE.PlaneGeometry(32, 32);
  const planeMat = new THREE.MeshStandardMaterial({
    map: linenDeskTexture,
    color: 0xf1ede6,
    roughness: 0.75,
    metalness: 0.1
  });
  const deskPlane = new THREE.Mesh(planeGeo, planeMat);
  deskPlane.rotation.x = -Math.PI / 2;
  deskPlane.position.y = -0.5;
  deskPlane.receiveShadow = true;
  scene.add(deskPlane);

  const interactiveModuleObjects = [];

  // 5. Distinct 3D Module Icon Meshes representing focused modules
  const moduleIcons = {};

  // Icon 1: Organization Topology Node Globe (Hero Focused)
  const globeGroup = new THREE.Group();
  const globeGeo = new THREE.SphereGeometry(0.8, 24, 24);
  const globeMat = new THREE.MeshStandardMaterial({ color: 0x0e6b68, metalness: 0.4, roughness: 0.2, emissive: 0x0e6b68, emissiveIntensity: 0.2 });
  const globeMesh = new THREE.Mesh(globeGeo, globeMat);
  globeMesh.castShadow = true;
  globeMesh.userData = { name: "Multi-Branch Topology Globe", category: "Organization Module", val: "Dubai, Riyadh & London Nodes", tag: "Foreground Focused" };
  globeGroup.add(globeMesh);

  const ringGeo = new THREE.RingGeometry(0.95, 1.1, 32);
  const ringMat = new THREE.MeshBasicMaterial({ color: 0xdfb26b, side: THREE.DoubleSide, transparent: true, opacity: 0.75 });
  const ringMesh = new THREE.Mesh(ringGeo, ringMat);
  ringMesh.rotation.x = Math.PI / 3;
  globeGroup.add(ringMesh);

  globeGroup.position.set(-2.5, 0.5, 0);
  scene.add(globeGroup);
  moduleIcons.topology = globeGroup;
  interactiveModuleObjects.push(globeMesh);

  // Icon 2: Sales Invoice Document + Brass Seal (Needs Action Focused)
  const invoiceGroup = new THREE.Group();
  const docGeo = new THREE.BoxGeometry(1.2, 1.6, 0.08);
  const docMat = new THREE.MeshStandardMaterial({ color: 0xfbf9f6, roughness: 0.4, metalness: 0.1 });
  const docMesh = new THREE.Mesh(docGeo, docMat);
  docMesh.castShadow = true;
  docMesh.userData = { name: "Sales Invoice Document (INV/2408)", category: "Voucher Series Module", val: "Desert Motors LLC · AED 14,280", tag: "Foreground Focused" };
  invoiceGroup.add(docMesh);

  const sealMiniGeo = new THREE.CylinderGeometry(0.3, 0.35, 0.12, 24);
  const sealMiniMat = new THREE.MeshStandardMaterial({ color: 0xb8843b, metalness: 0.9, roughness: 0.2 });
  const sealMini = new THREE.Mesh(sealMiniGeo, sealMiniMat);
  sealMini.rotation.x = Math.PI / 2;
  sealMini.position.set(0.3, -0.4, 0.08);
  invoiceGroup.add(sealMini);

  invoiceGroup.position.set(-1.0, 0.4, -2.5);
  scene.add(invoiceGroup);
  moduleIcons.invoice = invoiceGroup;
  interactiveModuleObjects.push(docMesh);

  // Icon 3: Currency Coin Stack & Vault Cylinder (Cash & Bank Focused)
  const vaultGroup = new THREE.Group();
  const coinCount = 5;
  for (let i = 0; i < coinCount; i++) {
    const coinGeo = new THREE.CylinderGeometry(0.55, 0.55, 0.12, 24);
    const coinMat = new THREE.MeshStandardMaterial({ color: 0xdfb26b, metalness: 0.92, roughness: 0.15 });
    const coinMesh = new THREE.Mesh(coinGeo, coinMat);
    coinMesh.position.y = i * 0.14;
    coinMesh.castShadow = true;
    vaultGroup.add(coinMesh);
  }

  const vaultRingGeo = new THREE.TorusGeometry(0.75, 0.08, 16, 32);
  const vaultRingMat = new THREE.MeshStandardMaterial({ color: 0x2f6f4e, metalness: 0.6, roughness: 0.3 });
  const vaultRing = new THREE.Mesh(vaultRingGeo, vaultRingMat);
  vaultRing.rotation.x = Math.PI / 2;
  vaultRing.position.y = 0.35;
  vaultGroup.add(vaultRing);

  vaultGroup.position.set(1.5, 0.2, -2.5);
  scene.add(vaultGroup);
  moduleIcons.vault = vaultGroup;
  interactiveModuleObjects.push(vaultRing);

  // Icon 4: Inventory Cargo Box & Pallet (Stock & Warehouse Focused)
  const cargoGroup = new THREE.Group();
  const boxGeo = new THREE.BoxGeometry(1.1, 1.1, 1.1);
  const boxMat = new THREE.MeshStandardMaterial({ color: 0xb8843b, roughness: 0.6, metalness: 0.2 });
  const boxMesh = new THREE.Mesh(boxGeo, boxMat);
  boxMesh.castShadow = true;
  boxMesh.userData = { name: "Warehouse Cargo SKU Batch", category: "Inventory Godown Module", val: "WH-01 Jebel Ali · 8,420 SKUs", tag: "Foreground Focused" };
  cargoGroup.add(boxMesh);

  cargoGroup.position.set(3.0, 0.4, -3.0);
  scene.add(cargoGroup);
  moduleIcons.cargo = cargoGroup;
  interactiveModuleObjects.push(boxMesh);

  // 6. Scroll-Driven 3D Module Icon Movement to Foreground
  function updateScroll3DFocus() {
    const scrollY = window.scrollY;
    const maxScroll = document.body.scrollHeight - window.innerHeight;
    const progress = Math.min(Math.max(scrollY / (maxScroll || 1), 0), 1);

    let focusTarget = 'topology';

    if (progress < 0.22) {
      focusTarget = 'topology';
    } else if (progress < 0.55) {
      focusTarget = 'invoice';
    } else if (progress < 0.82) {
      focusTarget = 'vault';
    } else {
      focusTarget = 'cargo';
    }

    Object.keys(moduleIcons).forEach(key => {
      const iconGroup = moduleIcons[key];
      const isFocused = key === focusTarget;

      const targetZ = isFocused ? 3.5 : (key === 'topology' ? -1.0 : -3.0);
      const targetY = isFocused ? 0.8 : 0.2;
      const targetScale = isFocused ? 1.4 : 0.65;

      gsap.to(iconGroup.position, {
        z: targetZ,
        y: targetY,
        duration: 1.2,
        ease: "power2.out"
      });

      gsap.to(iconGroup.scale, {
        x: targetScale,
        y: targetScale,
        z: targetScale,
        duration: 1.2,
        ease: "power2.out"
      });
    });
  }

  window.addEventListener('scroll', updateScroll3DFocus, { passive: true });

  // 7. 3D Motion on Cards / Containers (Parallax & Perspective Tilt)
  function init3DCardTiltMotion() {
    const cards = document.querySelectorAll('.card-3d-tilt, .magic-hover-card, .magic-panel');

    cards.forEach(card => {
      card.addEventListener('pointermove', (e) => {
        const rect = card.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;

        const mouseX = e.clientX - centerX;
        const mouseY = e.clientY - centerY;

        const rotateX = (mouseY / (rect.height / 2)) * -10;
        const rotateY = (mouseX / (rect.width / 2)) * 10;

        card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(12px) scale(1.03)`;
      });

      card.addEventListener('pointerleave', () => {
        card.style.transform = `perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0px) scale(1)`;
      });
    });
  }

  // 8. Overlays & Keybindings
  function openOverlay(overlayEl) {
    overlayEl.hidden = false;
    document.body.style.overflow = 'hidden';

    anime({
      targets: overlayEl.querySelector('.overlay-scrim'),
      opacity: [0, 1],
      duration: 350,
      easing: 'easeOutQuad'
    });

    const panel = overlayEl.querySelector('.cabinet-stage, .spotlight-panel');
    if (panel) {
      anime({
        targets: panel,
        scale: [0.85, 1],
        opacity: [0, 1],
        translateY: [30, 0],
        duration: 500,
        easing: 'spring(1, 85, 12, 0)'
      });
    }

    if (overlayEl === spotlightOverlay) {
      gsap.to(spotlightBeam, { intensity: 4.5, duration: 0.8 });
      document.getElementById('spotlight-input')?.focus();
    }
  }

  function closeOverlays() {
    [cabinetOverlay, spotlightOverlay].forEach(overlayEl => {
      if (!overlayEl.hidden) {
        anime({
          targets: overlayEl.querySelector('.overlay-scrim, .cabinet-stage, .spotlight-panel'),
          opacity: 0,
          scale: 0.95,
          duration: 300,
          easing: 'easeInQuad',
          complete: () => {
            overlayEl.hidden = true;
            document.body.style.overflow = '';
          }
        });
      }
    });

    gsap.to(spotlightBeam, { intensity: 0, duration: 0.6 });
  }

  document.getElementById('seal-btn')?.addEventListener('click', () => openOverlay(cabinetOverlay));
  document.getElementById('open-cabinet-btn')?.addEventListener('click', () => openOverlay(cabinetOverlay));
  document.getElementById('close-cabinet-btn')?.addEventListener('click', closeOverlays);
  document.getElementById('close-cabinet-scrim')?.addEventListener('click', closeOverlays);

  document.getElementById('spotlight-trigger')?.addEventListener('click', () => openOverlay(spotlightOverlay));
  document.getElementById('open-spotlight-btn')?.addEventListener('click', () => openOverlay(spotlightOverlay));
  document.getElementById('btn-spotlight-inline')?.addEventListener('click', () => openOverlay(spotlightOverlay));
  document.getElementById('btn-spotlight-foot')?.addEventListener('click', () => openOverlay(spotlightOverlay));
  document.getElementById('close-spotlight-scrim')?.addEventListener('click', closeOverlays);

  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      if (!spotlightOverlay.hidden) closeOverlays(); else openOverlay(spotlightOverlay);
    } else if ((e.metaKey || e.ctrlKey) && (e.key === '.' || e.key === '>')) {
      e.preventDefault();
      if (!cabinetOverlay.hidden) closeOverlays(); else openOverlay(cabinetOverlay);
    } else if (e.key === 'Escape') {
      closeOverlays();
    }
  });

  // Folder Filtering inside Cabinet
  document.querySelectorAll('.folder').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.folder').forEach(f => f.classList.remove('is-on'));
      tab.classList.add('is-on');

      const folder = tab.getAttribute('data-folder');
      document.querySelectorAll('.mod-tile').forEach(tile => {
        const matches = folder === 'all' || tile.getAttribute('data-folder') === folder;
        tile.style.display = matches ? '' : 'none';
      });

      anime({
        targets: '.mod-tile:not([style*="display: none"])',
        scale: [0.85, 1],
        opacity: [0, 1],
        delay: anime.stagger(50),
        easing: 'spring(1, 85, 12, 0)'
      });
    });
  });

  // 9. Physical 3D Stamp & Action
  function trigger3DStampAnimation(invCode = "INV/2408") {
    showToast(`Physical 3D Seal Applied to ${invCode}! ✓`);
  }

  document.querySelectorAll('.stamp-card-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const inv = btn.getAttribute('data-inv') || 'INV/2408';
      trigger3DStampAnimation(inv);
    });
  });

  document.getElementById('btn-stamp-quick')?.addEventListener('click', () => trigger3DStampAnimation());

  let isDaylight = true;
  document.getElementById('btn-theme-toggle')?.addEventListener('click', () => {
    isDaylight = !isDaylight;
    document.getElementById('theme-icon').textContent = isDaylight ? '☀️' : '🌙';

    gsap.to(scene.background, {
      r: isDaylight ? 0.94 : 0.08,
      g: isDaylight ? 0.93 : 0.11,
      b: isDaylight ? 0.90 : 0.15,
      duration: 1.2
    });

    gsap.to(scene.fog, { color: isDaylight ? 0xf1ede6 : 0x141b24, duration: 1.2 });
    gsap.to(ambientLight, { intensity: isDaylight ? 0.85 : 0.4, duration: 1.2 });
  });

  // 10. Raycaster & Kinetic Tooltip
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2(-999, -999);
  let hoveredObj = null;

  window.addEventListener('pointermove', (e) => {
    mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;

    cursorLight.position.x = mouse.x * 6;
    cursorLight.position.z = -mouse.y * 4 + 2;
    cursorLight.position.y = 2;
  });

  function checkRaycast() {
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveModuleObjects);

    if (intersects.length > 0) {
      const hitObj = intersects[0].object;
      if (hoveredObj !== hitObj) {
        if (hoveredObj) {
          gsap.to(hoveredObj.scale, { x: 1, y: 1, z: 1, duration: 0.3 });
        }
        hoveredObj = hitObj;
        gsap.to(hoveredObj.scale, { x: 1.2, y: 1.2, z: 1.2, duration: 0.3 });

        anime({
          targets: '#tooltip-3d',
          scale: [0.75, 1],
          opacity: [0, 1],
          duration: 300,
          easing: 'spring(1, 85, 12, 0)'
        });
      }

      const vector = new THREE.Vector3();
      hitObj.getWorldPosition(vector);
      vector.y += 0.8;
      vector.project(camera);

      const x = (vector.x * .5 + .5) * window.innerWidth;
      const y = (-(vector.y * .5) + .5) * window.innerHeight;

      tooltipCategory.textContent = hitObj.userData.category || "3D Module";
      tooltipTitle.textContent = hitObj.userData.name || "Module";
      tooltipVal.textContent = hitObj.userData.val || "Click to Launch Module";
      tooltipTag.textContent = hitObj.userData.tag || "Cabinet Active";
      tooltip3D.style.left = `${x}px`;
      tooltip3D.style.top = `${y}px`;
      tooltip3D.hidden = false;

    } else {
      if (hoveredObj) {
        gsap.to(hoveredObj.scale, { x: 1, y: 1, z: 1, duration: 0.3 });
        hoveredObj = null;
      }
      tooltip3D.hidden = true;
    }
  }

  function showToast(msg) {
    if (!toast) return;
    toast.textContent = msg;
    toast.hidden = false;
    void toast.offsetWidth;
    toast.classList.add('is-on');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toast.classList.remove('is-on');
      setTimeout(() => { toast.hidden = true; }, 300);
    }, 2400);
  }

  document.querySelectorAll('.mod-tile, .spot-row').forEach(btn => {
    btn.addEventListener('click', () => {
      const name = btn.getAttribute('data-name') || btn.querySelector('strong')?.textContent || 'Module';
      closeOverlays();
      showToast(`Launched 3D Module: ${name} ✓`);
    });
  });

  // Render Loop
  let clock = new THREE.Clock();
  function animate() {
    requestAnimationFrame(animate);

    const time = clock.getElapsedTime();

    globeGroup.rotation.y = time * 0.3;
    invoiceGroup.rotation.y = Math.sin(time * 0.8) * 0.15;
    vaultGroup.rotation.y = time * 0.25;
    cargoGroup.rotation.y = time * 0.2;

    dustSwarm.rotation.y += 0.005;

    camera.lookAt(0, 0, 0);

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
