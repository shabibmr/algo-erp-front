# algoERP — Standard Entity Architecture (5-View)

Interactive HTML mockup of the **standard surface set every entity gets** in algoERP.

| # | View | Role | Keyboard |
|---|------|------|----------|
| 1 | **Hub Dashboard** | Needs-you queue, KPIs, branch pulse | `⌘1` / `Ctrl+1` |
| 2 | **Entity List** | Filterable master grid | `⌘2` / `Ctrl+2` |
| 3 | **Record Overview** | Single-record dashboard, status steps, lines, activity | `⌘3` / `Ctrl+3` |
| 4 | **Entity Editor** | Desk Lamp workbench · header + line grid · sticky totals | `⌘4` / `Ctrl+4` |
| 5 | **Reports** | Report catalog, filters, chart + detail table | `⌘5` / `Ctrl+5` |

**Exemplar entity:** Sales Invoice (INV). The chrome is meant to be the template for masters and vouchers alike.

---

## Design language

- **Identity:** Ledger & Linen (linen paper, lagoon, brass seal) — see `docs/UI_DESIGN_PLAN.md`
- **Chrome craft:** Editorial Luxury double-bezel trays, island nav, button-in-button CTAs, mono money figures
- **3D role:** **Ambient** WebGL desk (Three.js) — camera presets reframe with each view; product UI is 2D-first and operator-dense
- **Motion:** Custom cubic-bezier / GSAP power3 / Anime curves — no stock `ease-in-out` UI transitions
- **Performance:** Film grain fixed; `backdrop-blur` limited to nav / seal dock / overlays / sticky editor footer

---

## Run

```bash
# Windows
start mockups/algoerp-entity-architecture-3d/index.html

# Or serve (preferred for texture loads)
npx --yes serve mockups/algoerp-entity-architecture-3d
```

---

## Shortcuts & chrome

| Shortcut | Action |
|----------|--------|
| `⌘1`–`⌘5` | Switch the five entity views |
| `⌘K` | Spotlight command palette (jump, new, seal, theme…) |
| `⌘.` | The Cabinet module launchpad |
| `Esc` | Close overlays |
| Seal dock · sun/moon | Toggle morning / night desk lighting |

---

## Files

| File | Purpose |
|------|---------|
| `index.html` | Shell, 5 view sections, cabinet, spotlight |
| `styles.css` | Tokens, double-bezel, tables, editor Desk Lamp, reports |
| `script.js` | View engine, list filter, editor totals, spotlight, ambient Three.js |
| `assets/` | `linen_paper_bg.jpg`, `luxury_desk_bg.jpg` (desk accent), `cabinet_3d.jpg` (WebGL fallback) |

---

## Mapping to Flutter (later)

| Mock view | Product surface |
|-----------|-----------------|
| Hub | Entity home / insights (not yet a generic Surface) |
| List | `MasterListSurface` / document list |
| Record | Document / master **overview** (extend beyond form-only) |
| Editor | `MasterFormSurface` / `DocumentSurface` |
| Reports | Entity report module (see `docs/REPORTS_STATUS.md`) |

This mockup is a **contract prototype**, not production Flutter code.
