import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// The band above a page's work surface: where you are, what you're looking
/// at, how much of it there is, and the one action that creates more of it.
///
/// The actions sit at the far right of this band — deliberately not beside the
/// search field. Creating a record is a *page* action; searching filters the
/// *sheet*. Keeping them on separate bands is what stops a list screen from
/// reading as a row of unrelated controls.
///
/// ```dart
/// PageHeader(
///   eyebrow: 'Inventory',
///   title: 'Brands',
///   subtitle: '128 records',
///   actions: [FilledButton.icon(onPressed: ..., label: Text('New brand'))],
/// )
/// ```
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
  });

  final String title;

  /// Where this page sits in the app — e.g. `'Inventory'`. Set in small caps
  /// above the title.
  final String? eyebrow;

  /// A quiet fact about the title, set on the title's baseline (e.g. the
  /// record count). Not a description — keep it to a few words.
  final String? subtitle;

  /// Page-level actions, rendered far right (or below the title on mobile).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: tokens.brand.inkMuted,
              letterSpacing: 0.08 * 11,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(width: tokens.spacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.brand.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (actions.isEmpty) return titleBlock;

    final spacedActions = <Widget>[
      for (final (index, action) in actions.indexed) ...[
        if (index > 0) SizedBox(width: tokens.spacing.sm),
        action,
      ],
    ];

    // Below tablet there isn't room for a title and a button on one line, so
    // the actions drop to their own row rather than squeezing the title.
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleBlock,
          SizedBox(height: tokens.spacing.md),
          Row(children: spacedActions),
        ],
      );
    }

    return Row(
      // Bottom-aligned: the button's baseline lands with the title's, and the
      // eyebrow stacks above without dragging the button up with it.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleBlock),
        SizedBox(width: tokens.spacing.md),
        ...spacedActions,
      ],
    );
  }
}
