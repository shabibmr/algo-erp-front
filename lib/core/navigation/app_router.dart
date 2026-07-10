import 'package:algo_erp_front/core/navigation/app_shell.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/theme/theme_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Seam for Step 8's auth/RBAC redirect guard. Returns a redirect path, or
/// null to allow navigation. Wired into GoRouter.redirect as-is so Step 8
/// only has to change this function's body, not the router's shape.
String? appRouterRedirect(BuildContext context, GoRouterState state) => null;

/// Wraps a destination widget in a fade-through transition using the shared
/// [MotionTokens], so every route in the shell animates consistently.
CustomTransitionPage<void> buildPageWithMotion({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurveTween(curve: MotionTokens.standardCurve);
      return FadeTransition(
        opacity: curved.animate(animation),
        child: child,
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: appRouterRedirect,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        for (final item in AppMenu.allItems)
          GoRoute(
            path: item.route,
            pageBuilder: (context, state) => buildPageWithMotion(
              state: state,
              child: item.route == '/theme-preview'
                  ? const ThemePreviewPage()
                  : _PlaceholderPage(title: item.label),
            ),
          ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('No route for ${state.uri}')),
  ),
);

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Feature not yet built — placeholder route from Step 3.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
