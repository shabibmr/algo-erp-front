# algoERP 3D — Cabinet & Spotlight (Chrome-Free 3D Desk)

An interactive, chrome-free **3D WebGL Web Experience** for **algoERP**, built on the **Cabinet + Spotlight** design recipe with **Three.js** and **Anime.js**.

| Axis | Choice |
|------|--------|
| Vibe | Editorial Luxury (Ledger & Linen light × Metallic Brass × Lagoon WebGL) |
| Layout | Chrome-Free Full-Bleed Desk + Floating Seal Dock |
| 3D Engine | Three.js (r128) + Volumetric 3D Spotlight Beam + 3D Launchpad Cubes |
| Interactivity | The Cabinet (`Cmd+.`), Spotlight Command Palette (`Cmd+K`), Physical Brass Seal Stamper |

---

## 🚀 How to Run

### Direct Browser Opening (Windows)
```bash
start mockups/algoerp-cabinet-3d/index.html
```

### Or Serve Locally
```bash
npx --yes serve mockups/algoerp-cabinet-3d
```

---

## 🎮 Interactive 3D Features & Keybindings

1. **❖ The Cabinet (3D Launchpad Grid)**:
   - Click the floating persistent **Cabinet Seal** dock (`#seal-btn`) or press **`⌘.` / `Ctrl+.`** to launch the full-screen module drawer.
   - Features 12 floating 3D module cubes in Three.js (*Desk, Sales Invoice, Purchase Order, Cash Receipt, Stock Transfer, Brands, Ledgers, Items, Reports, People, Warehouses, Settings*).
2. **🔍 Volumetric 3D Spotlight Beam (`⌘K` / `Ctrl+K`)**:
   - Press **`⌘K` / `Ctrl+K`** to trigger the 3D Spotlight Command Palette.
   - Fires a volumetric Three.js `SpotLight` cone beam focusing down on the desk while allowing instant module and voucher searching.
3. **🏛️ Physical 3D Brass Seal Stamper**:
   - Click any **"Seal 3D"** button or the 3D brass seal object on desk to physically press down with particle effects.
4. **⌨️ Keyboard Shortcuts**:
   - **`⌘K` / `Ctrl+K`**: Toggle Spotlight Command Palette.
   - **`⌘.` / `Ctrl+.`**: Toggle The Cabinet Launchpad.
   - **`Esc`**: Close any active overlay.

---

## 📁 File Structure

- `index.html` — Chrome-free full-bleed desk shell, persistent seal dock, cabinet launchpad modal, and spotlight overlay.
- `styles.css` — Editorial Luxury design system, launchpad grid tiles, spotlight palette, and spring animations.
- `script.js` — Three.js WebGL scene setup, 3D volumetric spotlight beam, 3D module launchpad cubes, Anime.js timelines, and keyboard listeners.
- `assets/cabinet_3d.jpg` — Generated 3D Cabinet & Spotlight visual asset render.
