import 'package:algo_erp_front/core/navigation/command_palette_cubit.dart';
import 'package:algo_erp_front/core/navigation/navigation_registry.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Centered Paper drawer: fuzzy jump to menu, reports, and create actions.
class CommandPalette extends StatelessWidget {
  const CommandPalette({super.key});

  /// Shows the palette as a dialog. Safe to call from shortcuts or header.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => BlocProvider(
        create: (_) => CommandPaletteCubit(),
        child: const CommandPalette(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _CommandPaletteBody();
  }
}

class _CommandPaletteBody extends StatefulWidget {
  const _CommandPaletteBody();

  @override
  State<_CommandPaletteBody> createState() => _CommandPaletteBodyState();
}

class _CommandPaletteBodyState extends State<_CommandPaletteBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      context.read<CommandPaletteCubit>().search(_controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _go(NavDestination dest) {
    Navigator.of(context).pop();
    context.go(dest.route);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final cubit = context.read<CommandPaletteCubit>();
    final results = cubit.state.results;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      cubit.highlightNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      cubit.highlightPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (results.isNotEmpty) _go(results[cubit.state.highlight]);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final maxWidth = context.isMobile ? double.infinity : 560.0;

    return BlocBuilder<CommandPaletteCubit, CommandPaletteState>(
      builder: (context, state) {
        final results = state.results;
        final highlight = state.highlight;

        // Group results preserving order.
        final groups = <String, List<NavDestination>>{};
        for (final d in results) {
          groups.putIfAbsent(d.group, () => []).add(d);
        }

        return Dialog(
          backgroundColor: brand.paper,
          elevation: tokens.elevation.level3,
          insetPadding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? tokens.spacing.md : 40,
            vertical: tokens.spacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            side: BorderSide(color: brand.mist),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 480),
            child: Focus(
              onKeyEvent: _onKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spacing.md,
                      tokens.spacing.md,
                      tokens.spacing.md,
                      tokens.spacing.sm,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Jump to a page, report, or action…',
                        prefixIcon: Icon(Icons.search, color: brand.inkMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radii.md),
                          borderSide: BorderSide(color: brand.mist),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radii.md),
                          borderSide: BorderSide(color: brand.mist),
                        ),
                        filled: true,
                        fillColor: brand.linen,
                        isDense: true,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: brand.mist),
                  Flexible(
                    child: results.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(tokens.spacing.lg),
                            child: Text(
                              'No matches',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: brand.inkMuted),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.symmetric(
                              vertical: tokens.spacing.sm,
                            ),
                            children: [
                              for (final entry in groups.entries) ...[
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    tokens.spacing.md,
                                    tokens.spacing.sm,
                                    tokens.spacing.md,
                                    tokens.spacing.xs,
                                  ),
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: brand.inkMuted,
                                          letterSpacing: 0.8,
                                        ),
                                  ),
                                ),
                                for (final d in entry.value)
                                  _PaletteTile(
                                    destination: d,
                                    selected: results.indexOf(d) == highlight,
                                    onTap: () => _go(d),
                                  ),
                              ],
                            ],
                          ),
                  ),
                  Divider(height: 1, color: brand.mist),
                  Padding(
                    padding: EdgeInsets.all(tokens.spacing.sm),
                    child: Text(
                      '↑↓ navigate · Enter open · Esc close',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: brand.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;
    return Material(
      color: selected ? brand.lagoonSoft : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(
          destination.icon,
          size: 20,
          color: selected ? brand.lagoon : brand.inkMuted,
        ),
        title: Text(
          destination.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Text(
          destination.route,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
        onTap: onTap,
      ),
    );
  }
}
