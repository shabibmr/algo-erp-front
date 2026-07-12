import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Landing page for `/organization` — index of org masters, not a placeholder.
class OrganizationHubPage extends StatelessWidget {
  const OrganizationHubPage({super.key});

  /// Masters for the hub grid (not binder nav).
  /// See `AppMenu.organizationMasters`.
  static List<MenuItemModel> destinationsFor(PermissionService permissions) {
    return [
      for (final item in AppMenu.organizationMasters)
        if (item.requiredModule == null ||
            permissions.can(
              item.requiredModule!,
              PermissionAction.read,
            ))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final items = destinationsFor(getIt<PermissionService>());

    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            eyebrow: 'Masters',
            title: 'Organization',
            subtitle: 'Company, people, numbering, and system settings',
          ),
          SizedBox(height: tokens.spacing.lg),
          Expanded(
            child: WorkSheet(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1100
                      ? 3
                      : width >= 700
                      ? 2
                      : 1;
                  return GridView.builder(
                    padding: EdgeInsets.all(tokens.spacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: tokens.spacing.md,
                      crossAxisSpacing: tokens.spacing.md,
                      childAspectRatio: crossAxisCount == 1 ? 3.2 : 2.4,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _OrgHubTile(
                        item: item,
                        onTap: () => context.go(item.route),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Text(
              'Open a master to list, create, or edit records.',
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

class _OrgHubTile extends StatelessWidget {
  const _OrgHubTile({required this.item, required this.onTap});

  final MenuItemModel item;
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
                      _blurbFor(item.route),
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

  static String _blurbFor(String route) {
    return switch (route) {
      '/organization/companies' => 'Legal profile, TRN, and address',
      '/organization/branches' => 'Branches and locations',
      '/organization/currencies' => 'ISO currencies and base currency',
      '/organization/rates/history' => 'Daily buy / sell FX rates',
      '/organization/fy' => 'Open, close, and default financial years',
      '/organization/voucher-series' => 'Prefixes, numbering, approvals',
      '/organization/roles' => 'Roles and permission matrix',
      '/organization/users' => 'Logins, roles, and branches',
      '/organization/contacts' => 'Address book contacts',
      '/organization/projects' => 'Project hierarchy for vouchers',
      '/organization/config' => 'Key system settings',
      '/organization/audit-logs' => 'Read-only activity trail',
      '/organization/error-reports' => 'Captured client and server errors',
      _ => 'Open master',
    };
  }
}
