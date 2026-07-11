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

## Filters

### `FilterBar` — `filters/filter_bar.dart`
Horizontal search field + `FilterChipData` chips + optional trailing
actions. Pure UI — no debounce, no state; wire `onSearchChanged` to a
`CrudSearchChanged` event (debounced in the bloc via
`debounceRestartable`) and `onFilterToggled` to a `CrudFilterChanged` event.

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
Renders `items` as a `DataTable` on tablet/desktop
(`context.isTablet || context.isDesktop`) and as a column of `Card`s on
mobile. Column defs (`EntityColumn<T>`) drive the table; `cardBuilder`
drives the mobile rendering. Same widget, same data, two adaptive shapes.

**Key props:** `items`, `columns` (list of `EntityColumn<T>` — `label`,
`cellBuilder`, `numeric`), `cardBuilder`, `onTap`, `keyOf` (stable key
extractor, e.g. `(e) => e.id`).

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
