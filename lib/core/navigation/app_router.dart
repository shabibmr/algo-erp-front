import 'dart:async';

import 'package:algo_erp_front/core/navigation/app_shell.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/theme/theme_preview_page.dart';
import 'package:algo_erp_front/core/widgets/gallery/widget_gallery_page.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/auth/presentation/pages/login_page.dart';
import 'package:algo_erp_front/features/desk/presentation/pages/todays_desk_page.dart';
import 'package:algo_erp_front/features/inventory_brand/presentation/brand_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Auth/RBAC redirect guard. Reads [AuthBloc] from the widget tree (provided
/// above `MaterialApp.router`) and steers navigation:
/// - while the boot check is in flight ([AuthInitial]/[AuthLoading]) it returns
///   null so we don't flash `/login` before `/auth/me` resolves;
/// - unauthenticated users are sent to `/login` (and kept there);
/// - authenticated users sitting on `/login` are bounced to `/dashboard`.
///
/// `/403` is a *destination* the app pushes when an API call returns a
/// `ForbiddenFailure` — it is never synthesized here (403s arise from data
/// calls, not from navigation).
String? appRouterRedirect(BuildContext context, GoRouterState state) {
  final authState = context.read<AuthBloc>().state;
  final atLogin = state.matchedLocation == '/login';

  if (authState is AuthInitial || authState is AuthLoading) return null;

  final isAuthed = authState is AuthAuthenticated;
  if (!isAuthed) return atLogin ? null : '/login';
  if (atLogin) return '/dashboard';
  return null;
}

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

/// Builds the app router bound to a single [AuthBloc] instance. The same
/// instance is provided above `MaterialApp.router` in `app.dart`, so the
/// redirect guard and the UI observe identical auth state, and
/// [GoRouterRefreshStream] re-runs the guard on every auth transition.
GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
      initialLocation: '/dashboard',
      redirect: appRouterRedirect,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // Chrome-less routes: no nav rail/drawer.
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/403', builder: (_, __) => const _ForbiddenPage()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            for (final item in AppMenu.allItems)
              GoRoute(
                path: item.route,
                pageBuilder: (context, state) => buildPageWithMotion(
                  state: state,
                  child: switch (item.route) {
                    '/dashboard' => const TodaysDeskPage(),
                    '/theme-preview' => const ThemePreviewPage(),
                    '/widget-gallery' => const WidgetGalleryPage(),
                    '/inventory/brand' => const BrandListPage(),
                    _ => _PlaceholderPage(title: item.label),
                  },
                ),
              ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('No route for ${state.uri}')),
      ),
    );

/// Adapts a [Stream] into a [Listenable] for `GoRouter.refreshListenable`.
/// go_router does not export its own, so we keep the standard adapter here.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _ForbiddenPage extends StatelessWidget {
  const _ForbiddenPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Access denied', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              "You don't have permission to view this page.",
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Back to desk'),
            ),
          ],
        ),
      ),
    );
  }
}

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
