import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:flutter/widgets.dart';

typedef DeviceWidgetBuilder = Widget Function(BuildContext context);

/// Picks a builder by [DeviceClass], falling back progressively:
/// large -> desktop -> tablet -> mobile (the first one supplied, in that
/// order of preference, going down in width).
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
    this.large,
  });

  final DeviceWidgetBuilder mobile;
  final DeviceWidgetBuilder? tablet;
  final DeviceWidgetBuilder? desktop;
  final DeviceWidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = Breakpoints.classify(constraints.maxWidth);
        return switch (device) {
          DeviceClass.large => (large ?? desktop ?? tablet ?? mobile)(context),
          DeviceClass.desktop => (desktop ?? tablet ?? mobile)(context),
          DeviceClass.tablet => (tablet ?? mobile)(context),
          DeviceClass.mobile => mobile(context),
        };
      },
    );
  }
}
