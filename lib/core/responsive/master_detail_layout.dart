import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

/// Renders list+detail side-by-side from tablet width upward; on mobile,
/// shows only one pane at a time (list, or detail with a back button),
/// mirroring how a caller would otherwise push/pop a detail route.
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    required this.list,
    super.key,
    this.detail,
    this.detailPlaceholder,
    this.onBack,
    this.listWidth = 360,
  });

  final Widget list;
  final Widget? detail;
  final Widget? detailPlaceholder;
  final VoidCallback? onBack;
  final double listWidth;

  bool get _hasDetail => detail != null;

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.hasPersistentNav(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: listWidth, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            child:
                detail ??
                detailPlaceholder ??
                const Center(child: Text('Select an item')),
          ),
        ],
      );
    }

    if (_hasDetail) {
      return PopScope(
        canPop: onBack == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onBack?.call();
        },
        child: detail!,
      );
    }

    return list;
  }
}
