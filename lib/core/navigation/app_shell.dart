import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/navigation/binder_sidebar.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/navigation/shell_header.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive binder shell: drawer on mobile, icon spine on tablet, extended
/// labeled spine on desktop. Single [AppMenu] model drives every form.
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
    final items = AppMenu.allItems;
    final title = items[selectedIndex.clamp(0, items.length - 1)].label;

    // Above every shell route, so a master's list and form routes — which are
    // siblings, not ancestors — resolve the same CrudBloc.
    return CrudBlocScope(
      child: switch (device) {
        DeviceClass.mobile => _MobileShell(
          selectedIndex: selectedIndex,
          title: title,
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
      },
    );
  }
}

class _MobileShell extends StatefulWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.title,
    required this.onSelect,
    required this.child,
  });

  final int selectedIndex;
  final String title;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: brand.linen,
      appBar: ShellHeader(
        title: widget.title,
        showMenuButton: true,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        backgroundColor: brand.paper,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(tokens.spacing.md),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/brand/algo_mark.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    Text(
                      context.l10n.appTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: brand.mist),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    vertical: tokens.spacing.sm,
                    horizontal: tokens.spacing.sm,
                  ),
                  children: _drawerTiles(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
    );
  }

  List<Widget> _drawerTiles(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final widgets = <Widget>[];
    var flatIndex = 0;

    for (final section in AppMenu.sections) {
      if (section.title != null) {
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
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06 * 11,
              ),
            ),
          ),
        );
      }
      for (final item in section.items) {
        final index = flatIndex;
        final selected = index == widget.selectedIndex;
        widgets.add(
          ListTile(
            selected: selected,
            selectedTileColor: brand.lagoonSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
            ),
            leading: Icon(
              selected ? (item.selectedIcon ?? item.icon) : item.icon,
              color: selected ? brand.lagoon : brand.inkMuted,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: selected ? brand.lagoon : brand.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelect(index);
            },
          ),
        );
        flatIndex++;
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
    final brand = context.tokens.brand;

    return Scaffold(
      backgroundColor: brand.linen,
      body: Row(
        children: [
          BinderSidebar(
            key: const Key('binder-sidebar'),
            extended: extended,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          VerticalDivider(width: 1, thickness: 1, color: brand.mist),
          Expanded(
            child: Column(
              children: [
                const ShellHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
