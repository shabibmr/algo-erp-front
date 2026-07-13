import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:flutter/material.dart';

/// A jump target for the command palette (and future ManifestRegistry).
@immutable
class NavDestination {
  const NavDestination({
    required this.id,
    required this.label,
    required this.route,
    required this.group,
    this.icon = Icons.circle_outlined,
    this.keywords = const [],
    this.requiredModule,
  });

  final String id;
  final String label;
  final String route;
  final String group;
  final IconData icon;
  final List<String> keywords;
  final String? requiredModule;
}

/// Flat navigation index: binder hubs + hub masters + reports + create paths.
abstract final class NavigationRegistry {
  static List<NavDestination> all() {
    final out = <NavDestination>[];

    // Binder entries and utility pages.
    for (final item in [...AppMenu.allItems, ...AppMenu.utilityItems]) {
      out.add(
        NavDestination(
          id: 'menu:${item.route}',
          label: item.label,
          route: item.route,
          group: 'Jump to',
          icon: item.icon,
          requiredModule: item.requiredModule,
          keywords: _tokens(item.label, item.route),
        ),
      );
    }

    // Hub tiles, grouped by the business domain that owns them — so a sales
    // invoice files under Sales, not under its `/transactions` route prefix.
    // Cross-links are skipped: they are the same destination seen from a
    // second hub, and would show up twice.
    final seen = <String>{};
    for (final hub in AppMenu.hubs.values) {
      if (!hub.inBinder) continue;
      for (final item in hub.tiles) {
        if (!seen.add(item.route)) continue;
        out.add(
          NavDestination(
            id: 'tile:${item.route}',
            label: item.label,
            route: item.route,
            group: hub.label,
            icon: item.icon,
            requiredModule: item.requiredModule,
            keywords: _tokens(item.label, item.route, hub.label),
          ),
        );
      }
    }

    for (final r in ReportCatalog.all) {
      out.add(
        NavDestination(
          id: 'report:${r.id}',
          label: r.title,
          route: '/reports/${r.id}',
          group: 'Reports',
          icon: Icons.bar_chart_outlined,
          requiredModule: r.requiredModule,
          keywords: _tokens(r.title, r.id, 'report'),
        ),
      );
    }

    // High-traffic create shortcuts.
    const creates = <(String, String, IconData)>[
      ('New sales invoice', '/transactions/sales-invoices/new', Icons.receipt),
      ('New ledger', '/accounts/ledgers/new', Icons.menu_book),
      ('New item', '/inventory/item/new', Icons.inventory),
      ('New employee', '/employee/employees/new', Icons.person_add),
      (
        'New leave request',
        '/employee/leave-requests/new',
        Icons.event_available,
      ),
    ];
    for (final (label, route, icon) in creates) {
      out.add(
        NavDestination(
          id: 'action:$route',
          label: label,
          route: route,
          group: 'Actions',
          icon: icon,
          keywords: _tokens(label, route, 'new', 'create'),
        ),
      );
    }

    return out;
  }

  static List<NavDestination> search(String query) {
    final q = query.trim().toLowerCase();
    final destinations = NavigationRegistry.all();
    if (q.isEmpty) return destinations;
    final scored = <(int, NavDestination)>[];
    for (final d in destinations) {
      final keywordHay = d.keywords.map((String k) => k.toLowerCase());
      final hay = [
        d.label.toLowerCase(),
        d.route.toLowerCase(),
        d.group.toLowerCase(),
        ...keywordHay,
      ].join(' ');
      final labelLower = d.label.toLowerCase();
      if (!hay.contains(q) && !labelLower.contains(q)) {
        final tokens = q.split(RegExp(r'\s+'));
        if (!tokens.every(hay.contains)) continue;
      }
      var score = 0;
      if (labelLower.startsWith(q)) score += 100;
      if (labelLower.contains(q)) score += 40;
      if (d.route.toLowerCase().contains(q)) score += 20;
      scored.add((score, d));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final e in scored) e.$2];
  }

  static List<String> _tokens(String a, [String? b, String? c, String? d]) {
    return [a, if (b != null) b, if (c != null) c, if (d != null) d];
  }
}
