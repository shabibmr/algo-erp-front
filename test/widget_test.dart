import 'package:algo_erp_front/core/navigation/app_shell.dart';
import 'package:algo_erp_front/core/navigation/binder_sidebar.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/auth/presentation/pages/login_page.dart';
import 'package:algo_erp_front/features/desk/presentation/pages/todays_desk_page.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  const user = AuthUser(
    id: 1,
    username: 'rania',
    roleId: 1,
    roleName: 'Admin',
    companyId: 10,
    branchId: 2,
  );

  setUp(() {
    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthAuthenticated(user)),
      initialState: const AuthAuthenticated(user),
    );
    when(() => authBloc.state).thenReturn(const AuthAuthenticated(user));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => Stream<AuthState>.value(const AuthAuthenticated(user)));
  });

  Widget wrap(Widget home) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('Login page shows desk-oriented copy and sign-in', (
    tester,
  ) async {
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthUnauthenticated()),
      initialState: const AuthUnauthenticated(),
    );
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => Stream<AuthState>.value(const AuthUnauthenticated()));

    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in to your desk'), findsOneWidget);
    expect(find.text('algoERP'), findsWidgets);
  });

  testWidgets('Binder shell shows Desk and morphs to mobile drawer', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const TodaysDeskPage(),
            ),
          ],
        ),
      ],
    );

    Widget buildApp() {
      return BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(BinderSidebar), findsOneWidget);
    expect(find.text('Desk'), findsWidgets);
    expect(find.textContaining('Good'), findsOneWidget);
    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('Nothing waiting yet'), findsOneWidget);
    expect(find.textContaining('Company #10'), findsOneWidget);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(BinderSidebar), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Desk'), findsWidgets);
  });
}
