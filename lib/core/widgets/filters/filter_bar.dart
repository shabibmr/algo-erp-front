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

/// A search + filter-chip row for the toolbar of a work sheet. Carries no data
/// logic of its own — it only reports a debounced-by-caller search string
/// and filter-chip toggles, matching `PageQuery.search`/`filters`.
///
/// The search field grows with the sheet (up to [_searchMaxWidth]) instead of
/// sitting at a fixed width, and [trailing] is pushed to the far right. These
/// controls act on the sheet's contents; page-level actions belong on
/// `PageHeader`, not here.
///
/// ```dart
/// FilterBar(
///   searchHint: 'Search brands',
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

  /// Utility actions for this sheet (e.g. export), rendered at the far right.
  final List<Widget>? trailing;

  /// Past this the field is just a long empty box — a search term is short.
  static const double _searchMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: searchHint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
    );

    final chips = [
      for (final filter in filters)
        Padding(
          padding: EdgeInsetsDirectional.only(start: tokens.spacing.sm),
          child: FilterChip(
            label: Text(filter.label),
            selected: filter.selected,
            onSelected: onFilterToggled == null
                ? null
                : (_) => onFilterToggled!(filter.key),
          ),
        ),
    ];

    // On mobile the field takes the full width and everything else drops below
    // it — three controls on one line at that width is a scrum.
    if (context.isMobile) {
      final hasBelow = chips.isNotEmpty || (trailing?.isNotEmpty ?? false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          search,
          if (hasBelow) ...[
            SizedBox(height: tokens.spacing.sm),
            Row(
              children: [
                ...chips,
                const Spacer(),
                if (trailing != null) ...trailing!,
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        // Expanded (not Flexible + Spacer): the field caps itself at
        // _searchMaxWidth and the slack stays inside this slot, which is what
        // pushes the trailing actions to the sheet's right edge.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _searchMaxWidth),
              child: search,
            ),
          ),
        ),
        ...chips,
        if (trailing != null) ...trailing!,
      ],
    );
  }
}
