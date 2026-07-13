# Desk Dashboard — chart insights plan

> Status: shipped. Tracks the work that turned Today's Desk (`lib/features/desk/`) from
> text-only KPI tiles into a chart-driven "corporate dashboard" using `fl_chart`, plus the
> one backend endpoint it needed. Kept as the durable design record for this feature.

## Why

Today's Desk (`TodaysDeskPage`) is the app's home surface. It currently shows four numeric
`_PulseTile`s (sales count, purchase count, cash position, bank position) and a plain text
list of top customers — no visuals. The ask: make it read as a corporate dashboard, with
charts, using the (new) `fl_chart` dependency.

The backend has no time-series endpoint for the desk — `GET /reports/dashboard` only returns
a single-period snapshot. A month-over-month trend chart needs real backend support, so this
plan adds one additive endpoint rather than faking a trend with N client-side snapshot calls.

## 1. Backend: `GET /reports/dashboard/trend`

New, additive endpoint alongside the existing `/reports/dashboard` and `/reports/alerts` in
`models/backend/src/modules/transactions/`. Nothing about the existing two routes changes.

### Route

`dashboard.routes.ts`:

```ts
router.get(
  '/dashboard/trend',
  authorize('Transactions', 'read'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const q = req.query as Record<string, string>;
      const months = Math.min(24, Math.max(1, Number(q.months) || 6));
      const data = await DashboardService.getTrend({
        company_id: q.company_id ? Number(q.company_id) : undefined,
        branch_id: q.branch_id ? Number(q.branch_id) : undefined,
        months,
      });
      return res.status(200).json({ success: true, data, requestId: req.requestId });
    } catch (err) {
      return next(err);
    }
  },
);
```

Same auth (`authenticate` at router level) and RBAC (`authorize('Transactions', 'read')`) as
the sibling `/dashboard` route — no new permission introduced.

### Service

`dashboard.service.ts`, `DashboardService.getTrend({ company_id?, branch_id?, months })`:

- Computes `months` calendar-month buckets ending at the current month (oldest first).
- For each bucket, reuses the same three aggregations as `getSummary` (sales count, purchase
  count, cash/bank net position) scoped to that month's date range. Implementation runs them
  as one `Promise.all` fan-out across buckets (server-side, so N queries in parallel is cheap
  and doesn't cost the client N round-trips) rather than N sequential trips.
- No `top_customers` per bucket — that stays a single-period concept on `/reports/dashboard`.

### Response shape

```ts
{
  success: true,
  data: {
    points: [
      {
        month: string,        // 'YYYY-MM', bucket start, oldest first
        sales_count: number,
        purchase_count: number,
        cash_position: number,
        bank_position: number,
      },
      // ... one entry per month, oldest → newest
    ],
  },
  requestId: string,
}
```

### Params

| Param | Default | Notes |
|---|---|---|
| `months` | `6` | Clamped `[1, 24]` |
| `company_id` | — | Optional, same semantics as `/dashboard` |
| `branch_id` | — | Optional, same semantics as `/dashboard` |

## 2. Frontend

### New dependency

`pubspec.yaml`: add `fl_chart: ^0.69.0` (compatible with `sdk: ^3.12.0`).

### New domain model — `lib/features/desk/domain/dashboard_trend_point.dart`

`Equatable`, hand-written (no freezed/DTO layer — this feature already parses JSON directly in
its domain models, see `dashboard_summary.dart`):

```dart
class DashboardTrendPoint extends Equatable {
  final String month;          // 'YYYY-MM'
  final int salesCount;
  final int purchaseCount;
  final num cashPosition;
  final num bankPosition;
}
```

`fromJson` maps `month`, `sales_count`, `purchase_count`, `cash_position`, `bank_position`.

### `DeskRepository` — `lib/features/desk/data/desk_repository.dart`

Add `fetchTrend({int months = 6})`: `GET /reports/dashboard/trend?months=$months`, decode
envelope, map `data['points']` to `List<DashboardTrendPoint>`.

### `DeskCubit` / `DeskState` — `lib/features/desk/presentation/cubit/desk_cubit.dart`

Add `trend: List<DashboardTrendPoint>` (default `const []`) and `trendFailure: Failure?` to
`DeskState`. `load()` fetches dashboard, alerts, and trend together; a trend failure doesn't
blank the rest of the page (same per-section-failure pattern already used for
dashboard/alerts).

### Chart widgets — `lib/core/widgets/charts/`

Reusable, token-styled (via `context.tokens`: `brand.lagoon` primary, `brand.brass` for money,
`semanticColors.danger`/`brand.oxblood` for negative values, `brand.inkMuted` for
gridlines/labels; `spacing`/`radii` for card chrome). Plain typed inputs — no `fl_chart` types
in call sites.

- `chart_legend.dart` — color-dot + label + value row, used under/beside charts.
- `signed_bar_chart.dart` — grouped bar chart; used for both the sales-vs-purchase trend
  (one group per month, two bars) and any other two-series comparison.
- `ranked_bar_chart.dart` — horizontal ranked bars for "top N" (top customers by invoice
  count), replacing the current plain list rows.
- `share_donut_chart.dart` — donut/pie for part-of-whole breakdowns (cash vs bank share of
  liquid position).

### `TodaysDeskPage` — `lib/features/desk/presentation/pages/todays_desk_page.dart`

Keep the 4 `_PulseTile`s (fast-scan numbers). Below them, in the existing responsive
`LayoutBuilder` split:

- Sales vs purchase trend → `signed_bar_chart.dart`, fed by `state.trend`.
- Cash vs bank position → `share_donut_chart.dart`, fed by `state.dashboard`.
- Top customers → `ranked_bar_chart.dart` (falls back to current list rendering if empty).

### Tests

- `test/core/widgets/charts/*_test.dart` — smoke + data-mapping tests for each chart widget.
- `test/features/desk/` — extend cubit/repository tests (`bloc_test` + `mocktail`) for
  `fetchTrend` and the new `DeskState` fields, including the partial-failure path.

### Docs

- `docs/api-contract.md` — add the new endpoint under the Reports section.
- `docs/STATUS.md` — update the desk/dashboard rows to mention the trend endpoint + charts.
- `docs/widget-catalog.md` — new "Charts" section for the four widgets.
- Widget gallery (`WidgetGalleryPage`) — demo entry with sample data.

## Rollout

Additive only: new endpoint, new optional cubit fields with safe defaults (`const []` /
`null`), new widgets. The existing `/reports/dashboard` and `/reports/alerts` contracts are
untouched, so this ships without a breaking window.
