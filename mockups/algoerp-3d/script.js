/**
 * algoERP 3D — Refined Three.js WebGL & Anime.js Kinetic Engine
 * Stack: Three.js (3D WebGL) + Anime.js v3.2.1 (Kinetic UI & SVG Morphs) + GSAP
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

  // Mobile Detection for DPR Optimization
  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent) || window.innerWidth < 768;

  // UI Elements
  const loaderScreen = document.getElementById('loader');
  const loaderBar = document.getElementById('loader-bar');
  const loaderPercent = document.getElementById('loader-percent');
  const tooltip3D = document.getElementById('tooltip-3d');
  const tooltipCategory = document.getElementById('tooltip-category');
  const tooltipTitle = document.getElementById('tooltip-title');
  const tooltipVal = document.getElementById('tooltip-val');
  const tooltipTag = document.getElementById('tooltip-tag');
  const fpsText = document.getElementById('fps-text');
  const toast = document.getElementById('toast');

  // 2. Anime.js Entrance Timeline Setup
  const entranceTl = anime.timeline({
    autoplay: false,
    easing: 'spring(1, 85, 12, 0)'
  });

  entranceTl
    .add({
      targets: '.island',
      translateY: [-40, 0],
      opacity: [0, 1],
      duration: 900
    })
    .add({
      targets: '.greeting .anime-word',
      translateY: [25, 0],
      opacity: [0, 1],
      delay: anime.stagger(60)
    }, '-=700')
    .add({
      targets: '.hero-chip',
      scale: [0.7, 1],
      opacity: [0, 1],
      delay: anime.stagger(50)
    }, '-=500')
    .add({
      targets: '.dock-3d',
      translateY: [60, 0],
      opacity: [0, 1],
      duration: 800
    }, '-=400');

  // Simulated Loading Progress & Trigger Entrance
  let progress = 0;
  const loadInterval = setInterval(() => {
    progress += Math.floor(Math.random() * 22) + 12;
    if (progress >= 100) {
      progress = 100;
      clearInterval(loadInterval);
      setTimeout(() => {
        loaderScreen.classList.add('is-done');
        // Play Anime.js Entrance Choreography
        entranceTl.play();
        triggerStatCounters();
        animateGodownCards();
      }, 300);
    }
    loaderBar.style.width = progress + '%';
    loaderPercent.textContent = progress + '%';
  }, 75);

  // 3. Anime.js Stat Counter Animation
  function triggerStatCounters() {
    document.querySelectorAll('.stat-counter').forEach(el => {
      const target = parseFloat(el.getAttribute('data-target')) || 0;
      const suffix = el.getAttribute('data-suffix') || '';

      anime({
        targets: el,
        innerHTML: [0, target],
        round: 1,
        duration: 1800,
        easing: 'easeOutExpo',
        update: (anim) => {
          const val = Math.round(anim.animations[0].currentValue);
          el.innerHTML = val.toLocaleString() + suffix;
        }
      });
    });
  }

  // 4. Anime.js Staggered Godown Card Grid Revealer
  function animateGodownCards() {
    anime({
      targets: '.godown-card',
      opacity: [0, 1],
      translateY: [40, 0],
      scale: [0.92, 1],
      delay: anime.stagger(120, { grid: [3, 1], from: 'center' }),
      easing: 'spring(1, 80, 12, 0)'
    });
  }

  // 5. Three.js WebGL Scene Setup
  const canvas = document.getElementById('webgl-canvas');

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf1ede6);
  scene.fog = new THREE.FogExp2(0xf1ede6, 0.022);

  const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(-2.5, 4.8, 6.5);

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
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.15;

  // Lights
  const ambientLight = new THREE.AmbientLight(0xfffbf5, 0.85);
  scene.add(ambientLight);

  const sunLight = new THREE.DirectionalLight(0xfffaed, 1.4);
  sunLight.position.set(6, 12, 6);
  sunLight.castShadow = true;
  sunLight.shadow.mapSize.width = 1024;
  sunLight.shadow.mapSize.height = 1024;
  sunLight.shadow.bias = -0.0005;
  scene.add(sunLight);

  const rimLight = new THREE.DirectionalLight(0x0e6b68, 1.2);
  rimLight.position.set(-6, 4, -4);
  scene.add(rimLight);

  const cursorLight = new THREE.PointLight(0xb8843b, 1.5, 9);
  scene.add(cursorLight);

  // Desk Plane
  const planeGeo = new THREE.PlaneGeometry(32, 32);
  const planeMat = new THREE.MeshStandardMaterial({
    color: 0xebdcc9,
    roughness: 0.85,
    metalness: 0.05
  });
  const deskPlane = new THREE.Mesh(planeGeo, planeMat);
  deskPlane.rotation.x = -Math.PI / 2;
  deskPlane.position.y = -0.5;
  deskPlane.receiveShadow = true;
  scene.add(deskPlane);

  const gridHelper = new THREE.GridHelper(32, 40, 0xb8843b, 0xd0c4b4);
  gridHelper.position.y = -0.49;
  scene.add(gridHelper);

  const interactiveDomainObjects = [];

  // A. Organization Branch Nodes
  const branchGroup = new THREE.Group();
  const branchNodes = [
    { name: "Dubai HQ", category: "Organization Branch", val: "AED 12.4 M Volume", tag: "Primary Operating Node", x: -3.0, z: -1.2, color: 0x0e6b68, size: 0.6 },
    { name: "Abu Dhabi Branch", category: "Organization Branch", val: "AED 4.2 M Volume", tag: "Capital Branch Hub", x: -1.2, z: -2.5, color: 0x0288d1, size: 0.48 },
    { name: "Sharjah Depot", category: "Organization Branch", val: "AED 1.8 M Volume", tag: "Northern Emirates Node", x: -4.2, z: -2.8, color: 0x2f6f4e, size: 0.42 },
    { name: "Riyadh Regional HQ", category: "Organization Branch", val: "SAR 8.9 M Volume", tag: "KSA Main Node", x: -2.2, z: 0.8, color: 0xb8843b, size: 0.55 }
  ];

  branchNodes.forEach(b => {
    const nodeGeo = new THREE.SphereGeometry(b.size, 24, 24);
    const nodeMat = new THREE.MeshStandardMaterial({
      color: b.color,
      roughness: 0.25,
      metalness: 0.4,
      emissive: b.color,
      emissiveIntensity: 0.2
    });
    const nodeMesh = new THREE.Mesh(nodeGeo, nodeMat);
    nodeMesh.position.set(b.x, b.size / 2 - 0.5, b.z);
    nodeMesh.castShadow = true;
    nodeMesh.userData = { ...b };
    branchGroup.add(nodeMesh);
    interactiveDomainObjects.push(nodeMesh);
  });
  scene.add(branchGroup);

  // B. Inventory Godowns
  const godownGroup = new THREE.Group();
  const godownData = [
    { code: "WH-01", name: "Jebel Ali Godown", category: "Inventory Godown", val: "8,420 SKUs · 94% Cap", tag: "Heavy Machinery & Batches", x: 1.5, z: -1.5, height: 2.2, color: 0x0e6b68 },
    { code: "WH-02", name: "Al Quoz Depot", category: "Inventory Godown", val: "4,190 SKUs · 68% Cap", tag: "FMCG Consumables", x: 2.8, z: -1.0, height: 1.6, color: 0x0288d1 },
    { code: "WH-03", name: "Riyadh Distribution", category: "Inventory Godown", val: "12,850 SKUs · 82% Cap", tag: "KSA Central Stock", x: 2.1, z: 0.8, height: 2.7, color: 0x7b1fa2 }
  ];

  godownData.forEach(g => {
    const rackGeo = new THREE.BoxGeometry(0.85, g.height, 0.85);
    const rackMat = new THREE.MeshStandardMaterial({
      color: g.color,
      roughness: 0.3,
      metalness: 0.35,
      transparent: true,
      opacity: 0.9
    });
    const rackMesh = new THREE.Mesh(rackGeo, rackMat);
    rackMesh.position.set(g.x, g.height / 2 - 0.5, g.z);
    rackMesh.castShadow = true;
    rackMesh.userData = { ...g, baseHeight: g.height };
    godownGroup.add(rackMesh);
    interactiveDomainObjects.push(rackMesh);
  });
  scene.add(godownGroup);

  // C. Multi-Currency Vault
  const vaultGroup = new THREE.Group();
  const vaultData = [
    { name: "AED Operating A/C", category: "Accounts & Currency", val: "AED 892,110.50", tag: "Base Currency (1.0000)", x: 0, z: -2.8, height: 1.8, color: 0x2f6f4e },
    { name: "USD Trade Facility", category: "Accounts & Currency", val: "$ 245,000.00 (AED 899.7K)", tag: "FX Rate: 3.6725", x: 1.1, z: -3.2, height: 2.1, color: 0x1565c0 },
    { name: "EUR European Reserve", category: "Accounts & Currency", val: "€ 180,500.00 (AED 725.7K)", tag: "FX Rate: 4.0210", x: -1.1, z: -3.2, height: 1.5, color: 0x6a1b9a }
  ];

  vaultData.forEach(v => {
    const cylGeo = new THREE.CylinderGeometry(0.4, 0.45, v.height, 24);
    const cylMat = new THREE.MeshStandardMaterial({
      color: v.color,
      metalness: 0.8,
      roughness: 0.2
    });
    const cylMesh = new THREE.Mesh(cylGeo, cylMat);
    cylMesh.position.set(v.x, v.height / 2 - 0.5, v.z);
    cylMesh.castShadow = true;
    cylMesh.userData = { ...v, baseHeight: v.height };
    vaultGroup.add(cylMesh);
    interactiveDomainObjects.push(cylMesh);
  });
  scene.add(vaultGroup);

  // D. 3D Official Brass Seal Stamp
  const sealGroup = new THREE.Group();
  const brassMaterial = new THREE.MeshStandardMaterial({ color: 0xb8843b, metalness: 0.9, roughness: 0.25 });
  const goldHandleMat = new THREE.MeshStandardMaterial({ color: 0xdfb26b, metalness: 0.95, roughness: 0.15 });

  const sealBaseGeo = new THREE.CylinderGeometry(1.1, 1.2, 0.25, 32);
  const sealBase = new THREE.Mesh(sealBaseGeo, brassMaterial);
  sealBase.castShadow = true;
  sealBase.userData = { name: "Official Executive Brass Seal", category: "Voucher Series Engine", val: "Voucher Series: INV, TRF, RCP", tag: "Click to Seal Pending Invoices" };
  sealGroup.add(sealBase);
  interactiveDomainObjects.push(sealBase);

  const handleGeo = new THREE.CylinderGeometry(0.3, 0.55, 1.2, 24);
  const handle = new THREE.Mesh(handleGeo, brassMaterial);
  handle.position.y = 0.7;
  sealGroup.add(handle);

  const knobGeo = new THREE.SphereGeometry(0.48, 24, 24);
  const knob = new THREE.Mesh(knobGeo, goldHandleMat);
  knob.position.y = 1.4;
  sealGroup.add(knob);

  sealGroup.position.set(0, 0.15, 0.8);
  scene.add(sealGroup);

  // 6. Camera Position Presets
  const cameraTargets = {
    branches: { x: -2.5, y: 4.8, z: 6.5, lookX: -2.0, lookY: 0, lookZ: -1.0 },
    godown: { x: 3.5, y: 3.8, z: 5.5, lookX: 2.1, lookY: 0.8, lookZ: -0.5 },
    vault: { x: 0, y: 4.2, z: 4.5, lookX: 0, lookY: 0.8, lookZ: -2.8 },
    seal: { x: 0, y: 2.4, z: 3.8, lookX: 0, lookY: 0.4, lookZ: 0.8 }
  };

  let targetLookAt = new THREE.Vector3(-2.0, 0, -1.0);
  let currentLookAt = new THREE.Vector3(-2.0, 0, -1.0);

  function setCameraPreset(presetKey) {
    const target = cameraTargets[presetKey];
    if (!target) return;

    targetLookAt.set(target.lookX, target.lookY, target.lookZ);

    gsap.to(camera.position, {
      x: target.x,
      y: target.y,
      z: target.z,
      duration: 1.6,
      ease: "power2.inOut"
    });

    document.querySelectorAll('.dock-btn').forEach(btn => {
      btn.classList.toggle('is-active', btn.getAttribute('data-preset') === presetKey);
    });

    if (presetKey === 'godown') animateGodownCards();
  }

  document.querySelectorAll('.dock-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      setCameraPreset(btn.getAttribute('data-preset'));
    });
  });

  // 7. Synchronized 3D Stamp & Anime.js 2D UI Impact Feedback
  function trigger3DStampAnimation(invCode = "INV/2408") {
    setCameraPreset('seal');

    const startY = 0.15;
    const pressY = -0.38;

    const timeline = gsap.timeline();
    timeline
      .to(sealGroup.position, {
        y: pressY,
        duration: 0.35,
        ease: "power3.in",
        onComplete: () => {
          showToast(`Official 3D Brass Seal Applied to Voucher ${invCode}! ✓`);
          animate2DUiStampImpact(invCode);
          morphSealSvgPath();
        }
      })
      .to(sealGroup.rotation, {
        y: sealGroup.rotation.y + Math.PI,
        duration: 0.4,
        ease: "back.out(1.7)"
      }, "-=0.1")
      .to(sealGroup.position, {
        y: startY,
        duration: 0.6,
        ease: "elastic.out(1, 0.4)"
      });
  }

  // Anime.js 2D UI Card Impact Bounce & Status Wave
  function animate2DUiStampImpact(invCode) {
    const targetRow = document.querySelector(`.voucher-row[data-voucher="${invCode}"]`) || document.querySelector('.voucher-row');
    if (targetRow) {
      anime({
        targets: targetRow,
        scale: [1, 0.93, 1.04, 1],
        rotateZ: [0, -1.2, 1, 0],
        duration: 650,
        easing: 'spring(1, 90, 10, 0)'
      });

      const pill = targetRow.querySelector('.status-pill');
      if (pill) {
        pill.textContent = 'Sealed ✓';
        pill.className = 'status-pill success';
        anime({
          targets: pill,
          scale: [1, 1.25, 1],
          backgroundColor: ['#fff3e0', '#e8f5e9'],
          color: ['#b8843b', '#2f6f4e'],
          duration: 600,
          easing: 'spring(1, 80, 12, 0)'
        });
      }
    }
  }

  // Anime.js SVG Path Morphing for Official Seal Badge
  let isMorphed = false;
  function morphSealSvgPath() {
    const sealPath = document.getElementById('seal-path');
    if (!sealPath) return;

    const starburstPath = "M60,10 L72,25 L92,20 L88,40 L105,52 L92,68 L98,88 L78,88 L60,105 L42,88 L22,88 L28,68 L15,52 L32,40 L28,20 L48,25 Z";
    const circlePath = "M60,10 A50,50 0 1,1 59.9,10 Z";

    anime({
      targets: sealPath,
      d: isMorphed ? circlePath : starburstPath,
      stroke: isMorphed ? '#b8843b' : '#0e6b68',
      duration: 1000,
      easing: 'spring(1, 75, 10, 0)'
    });

    isMorphed = !isMorphed;
  }

  document.getElementById('btn-stamp-action')?.addEventListener('click', () => trigger3DStampAnimation());
  document.getElementById('btn-batch-seal')?.addEventListener('click', () => trigger3DStampAnimation("INV/2408"));

  document.querySelectorAll('.stamp-card-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      trigger3DStampAnimation(btn.getAttribute('data-inv') || 'INV/2408');
    });
  });

  // 8. Lighting Theme Switcher
  let isDaylight = true;
  document.getElementById('btn-theme-toggle')?.addEventListener('click', () => {
    isDaylight = !isDaylight;
    const themeBtn = document.getElementById('btn-theme-toggle');
    if (themeBtn) {
      themeBtn.querySelector('.theme-icon').textContent = isDaylight ? '☀️' : '🌙';
      themeBtn.querySelector('span:last-child').textContent = isDaylight ? 'Daylight' : 'Midnight';
    }

    gsap.to(scene.background, {
      r: isDaylight ? 0.94 : 0.08,
      g: isDaylight ? 0.93 : 0.11,
      b: isDaylight ? 0.90 : 0.15,
      duration: 1.2
    });

    gsap.to(scene.fog, { color: isDaylight ? 0xf1ede6 : 0x141b24, duration: 1.2 });
    gsap.to(ambientLight, { intensity: isDaylight ? 0.85 : 0.4, duration: 1.2 });
  });

  // 9. Raycaster Hover Interactivity & Anime.js Tooltip Entrance
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
    const intersects = raycaster.intersectObjects(interactiveDomainObjects);

    if (intersects.length > 0) {
      const hitObj = intersects[0].object;
      if (hoveredObj !== hitObj) {
        if (hoveredObj) {
          gsap.to(hoveredObj.scale, { x: 1, y: 1, z: 1, duration: 0.3 });
        }
        hoveredObj = hitObj;
        gsap.to(hoveredObj.scale, { x: 1.15, y: 1.15, z: 1.15, duration: 0.3 });

        // Anime.js Kinetic Tooltip Scale-In
        anime({
          targets: '#tooltip-3d',
          scale: [0.75, 1],
          opacity: [0, 1],
          duration: 350,
          easing: 'spring(1, 85, 12, 0)'
        });
      }

      const vector = new THREE.Vector3();
      hitObj.getWorldPosition(vector);
      vector.y += (hitObj.userData.baseHeight || hitObj.geometry.parameters?.radius || 0.6) / 2 + 0.4;
      vector.project(camera);

      const x = (vector.x * .5 + .5) * window.innerWidth;
      const y = (-(vector.y * .5) + .5) * window.innerHeight;

      tooltipCategory.textContent = hitObj.userData.category || "ERP Resource";
      tooltipTitle.textContent = hitObj.userData.name || hitObj.userData.code || "Resource Node";
      tooltipVal.textContent = hitObj.userData.val || "";
      tooltipTag.textContent = hitObj.userData.tag || "";
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

  // 10. Scroll Sync
  window.addEventListener('scroll', () => {
    const scrollY = window.scrollY;
    const maxScroll = document.body.scrollHeight - window.innerHeight;
    const progress = Math.min(Math.max(scrollY / (maxScroll || 1), 0), 1);

    if (progress < 0.25) {
      setCameraPreset('branches');
    } else if (progress < 0.55) {
      setCameraPreset('godown');
    } else if (progress < 0.8) {
      setCameraPreset('vault');
    } else {
      setCameraPreset('seal');
    }
  }, { passive: true });

  // 11. Toast System
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
      setTimeout(() => { toast.hidden = true; }, 300);
    }, 2400);
  }

  document.getElementById('btn-explore-godown')?.addEventListener('click', () => setCameraPreset('godown'));
  document.getElementById('btn-reset-cam')?.addEventListener('click', () => setCameraPreset('branches'));
  document.getElementById('btn-trigger-godown-cam')?.addEventListener('click', () => setCameraPreset('godown'));

  document.querySelectorAll('.focus-godown-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      setCameraPreset('godown');
      showToast(`Focused 3D Godown Rack ${btn.getAttribute('data-wh')} ✓`);
    });
  });

  // 12. Main Render Loop
  let frameCount = 0;
  let lastTime = performance.now();
  const clock = new THREE.Clock();

  function animate() {
    requestAnimationFrame(animate);

    const time = clock.getElapsedTime();

    sealGroup.position.y = 0.15 + Math.sin(time * 1.5) * 0.04;
    sealGroup.rotation.y = Math.sin(time * 0.4) * 0.12;

    branchGroup.rotation.y = Math.sin(time * 0.2) * 0.08;

    currentLookAt.lerp(targetLookAt, 0.05);
    camera.lookAt(currentLookAt);

    checkRaycast();

    renderer.render(scene, camera);

    frameCount++;
    const now = performance.now();
    if (now >= lastTime + 1000) {
      const fps = Math.round((frameCount * 1000) / (now - lastTime));
      if (fpsText) fpsText.textContent = `${fps} FPS · 3D Kinetic Synced`;
      frameCount = 0;
      lastTime = now;
    }
  }

  animate();

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, isMobile ? 1.0 : 1.5));
  });

})();
