import 'package:flutter/material.dart';

/// A single navigation destination. [requiredModule]/[requiredAction] name
/// the RBAC permission that gates this item once `PermissionGate`/`RbacMixin`
/// land in Step 8 — until then every item renders unconditionally.
@immutable
class MenuItemModel {
  const MenuItemModel({
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
    this.requiredModule,
    this.requiredAction = 'read',
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final String? requiredModule;
  final String requiredAction;
}

@immutable
class MenuSectionModel {
  const MenuSectionModel({required this.items, this.title});

  final String? title;
  final List<MenuItemModel> items;
}

/// The single source of truth for the app's navigation menu. Every route
/// referenced here must exist in `app_router.dart`.
abstract final class AppMenu {
  static const List<MenuSectionModel> sections = [
    MenuSectionModel(
      items: [
        MenuItemModel(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/dashboard',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Organization',
      items: [
        MenuItemModel(
          label: 'Organization',
          icon: Icons.corporate_fare_outlined,
          selectedIcon: Icons.corporate_fare,
          route: '/organization',
          requiredModule: 'CompanyProfile',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Accounts',
      items: [
        MenuItemModel(
          label: 'Accounts',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance,
          route: '/accounts',
          requiredModule: 'Accounts',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Inventory',
      items: [
        MenuItemModel(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          route: '/inventory',
          requiredModule: 'Inventory',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Employee',
      items: [
        MenuItemModel(
          label: 'Employee',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          route: '/employee',
          requiredModule: 'Employee',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Transactions',
      items: [
        MenuItemModel(
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          route: '/transactions',
          requiredModule: 'Transactions',
        ),
      ],
    ),
    MenuSectionModel(
      items: [
        MenuItemModel(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          route: '/reports',
        ),
        MenuItemModel(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          route: '/settings',
        ),
        MenuItemModel(
          label: 'Theme preview',
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette,
          route: '/theme-preview',
        ),
      ],
    ),
  ];

  static List<MenuItemModel> get allItems =>
      sections.expand((s) => s.items).toList(growable: false);
}
