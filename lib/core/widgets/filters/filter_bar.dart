import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// One filter chip's data: a label plus whether it is currently selected.
/// [FilterBar] is pure UI — it reports taps via [FilterBar.onFilterToggled]
/// and lets the caller (typically a `CrudBloc`'s `CrudFilterChanged` event)
/// own the actual filter state.
@immutable
class FilterChipData {
  const FilterChipData({
    required this.key,
    required this.label,
    this.selected = false,
  });

  /// Stable identifier reported back in [FilterBar.onFilterToggled] —
  /// distinct from [label] so the label can be localized freely.
  final String key;
  final String label;
  final bool selected;
}

/// A horizontal search + filter-chip row for list screens. Carries no data
/// logic of its own — it only reports a debounced-by-caller search string
/// and filter-chip toggles, matching `PageQuery.search`/`filters`.
///
/// ```dart
/// FilterBar(
///   searchHint: 'Search brands...',
///   onSearchChanged: (q) => context.read<BrandCrudBloc>()
///       .add(CrudSearchChanged(q)),
///   filters: const [FilterChipData(key: 'active', label: 'Active')],
///   onFilterToggled: (key) => ...,
/// )
/// ```
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    this.searchHint,
    this.onSearchChanged,
    this.searchController,
    this.filters = const [],
    this.onFilterToggled,
    this.trailing,
  });

  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final List<FilterChipData> filters;
  final ValueChanged<String>? onFilterToggled;

  /// Extra actions rendered at the end of the row (e.g. a "New" button).
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        for (final filter in filters)
          FilterChip(
            label: Text(filter.label),
            selected: filter.selected,
            onSelected: onFilterToggled == null
                ? null
                : (_) => onFilterToggled!(filter.key),
          ),
        if (trailing != null) ...trailing!,
      ],
    );
  }
}
