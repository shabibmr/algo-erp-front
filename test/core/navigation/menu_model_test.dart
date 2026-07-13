import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/navigation/app_router.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads exactly the modules it is given, denies everything else — the same
/// fail-closed shape the backend uses for a role with no matrix row.
class _FakePermissions implements PermissionService {
  const _FakePermissions(this.readable);

  final Set<String> readable;

  @override
  bool can(String module, PermissionAction action) =>
      action == PermissionAction.read && readable.contains(module);
}

void main() {
  group('business hubs', () {
    test('binder is hubs only, in business order', () {
      expect(AppMenu.allItems.map((i) => i.label), [
        'Desk',
        'Sales',
        'Purchase',
        'Inventory',
        'Finance',
        'People',
        'General',
        'Organization',
        'Reports',
        'Settings',
      ]);
    });

    test('All documents is routed but kept out of the binder', () {
      expect(AppMenu.hubs.containsKey('/transactions'), isTrue);
      expect(AppMenu.allItems.any((i) => i.route == '/transactions'), isFalse);
      expect(
        AppMenu.allShellListItems.any((i) => i.route == '/transactions'),
        isTrue,
      );
    });

    test('every tile has exactly one canonical home', () {
      final owners = <String, List<String>>{};
      for (final hub in AppMenu.hubs.values) {
        if (!hub.inBinder) continue;
        for (final tile in hub.tiles) {
          owners.putIfAbsent(tile.route, () => []).add(hub.label);
        }
      }
      final shared = owners.entries.where((e) => e.value.length > 1);
      expect(
        shared,
        isEmpty,
        reason:
            'shared masters belong in crossLinks, not on two hubs: '
            '${shared.map((e) => '${e.key} -> ${e.value}').join(', ')}',
      );
    });

    test('cross-links point at a tile some other hub owns', () {
      for (final hub in AppMenu.hubs.values) {
        for (final link in hub.crossLinks) {
          final owner = AppMenu.owningHub(link.route);
          expect(owner, isNotNull, reason: '${link.route} is owned by nobody');
          expect(
            owner!.route,
            isNot(hub.route),
            reason: '${link.route} cross-links to its own hub',
          );
        }
      }
    });

    test('shell routes are unique — a shared tile registers once', () {
      final routes = AppMenu.allShellListItems.map((i) => i.route).toList();
      expect(routes.toSet().length, routes.length);
    });

    test('no shell route falls through to the placeholder page', () {
      final unwired = [
        for (final item in AppMenu.allShellListItems)
          if (shellListPageFor(
            item.route,
            fallbackTitle: item.label,
          ).runtimeType.toString().contains('Placeholder'))
            item.route,
      ];
      expect(unwired, isEmpty, reason: 'unwired routes: $unwired');
    });
  });

  group('selectedBinderRoute', () {
    test('a voucher highlights its business hub, not its route prefix', () {
      // The whole point: /transactions/* is an engine-shaped route, and Sales
      // owns the sales invoice regardless.
      expect(
        AppMenu.selectedBinderRoute('/transactions/sales-invoices'),
        '/sales',
      );
      expect(
        AppMenu.selectedBinderRoute('/transactions/purchase-orders'),
        '/purchase',
      );
      expect(
        AppMenu.selectedBinderRoute('/transactions/payments'),
        '/accounts',
      );
      expect(
        AppMenu.selectedBinderRoute('/transactions/godown-transfers'),
        '/inventory',
      );
      expect(AppMenu.selectedBinderRoute('/organization/contacts'), '/general');
    });

    test('child routes resolve to the owning hub', () {
      expect(
        AppMenu.selectedBinderRoute('/transactions/sales-invoices/42'),
        '/sales',
      );
      expect(AppMenu.selectedBinderRoute('/inventory/item/7'), '/inventory');
    });

    test('hubs and non-hub binder entries resolve to themselves', () {
      expect(AppMenu.selectedBinderRoute('/sales'), '/sales');
      expect(AppMenu.selectedBinderRoute('/dashboard'), '/dashboard');
      expect(AppMenu.selectedBinderRoute('/reports/stock-summary'), '/reports');
    });
  });

  group('visibleSections', () {
    test('hides a hub when the user can read none of its tiles', () {
      final sections = AppMenu.visibleSections(
        const _FakePermissions({'Inventory'}),
      );
      final labels = [for (final s in sections) ...s.items.map((i) => i.label)];

      expect(labels, contains('Inventory'));
      expect(labels, isNot(contains('Purchase')));
      expect(labels, isNot(contains('People')));
      expect(labels, isNot(contains('Organization')));
      // Ungated entries always survive.
      expect(labels, containsAll(['Desk', 'Reports', 'Settings']));

      // Sales and Finance survive on purpose: `rbacModule` is not the entity
      // name, and Price list / Route / Tax category all gate on `Inventory`.
      // The rule is "a hub you can read *something* on stays", so these are
      // reachable — with only their Inventory-gated tiles showing.
      expect(labels, containsAll(['Sales', 'Finance']));
    });

    test('one readable tile is enough to keep a hub', () {
      final sections = AppMenu.visibleSections(
        const _FakePermissions({'SalesInvoice'}),
      );
      final labels = [for (final s in sections) ...s.items.map((i) => i.label)];
      expect(labels, contains('Sales'));
      expect(labels, isNot(contains('Purchase')));
    });

    test('empty sections are dropped, never rendered as bare titles', () {
      final sections = AppMenu.visibleSections(const _FakePermissions({}));
      expect(sections.every((s) => s.items.isNotEmpty), isTrue);
      expect(sections.any((s) => s.title == 'Operations'), isFalse);
    });
  });
}
