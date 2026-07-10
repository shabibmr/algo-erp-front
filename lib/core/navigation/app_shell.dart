import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive navigation shell: a Drawer behind an AppBar on mobile, a
/// [NavigationRail] on tablet, and an extended labeled sidebar on desktop —
/// switching purely off [Breakpoints], with a single data-driven menu model
/// so no destination is defined twice.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final items = AppMenu.allItems;
    final index = items.indexWhere(
      (item) => location == item.route || location.startsWith('${item.route}/'),
    );
    return index == -1 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    context.go(AppMenu.allItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final device = Breakpoints.of(context);
    final selectedIndex = _selectedIndex(context);

    return switch (device) {
      DeviceClass.mobile => _MobileShell(
        selectedIndex: selectedIndex,
        onSelect: (i) => _onSelect(context, i),
        child: child,
      ),
      DeviceClass.tablet => _RailShell(
        extended: false,
        selectedIndex: selectedIndex,
        onSelect: (i) => _onSelect(context, i),
        child: child,
      ),
      DeviceClass.desktop || DeviceClass.large => _RailShell(
        extended: true,
        selectedIndex: selectedIndex,
        onSelect: (i) => _onSelect(context, i),
        child: child,
      ),
    };
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = AppMenu.allItems;
    return Scaffold(
      appBar: AppBar(title: Text(items[selectedIndex].label)),
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          Navigator.of(context).pop();
          onSelect(i);
        },
        children: _buildDrawerChildren(),
      ),
      body: child,
    );
  }

  List<Widget> _buildDrawerChildren() {
    final widgets = <Widget>[];
    for (final section in AppMenu.sections) {
      if (section.title != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
            child: Text(section.title!),
          ),
        );
      }
      for (final item in section.items) {
        widgets.add(
          NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon ?? item.icon),
            label: Text(item.label),
          ),
        );
      }
    }
    return widgets;
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.extended,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = AppMenu.allItems;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon ?? item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
