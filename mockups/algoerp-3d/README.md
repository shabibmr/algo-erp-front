# algoERP 3D — Logical ERP Domain Visualizer & 3D Web Experience

An interactive **3D WebGL Web Experience** for **algoERP**, mapping 3D WebGL scene elements directly to real ERP domain resources (`organization_branch`, `inventory_godown`, `accounts_ledger`, `organization_currency`, `transactions_sales_invoice`).

| Axis | Choice |
|------|--------|
| Vibe | Editorial Luxury (Ledger & Linen light × Metallic Brass × Lagoon WebGL) |
| 3D Engine | Three.js (r128) + WebGL Domain Shaders + Raycasting + GSAP |
| Logical 3D Resources | 🏢 Organization Branch Network, 📦 Inventory Godown Racks (`WH-01`, `WH-02`, `WH-03`), 💱 Multi-Currency Vault (AED/USD/EUR), ❖ Voucher Approval Seal Engine |
| Optimizations | 3D Loader (`useProgress` pattern), WebGL Hardware Fallback, Mobile DPR scaling, Non-blocking Pointer raycaster |

---

## 🚀 How to Run

### Direct Browser Opening (Windows)
```bash
start mockups/algoerp-3d/index.html
```

### Or Serve Locally
```bash
npx --yes serve mockups/algoerp-3d
```

---

## 🎮 Interactive Logical ERP Resources in 3D

1. **🏢 Organization Branch Topology Network**:
   - 3D Nodes representing Dubai HQ, Abu Dhabi Branch, Sharjah Depot, and Riyadh Regional HQ with animated transfer line conduits.
2. **📦 Inventory Godown Racks & SKUs (`inventory_godown`)**:
   - 3D Warehouse Pallet Racks (`WH-01 Jebel Ali`, `WH-02 Al Quoz`, `WH-03 Riyadh Depot`). Hovering displays real SKU counts, capacity %, and batch tracking.
3. **💱 Multi-Currency Accounts Vault (`organization_currency`, `accounts_ledger`)**:
   - 3D Metallic Vault Cylinders showing AED Operating A/C, USD Trade Facility, and EUR European Reserve with live FX rates.
4. **❖ Voucher Series 3D Brass Seal Engine (`transactions_sales_invoice`)**:
   - Official 3D Brass Seal Stamp linked to real voucher series (`INV/2408`, `TRF/0042`, `CRE/9901`). Click to physically press the seal in WebGL.

---

## 📁 File Structure

- `index.html` — Main shell with WebGL canvas layer, domain dock, godown cards, currency vault, and voucher table.
- `styles.css` — Modern design system tokens, glassmorphic UI panels, godown tags, and responsive layout.
- `script.js` — Three.js engine setup, domain resource 3D meshes, raycasting tooltips, and camera lerping.
- `assets/` — Generated 3D visual assets (`hero_3d.jpg`, `seal_3d.jpg`, `resources_3d.jpg`).
