# Sales Invoice editor — replicate `docs/images/invoice editor.png`

> **Status (2026-07-23): partially implemented — active plan, not a completed record.**
> **Phases 0–1 shipped** (2026-07-16): `_DocumentTopStrip`, header/breadcrumb tokens, Notes
> counter, Attachments placeholder, `DocumentSurface` summary lines (taxable, Round Off), action
> captions. **Phases 2–5 outstanding:** Items toolbar (Scan Barcode / Import Items / Quick
> Filters / Add-another-line), full grid columns, summary polish, page shell, visual-system pass.

## Goal

Replicate the layout and product density of `docs/images/invoice editor.png`. Earlier “Webby” iterations removed fields such as Project and Convert From and simplified chrome. The mock is a dense ERP document shell: dual top strips, Invoice Details card, full Items toolbar/grid, Notes + Attachments, right-rail Summary with sticky-ish actions, and page-level chrome (badge, breadcrumb, shortcuts footer).

**Fidelity targets (be explicit — “exactly” is not free):**

| Level | Meaning | Status of *this* plan alone |
|-------|---------|------------------------------|
| **Structural ~70%** | Top strip(s), 75/25 split, restored fields, notes/attachments, bordered line cells | Achievable; much already started in code |
| **Product ~90%** | Full grid columns, toolbars, dual top cards, summary empty-state, page chrome | Needs the zone work below |
| **Pixel-exact** | Token density, radii, glass cards, microcopy, keyboard footer | Separate design-token / golden pass |

This document keeps the original structural plan and adds gaps, current-code notes, architecture caution, phased work, and a stronger verification checklist.

---

## Screenshot inventory (zones)

Use this as the source of truth when implementing or reviewing.

| Zone | Mock content |
|------|----------------|
| **Page chrome** | Title **Sales Invoice** + **Draft** badge; breadcrumb Home › Sales › Invoices › New Sales Invoice; **More actions** + Help |
| **Top strip (two cards)** | **Left:** Customer picker + Outstanding / Credit Limit / Available Credit / Last Invoice / Last Payment. **Right:** Today’s Sales, Financial Year, Invoice No. (auto-numbered) |
| **Invoice Details** | Row 1: Salesman, Godown / Warehouse, Project. Row 2: Voucher Date, Voucher No., Convert From, Billing Name, Credit Days (+ field helpers) |
| **Items** | Card title + **Add Item**, **Scan Barcode**, **Import Items**, **Quick Filters**. Columns: #, Item, SKU, Batch, Qty, Unit, Rate (AED), Disc %, Tax %, Amount (AED). Drag handle, search helpers, gear, trash; dashed **Add another line** |
| **Bottom left** | Notes (char counter) + Attachments drop zone side by side |
| **Right rail** | **Summary (AED):** Items Total, Discount, Taxable Amount, Total Tax, Round Off, Grand Total; empty-state tip; **Save Draft** (outlined) + **Post Invoice** (solid teal, split chevron); helper captions under buttons |
| **App footer** | Shortcuts (Ctrl+S, Ctrl+P, …) + support phone/email |
| **Look** | Dark glass cards, teal accents, dense bordered inputs |

---

## Current code (as of plan update)

Much of the *structural* work is already present — treat remaining work as **parity with the mock**, not greenfield layout.

| Area | Location | Notes |
|------|----------|--------|
| Desktop 3∶1 + `topBar` | `lib/core/surfaces/document_surface.dart` | Left scroll + fixed-width (~320) sidebar; not true sticky |
| SI wiring | `sales_invoice_form_page.dart` | `topBar: _CustomerMetricsBar()`, `header: _FormHeader()`, `footer: _FormFooter()` |
| Project / Convert From / source | same | Fields restored; second-row source voucher row exists |
| Customer metrics | `_CustomerMetricsBar` | Customer + metrics; **hardcoded** last invoice/payment/outstanding demos |
| Line columns | SI form columns | Still uses `hideLabel: true` in places; missing SKU/Batch/Unit/Amount vs mock |
| Totals | `_TotalsBar` in `DocumentSurface` | Subtotal / discount / tax / total — **no** Taxable Amount, Round Off, empty-state card, split Post |

Do **not** re-land “add topBar / split columns” as if missing; extend and polish.

---

## Original proposed changes (kept)

### 1. `lib/core/surfaces/document_surface.dart`

Dashboard layout for the mock:

- Desktop `Row`:
  - **Left (flex ~3):** `header`, line grid, `footer` (Notes / Attachments)
  - **Right (~1 / fixed width):** summary + actions (`Save Draft`, `Post Invoice`)
- Optional **`topBar`** above the two columns (customer / metrics strip)

**Refinements vs original wording:**

- Prefer **true sticky** right rail (`Align` + viewport height / `CustomScrollView` slivers) over a second `SingleChildScrollView` that scrolls away with content.
- Drop or raise the hard-coded **420px** line-grid height so the Items card can grow like the mock.
- Keep shared surface **generic**; SI-only density (toolbars, dual top cards, page chrome) should live in SI presentation or optional slots (`itemsToolbar`, `summaryExtra`, `pageChrome`) so item_qty / stock / payment forms do not inherit SI chrome by accident.

### 2. `lib/features/transactions_sales_invoice/presentation/sales_invoice_form_page.dart`

- **Top bar:** `_CustomerMetricsBar` → customer + Outstanding, Credit Limit, Available Credit, Last Invoice, Last Payment.
- **Form header:** Project, Convert From / source; **Invoice Details** card, two-row desktop grid.
- **Footer:** Notes card + placeholder Attachments card in a `Row`.
- **Line items:** Prefer bordered cells (`hideLabel` / `isBorderless` off or false for grid aesthetic).

### 3. Core field widgets

- Keep `isBorderless` / `hideLabel` APIs; set **false** for line grid cells in the mock aesthetic.
- Buttons: Save Draft outlined; Post solid teal / success green per mock.

---

## Gaps the original plan did not cover (required for product parity)

### A. Dual top strip (not one bar)

Mock has **two** top modules:

1. Customer + AR metrics (partially implemented).
2. **Today’s Sales · Financial Year · Invoice No. (auto-numbered)** — **not in original plan**, not in current bar.

Implement as either a second card in `topBar` or a `Row` of two cards under page chrome.

### B. Items card is more than border styling

Missing from plan (and generic `LineItemGrid` + current SI columns):

| Missing | Notes |
|---------|--------|
| Columns SKU, Batch, Unit, Amount | Domain + wire + UI |
| Row # + drag handle | Grid UX |
| Toolbar: Add Item, Scan Barcode, Import Items, Quick Filters | Real feature or labeled stub |
| Per-cell placeholders / helpers | “Search item…”, “Pick item first”, etc. |
| Column gear, trash styling | Match mock affordances |
| Dashed “Add another line” | Beyond default `newRow` |
| Flexible card height | Replace fixed 420 box |

Turning off borderless/hideLabel only adjusts input chrome.

### C. Summary rail shape

Beyond “totals + green Post”:

- Card title **Summary (AED)**
- Lines: Items Total, Discount, **Taxable Amount**, Total Tax, **Round Off**, Grand Total
- Empty-state callout when no complete lines
- Helper captions under Save / Post
- **Split** Post control (primary + chevron menu) if product wants it
- Sticky behavior (see DocumentSurface refinements)

Round-off needs **LineEngine / draft state**, not only paint.

### D. Page chrome & global footer

Not in original plan:

- Draft badge, breadcrumb, More actions, Help
- Keyboard shortcuts strip + support contacts

Without these, the screen still reads as “our form with a sidebar,” not the mock shell.

### E. Data / backend honesty

| UI | Plan implication | Reality |
|----|------------------|---------|
| Outstanding / last invoice / last payment | Metrics bar | API or clearly labeled demo data (stop silent hardcode) |
| Today’s sales | Not planned | Endpoint or hide until ready |
| Auto invoice no. / FY | Implied by mock | Voucher series / tenant FY |
| Attachments | Placeholder OK for v1 | Real upload later |
| Scan / import / filters | Not planned | Stub with disabled + tooltip, or cut from scope |
| Round-off | Not planned | Engine + field |

### F. Architecture decision (explicit)

| Option | When |
|--------|------|
| **A. SI-only shell** | Mock is SI-specific; other vouchers keep thinner `DocumentSurface` | **Recommended default** |
| **B. Shared surface rewrite** | All document vouchers should look like the mock | Requires optional slots + feature flags so simpler vouchers stay simple |

Rewriting `DocumentSurface` for SI density without slots will regress other families.

---

## Phased delivery (recommended)

### Phase 0 — Baseline honesty

- Document what already ships vs mock (this file).
- Mark hardcoded metrics as demo or wire real APIs.
- Decide Option A vs B above.

**Done (2026-07-16):** demo AR figures labeled; Option A retained (SI form + light shared `DocumentSurface` slots only).

### Phase 1 — Structural parity (original plan + dual top)

- Dual top strip (customer metrics + session/invoice meta).
- Invoice Details density + helpers.
- Notes + Attachments layout polish.
- Bordered line cells; button styles.
- Summary labels closer to mock (even if round-off is 0).

**Done (2026-07-16):** `_DocumentTopStrip` (metrics + session card); header tokens/breadcrumb; Notes 500-char counter; Attachments “Coming soon”; line **Amount** column + Rate label; `DocumentSurface` summary lines (taxable, round off 0, empty hint) + action captions.

### Phase 2 — Items product surface

- Column model: SKU, Batch, Unit, Amount (+ domain).
- Items toolbar (implement or stub consistently).
- Grid row chrome (handle, delete, add-another-line).
- Flexible height / scroll inside Items card only.

### Phase 3 — Summary + actions polish

- Full summary lines + empty state.
- Round-off in engine if in scope.
- Split Post if required; sticky rail.

### Phase 4 — Page shell

- Badge, breadcrumb, More actions, Help.
- Shortcuts footer (wire real shortcuts where feasible).

### Phase 5 — Visual system

- Tokens / glass cards / density to approach dark mock.
- Optional golden tests against `docs/images/invoice editor.png` (desktop breakpoint).

---

## Verification plan

### Automated

1. `flutter analyze` clean on touched packages.
2. `flutter test` — at least form bloc tests + any new cubit/engine tests for round-off / totals lines.
3. Optional: golden or layout test for desktop width asserting presence of dual top strip, Invoice Details, Items toolbar, Summary, Notes/Attachments.

### Manual (zone checklist vs `docs/images/invoice editor.png`)

Do **not** stop at “Project is visible.”

- [ ] Page chrome: Draft badge, breadcrumb, More actions, Help  
- [ ] Dual top: customer metrics **and** Today’s Sales / FY / Invoice No.  
- [ ] Metrics: no silent fake numbers (demo label or live data)  
- [ ] Invoice Details: full two-row field set + helpers  
- [ ] Project + Convert From (+ source voucher when type ≠ None)  
- [ ] Items toolbar + column set matches agreed scope  
- [ ] Bordered line inputs; add-another-line affordance  
- [ ] Notes + Attachments side by side  
- [ ] Summary lines + grand total emphasis + empty state  
- [ ] Save Draft outlined; Post solid; captions if in scope  
- [ ] Desktop ~75/25; right rail doesn’t feel broken on scroll  
- [ ] Mobile/tablet: stacked layout still usable (mock is desktop-first)  
- [ ] Other voucher forms (item_qty, stock, …) not regressed if DocumentSurface changed  

### Out of scope unless explicitly pulled in

- Pixel-perfect font/spacing match without design tokens pass  
- Full attachment storage pipeline  
- Barcode scanner hardware integration  
- Exact mock phone number / support email copy (use product config)

---

## Definition of done (revised)

- [ ] Structural layout matches mock zones (Phase 1+)  
- [ ] No field regressions: Project, Convert From, Billing Name, Credit Days, etc.  
- [ ] Metrics and “today’s sales” either real or clearly demo  
- [ ] SI-only chrome does not force other vouchers into SI density (unless Option B)  
- [ ] Analyze + tests green; manual zone checklist signed off at the agreed fidelity level (structural vs product vs visual)  

**Bottom line:** The original three sections remain the backbone for **layout idea** (~70%). Product-faithful replication of `invoice editor.png` requires the gap sections and phases above — the original plan alone is **necessary but not sufficient** for “match the image exactly.”
