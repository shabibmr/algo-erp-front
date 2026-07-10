import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/navigation/app_router.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/theme/theme_cubit.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => getIt<ThemeCubit>(),
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeCubit>().state;
          return MaterialApp.router(
            title: 'algoERP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
