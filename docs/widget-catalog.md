# Widget Catalog (Track C — `lib/core/widgets/`)

Every widget below is theme-aware (pulls colors/spacing from `context.tokens`
/ `Theme.of(context)`, never a hardcoded value) and RTL-aware (uses
`EdgeInsetsDirectional`/`Directionality`-driven layout where it matters).
None depend on a bloc directly — they take plain data (`ViewState<T>`,
lists, callbacks) so they work from any state-management shape.

## Lifecycle

### `AsyncStateView<T>` — `async_state_view.dart`
Switches over a `ViewState<T>` (loading/empty/data/error) and renders the
matching branch. The one seam every list/detail screen should use instead of
hand-rolling its own `if (loading) ... else if (empty) ...`.

**Key props:** `state`, `builder(context, T)`, `onRetry`, `emptyMessage`,
`emptyIcon`, `emptyActionLabel`/`onEmptyAction`, `loadingMessage`.

```dart
AsyncStateView<List<Brand>>(
  state: state.toViewState(),
  onRetry: () => context.read<BrandCrudBloc>().add(const CrudRequested()),
  builder: (context, brands) => AdaptiveEntityList(...),
)
```

### `LoadingState` — `states/loading_state.dart`
Centered spinner + localized "Loading..." label. Used internally by
`AsyncStateView`'s loading branch; usable standalone too.

### `LedgerSkeleton` — `states/ledger_skeleton.dart`
First-paint placeholder for a ledger sheet: ruled rows with the ink not yet dry,
pulsing slowly (no shimmer sweep). Holds the sheet's shape while a list loads,
where a centered spinner would leave the sheet an empty box and then jump when
rows arrive. `MasterListSurface` uses this instead of `AsyncStateView`'s loading
branch for exactly that reason. **Key props:** `rows`, `columns`.

### `EmptyState` — `states/empty_state.dart`
Icon + localized "Nothing here yet" message + optional CTA button.
**Key props:** `message`, `icon`, `actionLabel`, `onAction`.

### `ErrorState` — `states/error_state.dart`
Icon (chosen by `Failure` subtype) + `failure.message` + optional retry
button. **Key props:** `failure`, `onRetry`.

## Chips

### `StatusChip` — `chips/status_chip.dart`
Colored pill for an `EntityStatus` (draft/approved/posted/cancelled/
rejected/pendingSync), colored from `AppTokens.voucherStatusColors` — never
a raw `Color`. Shows a sync icon automatically for `pendingSync`.

**Key props:** `status`, `label`.

```dart
StatusChip(status: EntityStatus.posted, label: 'Posted')
```

## Dialogs

### `showConfirmDialog` — `dialogs/confirm_dialog.dart`
`Future<bool> showConfirmDialog(context, {title, message, confirmLabel,
cancelLabel, destructive})`. Dismissing (barrier tap/back) resolves `false`,
never `null`. `destructive: true` colors the confirm button with
`tokens.semanticColors.danger`. Labels default to the platform's OK/Cancel
strings via `MaterialLocalizations`.

```dart
final ok = await showConfirmDialog(
  context,
  title: 'Delete brand?',
  message: 'This cannot be undone.',
  confirmLabel: 'Delete',
  destructive: true,
);
```

## Form fields (`fields/`)

All fields share the same shape: `label`, an optional `validator`, an
`onChanged`/`onSaved` pair, `enabled`, and rely on the app-wide
`AppTheme.inputDecorationTheme` for borders/padding — they only set
`labelText`/`hintText`/`helperText`/`errorText`.

| Widget | Wraps | Notes |
|---|---|---|
| `AppTextField` | `TextFormField` | Plain string field; `maxLines`, `prefixIcon`/`suffixIcon`. |
| `AppNumberField` | `TextFormField` | Parses to `int`; digit-only `TextInputFormatter`; `allowNegative`. |
| `AppDecimalField` | `TextFormField` | Parses to `package:decimal` `Decimal`; `maxDecimals` formatter; never `double`. |
| `AppCurrencyField` | `AppDecimalField` | 2-dp decimal field with a `currencySymbol` prefix (default `AED`). |
| `AppDateField` | `FormField<DateTime?>` + `showDatePicker` | Displays via `DateTimeFormatX.toDayString()`; value stays `DateTime`. |
| `AppSwitchField` | `SwitchListTile.adaptive` | Labeled boolean toggle (e.g. `is_active`). |
| `AppDropdownField<T>` | `DropdownButtonFormField<T>` | Generic single-select; `items`, `labelOf(T)`. |

```dart
AppDecimalField(
  label: 'Quantity',
  initialValue: line.quantity,
  onChanged: (v) => setState(() => line.quantity = v),
)
```

## Layout

### `PageHeader` — `layout/page_header.dart`
The band above a page's work surface: an eyebrow (where you are), a Fraunces
title, a subtitle on the title's baseline (the record count), and the page's
actions at the **far right**.

The create action belongs here, not beside the search field. Creating a record
is a page action; searching filters the sheet. Keeping them on separate bands
is what stops a list screen from reading as a row of unrelated controls. Below
tablet the actions drop to their own row.

**Key props:** `title`, `eyebrow`, `subtitle`, `actions`.

### `WorkSheet` — `layout/work_sheet.dart`
A sheet of paper on the linen desk. With `fill: true` (the default) it stretches
to the bottom of whatever bounded height it's given — so a list of eight rows
still reads as a full page rather than eight rows floating on the canvas. With
`fill: false` it hugs its content, which is how the form's index cards are
built. Pass a `toolbar` (the ledger case) or a `title` (the index-card case) to
get a header band above a full-strength rule.

It is a `Material`, so ink from rows and buttons inside it paints on the paper
rather than the canvas underneath.

**Key props:** `child`, `toolbar` *or* `title`, `fill`, `padding`.

## Filters

### `FilterBar` — `filters/filter_bar.dart`
The toolbar of a `WorkSheet`: a search field that grows with the sheet (capped
at 420px), `FilterChipData` chips, and `trailing` utility actions pushed to the
sheet's right edge. Pure UI — no debounce, no state; wire `onSearchChanged` to a
`CrudSearchChanged` event (debounced in the bloc via
`debounceRestartable`) and `onFilterToggled` to a `CrudFilterChanged` event.

These controls act on the sheet's *contents*. Page-level actions go on
`PageHeader`. Don't put a "New X" button in `trailing`.

**Key props:** `searchHint`, `onSearchChanged`, `filters`,
`onFilterToggled`, `trailing`.

## Lookup

### `FkLookupField<T>` — `lookup/fk_lookup_field.dart`
Read-only field that opens a searchable dialog backed by an async `loader`.
Debounces keystrokes with a `Timer` (`kFkLookupDebounce`, 350ms default)
before calling `loader` again — this is a self-contained widget, not a
screen, so it doesn't need the bloc-level `stream_transform` debounce.

**Key props:** `label`, `value`, `displayOf(T)`, `loader(query) →
Future<List<T>>`, `onSelected`.

```dart
FkLookupField<Brand>(
  label: 'Brand',
  value: selectedBrand,
  displayOf: (b) => b.name,
  loader: (query) => brandRepository.search(query),
  onSelected: (b) => setState(() => selectedBrand = b),
)
```

## Data display

### `AdaptiveEntityList<T>` — `data_display/adaptive_entity_list.dart`
Renders `items` as a `LedgerTable` from tablet up and as index cards on mobile.
**Both renderings are driven by the same `columns`**, so a screen declares its
data once; `cardBuilder` is only for overriding the default card (the primary
column as the card's heading, the rest as quiet label/value lines).

**Key props:** `items`, `columns` (list of `EntityColumn<T>` — `label`,
`cellBuilder`, `flex`, `minWidth`, `align`, `mono`, `primary`), `onTap`,
`keyOf` (stable key extractor, e.g. `(e) => e.id`), `footer` (the load-more
indicator), `cardBuilder` (optional override).

### `LedgerTable<T>` — `data_display/ledger_table.dart`
The ledger sheet's rows, and the app's signature surface. Columns flex to fill
the full width they're given — every column gets its `minWidth` first, and the
surplus is shared out by `flex` — so the table *is* the sheet rather than a
narrow island inside it. It falls back to horizontal scrolling only when the
minimum widths genuinely don't fit.

Rows are separated by a faint rule, and **every fifth rule is drawn at full
strength** — the way a paper ledger pad rules in fives so the eye can count down
a column without losing its place. Hovering or focusing a row lights a lagoon
edge in its left gutter. The rhythm and both rule colors come from
`AppTokens.ledger` (`LedgerTokens`); nothing else should hardcode a row divider.

The header row is a sibling of the scrolling list, not an item in it, so it
stays put while rows scroll under it. Given an unbounded height (a gallery, a
page that scrolls as a whole) the table hugs its rows instead of throwing.

**Key props:** `items`, `columns` (`LedgerColumn<T>`), `onTap`, `keyOf`,
`footer`.

Manifest-driven screens never build these by hand: `MasterListSurface` derives
each column from the entity's `FieldSpec`, and **`align`/`mono` are derived from
`FieldType`** — `int` and `decimal` render right-aligned in tabular mono figures
(`AppTokens.figures`, IBM Plex Mono) so digits stack on the decimal. Override on
the `FieldSpec` only when the derivation is wrong.

### `LineItemGrid<R>` — `data_display/line_item_grid.dart`
Editable rows-of-fields grid for voucher line items, with add/remove-row
affordances. Generic over the row model `R`; each `LineItemColumn<R>`
builds its cell from `(context, row, index)` — typically an
`AppDecimalField`/`FkLookupField` — and the row model itself owns mutation;
`onChanged(List<R>)` is called with the full list on add/remove.

**Key props:** `rows`, `columns`, `onChanged`, `newRow` (factory for the
add-row button; omit to hide it), `addLabel`, `enabled`.

## Gallery

### `WidgetGalleryPage` — `gallery/widget_gallery_page.dart`
Self-contained showcase of every widget above, with toolbar toggles for
light/dark theme and LTR/RTL direction (matching `ThemePreviewPage`'s
idiom). No bloc, no DI, no routing dependency — see the WIRING REPORT for
the suggested route.
