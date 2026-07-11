# algoERP — UI Design Plan

> **Codename:** *Ledger & Linen*  
> **Status:** Decisions locked · **Slice A shipped** · **Slice B shipped** (binder shell + context strip + Today’s Desk)  
> **Date:** 2026-07-11  
> **Companion to:** `docs/BUILD_TASKS_V2.md` (visual layer for Waves A2–A9)  
> **Stack constraint:** free / first-party only — Material 3 + owned tokens + free fonts. No paid kits.

---

## 0. Grounding (what this product actually is)

| Axis | Choice |
|------|--------|
| **Subject** | **algoERP** — online-first ERP for UAE SMEs: masters, vouchers, ledgers, stock, people. |
| **Audience** | Daily operators: accountant, sales clerk, warehouse, admin. Live in the app 6–10 hours. Not “tourists.” |
| **Job of the UI** | Make dense transactional work feel **calm, personal, and trustworthy** — like a well-kept desk you return to every morning — without sacrificing scan speed, keyboard paths, or RTL. |
| **Architecture reality** | Manifest-rendered **Surfaces** (not 40 unique screens). One visual language must scale across every master and voucher. |
| **Differentiators to *feel*** | Command palette · adaptive shell · decimal-precise documents · personal company/branch/FY context |

**Current baseline (to evolve, not throw away):**  
`AppTokens` + Material seed `#2563EB` + compact density + light/dark + en/ar + `MotionTokens` + generic rail shell. Functional scaffold; emotionally neutral SaaS-blue. This plan replaces that neutrality with a **specific desk identity**.

---

## 1. Thesis (one sentence)

> **Your company’s desk, not a generic ERP console** — paper-calm surfaces, ink-clear type, lagoon seals for action, and a soft “desk lamp” focus when the work gets serious.

### Fusion that means something

| Real-world material | Maps to product meaning |
|---------------------|-------------------------|
| **Linen desk cloth** | Soft app canvas — long sessions without eye fatigue |
| **Ledger ink** | Precise body type & table rules — money & codes never fuzzy |
| **Gulf lagoon water** | Primary action color — UAE-rooted without flag kitsch |
| **Brass seal / office stamp** | Primary CTA + money highlights — “this commits” |
| **Desk lamp** | Focus mode on forms & vouchers — personal attention on *this* document |
| **Sticky notes** | “Needs you” work queue on home — human priority, not KPI vanity |

This is **not** “dark mode trading terminal,” not “cream + terracotta lifestyle SaaS,” and not “newspaper broadsheet admin.”

---

## 2. Signature element (spend boldness once)

### ★ The Desk Lamp + Today’s Desk

**A. Today’s Desk (home)**  
Home is not a KPI billboard. It is a **personal desk surface**:

- Warm greeting: name · company · branch · financial year  
- **Needs you** — draft vouchers, approvals, credit alerts as soft “note” cards (short, actionable)  
- **Continue** — last 3–5 documents/masters you touched  
- **Quiet pulse** — 2–3 real numbers only if they answer “what should I do next?” (e.g. *3 invoices awaiting approval*), never a decorative stat grid  

**B. Desk Lamp (focus canvas)**  
When the user opens a **Master form** or **DocumentSurface** (voucher):

- Sidebar opacity softens slightly  
- Content canvas gains a subtle lagoon **rim light** (1–2px inner edge + very soft ambient wash)  
- App bar title becomes the document identity (*Sales Invoice · Draft · INV/…*)  
- Ambient motion is near-zero; only status changes and totals animate  

**Why this is the signature:** operators feel *attended to* without cartoon. It encodes “this is your work right now” — functional focus, personal comfort, memorable once.

Everything else stays disciplined: quiet chrome, consistent density, no second gimmick.

---

## 3. Color system (named tokens → hex)

Implement as **named roles** on `AppTokens` / `ColorScheme` — widgets never hardcode.

### Light — *Morning desk*

| Token | Hex | Role |
|-------|-----|------|
| **Linen** | `#F1EDE6` | App scaffold / page background (cool-linen, not pure cream) |
| **Paper** | `#FBF9F6` | Cards, tables, dialogs, form surfaces |
| **Mist** | `#E4E9EE` | Rail, zebra rows, chips background, dividers soft |
| **Ink** | `#1A2330` | Primary text (blue-slate ink, never pure black) |
| **Ink muted** | `#5C6778` | Secondary labels, helper text, table headers |
| **Lagoon** | `#0E6B68` | Primary actions, focus rim, selected nav |
| **Lagoon soft** | `#D7EFED` | Selected row wash, soft chips, focus fill |
| **Brass** | `#B8843B` | Money accents, “attention” icons, voucher number emphasis |
| **Oxblood** | `#8F3535` | Destructive only (delete, reject) |
| **Success moss** | `#2F6F4E` | Posted / success (earthy, not neon) |

### Dark — *Night desk*

| Token | Hex | Role |
|-------|-----|------|
| **Night** | `#11161D` | Scaffold |
| **Panel** | `#1A212B` | Cards / tables |
| **Mist dark** | `#2A3340` | Dividers / rail |
| **Ink light** | `#E8ECF1` | Text |
| **Lagoon glow** | `#3CB8B0` | Primary / focus |
| **Brass soft** | `#D9A45C` | Money accents |
| **Oxblood soft** | `#E07A7A` | Destructive |

### Domain colors (keep separate — already partly in `VoucherStatusColors`)

Retune status hues to sit on Linen/Paper without shouting:

| Status | Light intent |
|--------|----------------|
| Draft | Ink muted gray |
| Approved | Lagoon (trust, ready) |
| Posted | Success moss |
| Cancelled / Rejected | Oxblood family |
| Pending sync (parked feature) | Brass |

**Avoid:** Material seed blue `#2563EB`, pure black type, pure white walls, acid green, default purple M3 secondary.

**Seed for `ColorScheme.fromSeed`:** Lagoon `#0E6B68`, then **override** surfaces to Linen/Paper so M3 doesn’t wash everything teal.

---

## 4. Typography

Free fonts only (add `google_fonts` — OSS — or bundle `.ttf` under `assets/fonts`).

| Role | Face | Use |
|------|------|-----|
| **Display** | **Fraunces** (soft optical size, weight 500–600) | Page titles, login brand wordmark, “Good morning, Rania” on Desk — **restrained**: never in tables |
| **Body / UI** | **IBM Plex Sans** | Navigation, labels, buttons, forms, master lists |
| **Figures** | **IBM Plex Mono** (tabular if available) | Amounts, qty, codes, voucher nos, TRN, dates in grids |

### Type scale (logical)

| Token | Size / weight | Example |
|-------|---------------|---------|
| `displaySm` | 28 / Fraunces 600 | Desk greeting |
| `titleLg` | 20 / Plex Sans 600 | Surface titles (*Brands*) |
| `titleMd` | 16 / Plex Sans 600 | Section headers in forms |
| `body` | 14 / Plex Sans 400 | Default UI |
| `bodySm` | 12 / Plex Sans 400 | Table secondary, captions |
| `label` | 11–12 / Plex Sans 500 · letter-spacing 0.02em | Column headers, eyebrow chips |
| `figure` | 13–14 / Plex Mono 500 | Money & codes — **always right-aligned in columns** |

**Arabic:** Prefer Plex / Noto as fallback chain; Fraunces only for LTR brand moments if Arabic display feels off — body stays Plex-compatible with `fontFamilyFallback`.

---

## 5. Layout language

### 5.1 Shell — *Binder spine*

```
┌──────────┬────────────────────────────────────────────┐
│  algo    │  [context: Co · Branch · FY]    [⌘K] [👤]  │
│  ──────  ├────────────────────────────────────────────┤
│  Desk    │                                            │
│          │   content canvas (Paper on Linen)          │
│  Sales   │                                            │
│  Purch.  │                                            │
│  Stock   │                                            │
│  Books   │                                            │
│  People  │                                            │
│  ──────  │                                            │
│  ⚙       │                                            │
└──────────┴────────────────────────────────────────────┘
```

- **Mobile:** drawer + compact top bar; Desk greeting collapses to one line.  
- **Tablet:** icon rail + tooltips.  
- **Desktop/large:** extended rail with **section titles** as quiet linen labels (not heavy caps bars).  
- Selected item: Lagoon soft pill + Lagoon icon — no loud fill block.  
- Top **context chip strip** (company / branch / FY) always visible when authenticated — *personal workplace*, not abstract app.

### 5.2 Master list surface — *Ledger sheet*

```
  Brands                              [ Search…        ]  [ + New Brand ]
  ────────────────────────────────────────────────────────
  Name              Code        Active
  ────────────────────────────────────────────────────────
  Acme Paints       ACME        ●
  Gulf Hardware     GHW         ●
```

- Header row: label style, Mist hairline under  
- Rows: Paper; hover → Lagoon soft 4–6% wash; selected → stronger soft  
- First identity column slightly heavier weight  
- Mobile: **index cards** (name primary, 2 secondary lines, trailing status)  
- Empty: invitation, not apology — *“No brands yet. Add the first brand your invoices will use.”*

### 5.3 Master form / detail — *Index card stack*

- Sections as soft Paper cards with titleMd, not numbered 01/02  
- Required fields marked with subtle Brass asterisk (not red until error)  
- Sticky footer actions on mobile: Cancel · Save  
- Desk Lamp rim active

### 5.4 Document surface (vouchers) — *Real form on the desk*

```
  ┌─ Sales Invoice ──────── Draft ────── INV/… ──┐
  │  Party  [ lookup ]     Date [  ]  Series [ ] │
  ├──────────────────────────────────────────────┤
  │  #  Item     Qty   Rate    Tax    Amount     │
  │  1  …        …     …       …      …          │
  │  + Add line                                  │
  ├──────────────────────────────────────────────┤
  │              Subtotal · Tax ·  TOTAL (figures) │
  │  [ Save draft ]  [ Post ]                    │
  └──────────────────────────────────────────────┘
```

- Totals bar sticks to bottom of canvas; figures in Plex Mono + Brass for **grand total only**  
- Lifecycle actions use seal buttons (Post) vs quiet tonal (Save draft) vs Oxblood text button (Cancel/Reject)  
- Status chip sits near title like a rubber stamp

### 5.5 Command palette — *The drawer*

- Centered Paper panel, max ~560px, soft elevation 3  
- Fraunces not used here — pure instrument UI  
- Groups: Jump to · Actions · Recent  
- Keyboard: `Ctrl/Cmd+K`, arrow + enter, esc  

### 5.6 Login — *Closed desk, open for the day*

- Split on desktop: left soft Lagoon/Linen abstract wash (subtle geometric “ledger lines”), right Paper card  
- Mobile: full Linen + single card  
- Copy: *“Sign in to your desk”* — not “Welcome to the future of ERP”  
- Brand: **algoERP** in Fraunces + small Lagoon seal mark  

---

## 6. Motion (subtle, one language)

Build only on `MotionTokens` (extend if needed; don’t invent ad-hoc ms).

| Moment | Motion | Duration / curve |
|--------|--------|------------------|
| Page enter | Fade + 6px rise | `standard` / `emphasizedCurve` |
| List first paint | Optional stagger **max 5 items**, then stop | `listStaggerStep` 30ms |
| Row hover (desktop) | Background wash | `hoverPress` |
| Seal button press | Scale 0.98 + shadow ease | `fast` |
| Desk Lamp on | Rim opacity 0 → 1 | `slow` once on route enter |
| Totals change | Figure cross-fade / slight tally tick | `fast` |
| Palette open | Fade + scale 0.98 → 1 | `standard` |
| Status → Posted | Chip color settle (no bounce) | `standard` |

**Rules:**

- Respect `MediaQuery.disableAnimations` / `prefers-reduced-motion` → opacity only or none  
- No parallax, no continuous ambient particle, no confetti  
- Motion **informs state**, never entertains  

---

## 7. Component expression (how atoms should *feel*)

Maps to Wave A2 widgets — visual contract only.

| Component | Expression |
|-----------|------------|
| `FilledButton` primary | **Seal** — Lagoon fill, slightly larger radius (`radii.lg`), soft Brass-tinted shadow on hover (desktop) |
| `OutlinedButton` | Ink border on Paper |
| Destructive confirm | Oxblood fill or outlined |
| Inputs | Paper fill, Mist border → Lagoon border on focus (2px), dense padding kept for ERP |
| `StatusChip` | Pill, soft tinted fill, no harsh border |
| `FilterBar` | Sits on Linen; search field is Paper inset |
| Tables | Hairline Mist rules; no heavy card chrome around every cell |
| Dialogs | Paper, `radii.xl`, title in titleMd |
| Snackbars | Bottom, muted Ink; success uses moss, not neon |
| KPI (if used) | Prefer **sentence cards** (*“3 invoices need approval”*) over big orphan numbers |

### Density dual-mode (functional fusion)

| Mode | When | Density |
|------|------|---------|
| **Clerk** (default desktop) | Lists, grids, vouchers | `VisualDensity.compact` — current plan |
| **Comfort** | Login, Desk home, settings, empty/error | Comfortable padding (`spacing.md/lg`) |

Same tokens; different surface recipes. Operators get density where money moves, air where they rest.

---

## 8. Voice & copy (personal, plain)

| Situation | Say | Don’t say |
|-----------|-----|-----------|
| Empty brands | “No brands yet. Add one to use on items and invoices.” | “No data found.” |
| Delete | “Delete brand Acme? This cannot be undone.” | “Are you sure?” alone |
| Save | “Save changes” / toast “Saved” | “Submit” / “Success” |
| Post voucher | “Post invoice” / “Posted · INV/0421” | “Execute workflow” |
| Error network | “Can’t reach the server. Check the connection and try again.” | “Something went wrong.” |
| Palette placeholder | “Jump to a page or action…” | “Search commands…” |
| Desk morning | “Good morning, {name}” (time-aware) | “Dashboard” as the only greeting |

Tone: calm colleague at the next desk. Sentence case. Active verbs. Same word for the same action everywhere.

---

## 9. Implementation map → BUILD_TASKS_V2

| Design piece | Where it lands |
|--------------|----------------|
| Palette + semantic roles | Expand `app_tokens.dart`, retune `app_theme.dart` seed/surfaces |
| Typefaces | `pubspec` + `AppTheme` textTheme; gallery preview |
| Shell / binder spine | `app_shell.dart` + menu section chrome |
| Context chips (co/branch/FY) | Shell app bar (after A1 session claims) |
| Desk home | Wave A8 dashboard → implement as **Today’s Desk**, not generic KPI grid |
| Desk Lamp focus | Shared `WorkCanvas` wrapper used by form/detail/document surfaces |
| Seal buttons / fields | Wave A2 atoms themed globally |
| Ledger list | `MasterListSurface` + `AdaptiveEntityList` styling |
| Document form language | Wave A6 `DocumentSurface` |
| Command palette drawer | Wave A3.4 / A8 |
| Motion | `motion_tokens.dart` + surface enter wrappers; A9 polish |
| Login desk | Auth login page restyle (A1 complete → visual pass) |
| Goldens | A9 alchemist: login, desk, list, invoice |

**Non-goals for this visual plan:** custom illustration library, paid icon packs, heavy textures that hurt web performance, redesign of EMR architecture.

### Suggested token additions (API sketch)

```dart
// conceptual — implement carefully under AppTokens / ColorScheme
// surfaceLinen, surfacePaper, surfaceMist
// ink, inkMuted
// lagoon, lagoonSoft
// brass, oxblood
// + existing semantic + voucherStatusColors (retuned)
```

### Risk check (uniqueness pass)

| Temptation | Why rejected / revised |
|------------|------------------------|
| Cream + terracotta + big serif | AI default #1 — linen is cooler/grayer; accent is lagoon+brass, not terracotta |
| Black + acid green | AI default #2 — night desk stays blue-slate, lagoon glow not neon |
| Broadsheet hairlines only | AI default #3 — we use soft Paper cards + desk metaphor, not newspaper grid |
| Generic blue M3 ERP | Current codebase default — explicitly replaced by Lagoon seed |
| Big KPI hero numbers | Template dashboard — replaced by **Needs you** narrative cards |
| Numbered section markers 01/02 | No sequence meaning — section titles only |

**Aesthetic risk we keep:** Desk Lamp focus + Fraunces only on human moments. Justified: personal comfort without breaking dense clerk work.

---

## 10. Decisions (locked 2026-07-11)

1. **Brand name:** **algoERP** as-is (logo art may read algoRay; product chrome stays algoERP).  
2. **Logo:** Source `../algoLogo.png` → `assets/brand/*` + platform icons.  
3. **Density:** Clerk compact default on desktop; comfort padding on login/Desk.  
4. **Climate:** Linen + Lagoon + Brass.  
5. **Dashboard data:** Honest empty placeholders until APIs.  
6. **First visual PR:** **A** — tokens + theme + login (+ logo pipeline).

---

## 11. First build slice (when you say go)

Recommended order after your answers:

1. Token + theme + fonts (foundation)  
2. Login restyle (emotional proof in one screen)  
3. Shell binder + context strip  
4. Today’s Desk skeleton (copy + layout, data later)  
5. WorkCanvas (Desk Lamp) on existing `MasterListSurface` / future forms  
6. Widget gallery update so A2 atoms inherit the language  

---

*End of plan. This is the visual north star; EMR architecture in BUILD_TASKS_V2 remains the structural north star.*
