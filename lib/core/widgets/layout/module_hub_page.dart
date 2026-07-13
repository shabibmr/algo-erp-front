import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Landing page for a business domain: the tiles of a [ModuleHub], banded by
/// [MenuGroup], with the hub's cross-links in a trailing Related band.
///
/// The binder shows only hub routes; masters and voucher types open from here.
/// Tiles the user may not read are filtered out, and a group whose tiles all
/// filter out disappears with them.
class ModuleHubPage extends StatelessWidget {
  const ModuleHubPage({required this.hub, this.permissions, super.key});

  final ModuleHub hub;

  /// Injected in tests; resolves from the container otherwise.
  final PermissionService? permissions;

  /// The tiles of [masters] the current user may read.
  static List<MenuItemModel> destinationsFor(
    List<MenuItemModel> masters, {
    PermissionService? permissions,
  }) {
    final service = permissions ?? getIt<PermissionService>();
    return [
      for (final item in masters)
        if (item.requiredModule == null ||
            service.can(item.requiredModule!, PermissionAction.read))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    final groups = <MenuGroup>[
      for (final group in hub.groups)
        if (destinationsFor(group.items, permissions: permissions)
            case final items when items.isNotEmpty)
          MenuGroup(title: group.title, items: items),
    ];
    final related = destinationsFor(hub.crossLinks, permissions: permissions);

    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: hub.eyebrow,
            title: hub.label,
            subtitle: hub.subtitle,
          ),
          SizedBox(height: tokens.spacing.lg),
          Expanded(
            child: WorkSheet(
              child: groups.isEmpty && related.isEmpty
                  ? Center(
                      child: Text(
                        'No destinations available for your role.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(tokens.spacing.md),
                      children: [
                        for (final group in groups) ...[
                          if (group.title != null)
                            _BandTitle(title: group.title!),
                          _TileGrid(items: group.items),
                          SizedBox(height: tokens.spacing.lg),
                        ],
                        if (related.isNotEmpty) ...[
                          Divider(color: brand.mist),
                          SizedBox(height: tokens.spacing.sm),
                          const _BandTitle(title: 'Related'),
                          _TileGrid(items: related, showOwner: true),
                        ],
                      ],
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Text(
              hub.footerHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandTitle extends StatelessWidget {
  const _BandTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tokens.brand.inkMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 11,
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.items, this.showOwner = false});

  final List<MenuItemModel> items;

  /// Cross-linked tiles name the hub that owns them, so the canonical home of
  /// a shared master stays legible.
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 3
            : width >= 700
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: tokens.spacing.md,
            crossAxisSpacing: tokens.spacing.md,
            childAspectRatio: crossAxisCount == 1 ? 3.2 : 2.4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final owner = showOwner ? AppMenu.owningHub(item.route) : null;
            return _HubTile(
              item: item,
              blurb: owner == null
                  ? item.blurb
                  : 'In ${owner.label} · ${item.blurb}',
              onTap: () => context.go(item.route),
            );
          },
        );
      },
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.item,
    required this.blurb,
    required this.onTap,
  });

  final MenuItemModel item;
  final String blurb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final theme = Theme.of(context);

    return Material(
      color: brand.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radii.lg),
        side: BorderSide(color: brand.mist),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: brand.lagoon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.radii.md),
                ),
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacing.sm),
                  child: Icon(
                    item.selectedIcon ?? item.icon,
                    color: brand.lagoon,
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: brand.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xxs),
                    Text(
                      blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: brand.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: brand.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
