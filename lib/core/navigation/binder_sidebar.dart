import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Paper "binder spine" navigation — section labels + lagoon soft selection.
///
/// [extended] shows labels and brand word; collapsed is icon-only.
/// Pass [onToggleExtended] to show a collapse/expand control at the footer.
///
/// Content is always laid out at [extendedWidth] and clipped by an animated
/// outer width. That avoids the expand glitch where labels reflow on top of
/// icons while the rail is still mid-animation.
class BinderSidebar extends StatelessWidget {
  const BinderSidebar({
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    required this.extended,
    this.onToggleExtended,
    super.key,
  });

  /// Already RBAC-filtered by `AppShell`. [selectedIndex] is a flat index into
  /// these sections' items, so the filtering must not be repeated here.
  final List<MenuSectionModel> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  /// When set, a footer control toggles between icon-only and labeled modes.
  final VoidCallback? onToggleExtended;

  static const double collapsedWidth = 72;
  // 25% narrower than the original extended width (248).
  static const double extendedWidth = 186;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final width = extended ? extendedWidth : collapsedWidth;

    return Material(
      color: brand.paper,
      // Clip paint while width animates; content stays full-width underneath.
      clipBehavior: Clip.hardEdge,
      child: AnimatedContainer(
        duration: MotionTokens.standard,
        curve: MotionTokens.standardCurve,
        width: width,
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minWidth: extendedWidth,
          maxWidth: extendedWidth,
          child: SizedBox(
            width: extendedWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(showLabel: extended),
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
                if (onToggleExtended != null) ...[
                  Divider(height: 1, color: brand.mist),
                  _CollapseToggle(
                    extended: extended,
                    onPressed: onToggleExtended!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEntries(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final widgets = <Widget>[];
    var flatIndex = 0;

    for (final section in sections) {
      if (section.title != null) {
        // Keep a stable slot so tiles don't jump; fade the title with expand.
        widgets.add(
          _SectionTitle(
            title: section.title!,
            visible: extended,
            color: brand.inkMuted,
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.sm,
              tokens.spacing.md,
              tokens.spacing.sm,
              tokens.spacing.xs,
            ),
            collapsedHeight: tokens.spacing.sm,
          ),
        );
      }

      for (final item in section.items) {
        final index = flatIndex;
        final selected = index == selectedIndex;
        widgets.add(
          _NavTile(
            item: item,
            selected: selected,
            showLabel: extended,
            onTap: () => onSelect(index),
          ),
        );
        flatIndex++;
      }
    }
    return widgets;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.visible,
    required this.color,
    required this.padding,
    required this.collapsedHeight,
  });

  final String title;
  final bool visible;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double collapsedHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: MotionTokens.standard,
      sizeCurve: MotionTokens.standardCurve,
      firstCurve: MotionTokens.standardCurve,
      secondCurve: MotionTokens.standardCurve,
      crossFadeState: visible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Padding(
        padding: padding,
        child: Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      secondChild: SizedBox(height: collapsedHeight),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.showLabel});

  final bool showLabel;

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
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.hexagon_outlined, color: brand.lagoon, size: 32),
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: AnimatedOpacity(
              duration: MotionTokens.standard,
              curve: MotionTokens.standardCurve,
              opacity: showLabel ? 1 : 0,
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
          ),
        ],
      ),
    );
  }
}

class _CollapseToggle extends StatelessWidget {
  const _CollapseToggle({required this.extended, required this.onPressed});

  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final isRtl = context.isRtl;
    // Point inward when extended (collapse), outward when collapsed (expand).
    final icon = extended
        ? (isRtl ? Icons.chevron_right : Icons.chevron_left)
        : (isRtl ? Icons.chevron_left : Icons.chevron_right);
    final tooltip = extended ? 'Collapse navigation' : 'Expand navigation';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sm,
        vertical: tokens.spacing.xs,
      ),
      child: Align(
        // Sit under the icon column when collapsed; right edge when extended.
        alignment: extended
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: IconButton(
          key: const Key('binder-sidebar-toggle'),
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: brand.inkMuted),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final MenuItemModel item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final icon = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    final fg = selected ? brand.lagoon : brand.inkMuted;
    final bg = selected ? brand.lagoonSoft : Colors.transparent;

    // Always the same row geometry (icon left + label). Outer rail clips the
    // label when collapsed so expand never reflows icons over text.
    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(tokens.radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sm,
            vertical: tokens.spacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fg),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: AnimatedOpacity(
                  duration: MotionTokens.standard,
                  curve: MotionTokens.standardCurve,
                  opacity: showLabel ? 1 : 0,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? brand.lagoon : brand.ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final padded = Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.xxs),
      child: tile,
    );

    if (!showLabel) {
      return Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 400),
        child: padded,
      );
    }
    return padded;
  }
}
