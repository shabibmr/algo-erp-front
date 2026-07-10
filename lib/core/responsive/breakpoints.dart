import 'package:flutter/widgets.dart';

enum DeviceClass { mobile, tablet, desktop, large }

/// Breakpoint system driving the adaptive shell and layout primitives.
/// Widths are logical pixels, matching Material 3 window-size-class guidance.
abstract final class Breakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double desktopMax = 1440;

  static DeviceClass classify(double width) {
    if (width < mobileMax) return DeviceClass.mobile;
    if (width < tabletMax) return DeviceClass.tablet;
    if (width < desktopMax) return DeviceClass.desktop;
    return DeviceClass.large;
  }

  static DeviceClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);

  static bool isMobile(BuildContext context) =>
      of(context) == DeviceClass.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == DeviceClass.tablet;

  static bool isDesktop(BuildContext context) {
    final device = of(context);
    return device == DeviceClass.desktop || device == DeviceClass.large;
  }

  /// True from tablet width upward — the point at which the shell switches
  /// from a bottom bar/drawer to a persistent rail or sidebar.
  static bool hasPersistentNav(BuildContext context) => !isMobile(context);
}
