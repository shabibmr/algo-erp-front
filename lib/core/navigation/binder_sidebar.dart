import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Paper "binder spine" navigation — section labels + lagoon soft selection.
///
/// [extended] shows labels and brand word; collapsed is icon-only (tablet).
class BinderSidebar extends StatelessWidget {
  const BinderSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.extended,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  static const double collapsedWidth = 72;
  static const double extendedWidth = 248;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final width = extended ? extendedWidth : collapsedWidth;

    return Material(
      color: brand.paper,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrandHeader(extended: extended),
            Divider(height: 1, color: brand.mist),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: tokens.spacing.sm,
                  horizontal: tokens.spacing.sm,
                ),
                children: _buildEntries(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntries(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final widgets = <Widget>[];
    var flatIndex = 0;

    for (final section in AppMenu.sections) {
      if (section.title != null && extended) {
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.sm,
              tokens.spacing.md,
              tokens.spacing.sm,
              tokens.spacing.xs,
            ),
            child: Text(
              section.title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: brand.inkMuted,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      } else if (section.title != null && !extended) {
        widgets.add(SizedBox(height: tokens.spacing.sm));
      }

      for (final item in section.items) {
        final index = flatIndex;
        final selected = index == selectedIndex;
        widgets.add(
          _NavTile(
            item: item,
            selected: selected,
            extended: extended,
            onTap: () => onSelect(index),
          ),
        );
        flatIndex++;
      }
    }
    return widgets;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.md,
        vertical: tokens.spacing.md,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radii.md),
            child: Image.asset(
              'assets/brand/algo_mark.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                Icons.hexagon_outlined,
                color: brand.lagoon,
                size: 32,
              ),
            ),
          ),
          if (extended) ...[
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(
                context.l10n.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: brand.ink,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final MenuItemModel item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final icon = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    final fg = selected ? brand.lagoon : brand.inkMuted;
    final bg = selected ? brand.lagoonSoft : Colors.transparent;

    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(tokens.radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? tokens.spacing.sm : 0,
            vertical: tokens.spacing.sm,
          ),
          child: extended
              ? Row(
                  children: [
                    Icon(icon, size: 22, color: fg),
                    SizedBox(width: tokens.spacing.sm),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: selected ? brand.lagoon : brand.ink,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                )
              : Center(child: Icon(icon, size: 22, color: fg)),
        ),
      ),
    );

    if (!extended) {
      return Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 400),
        child: tile,
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.xxs),
      child: tile,
    );
  }
}
