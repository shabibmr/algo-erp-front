import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/theme/locale_cubit.dart';
import 'package:algo_erp_front/core/theme/theme_cubit.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/auth/presentation/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final organization = AppMenu.hubs['/organization']!;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.gradient.canvasGradient),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              eyebrow: 'Workspace',
              title: 'Settings',
              subtitle: 'Theme, language, and account',
            ),
            SizedBox(height: tokens.spacing.md),
            Expanded(
              child: ListView(
                children: [
                  WorkSheet(
                    fill: false,
                    title: 'Appearance',
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, mode) {
                        return SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.brightness_auto, size: 16),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_outlined, size: 16),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (set) {
                            context.read<ThemeCubit>().setThemeMode(set.first);
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  WorkSheet(
                    fill: false,
                    title: 'Language',
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: BlocBuilder<LocaleCubit, Locale?>(
                      builder: (context, locale) {
                        final code = locale?.languageCode ?? 'system';
                        return SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'system',
                              label: Text('System'),
                            ),
                            ButtonSegment(value: 'en', label: Text('English')),
                            ButtonSegment(value: 'ar', label: Text('العربية')),
                          ],
                          selected: {code},
                          onSelectionChanged: (set) {
                            context.read<LocaleCubit>().setLanguageCode(
                              set.first,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  WorkSheet(
                    fill: false,
                    title: 'Account',
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.lock_outline,
                            color: brand.lagoon,
                          ),
                          title: const Text('Change password'),
                          onTap: () => ChangePasswordDialog.show(context),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.logout, color: brand.oxblood),
                          title: const Text('Sign out'),
                          onTap: () {
                            context.read<AuthBloc>().add(
                              const AuthLogoutRequested(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  WorkSheet(
                    fill: false,
                    title: 'Organization',
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(organization.icon, color: brand.lagoon),
                      title: Text(organization.label),
                      subtitle: Text(
                        organization.subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: brand.inkMuted,
                      ),
                      onTap: () => context.go(organization.route),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  WorkSheet(
                    fill: false,
                    title: 'Developer',
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: Column(
                      children: [
                        for (final item in AppMenu.utilityItems)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(item.icon, color: brand.lagoon),
                            title: Text(item.label),
                            subtitle: Text(
                              item.blurb,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: brand.inkMuted),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: brand.inkMuted,
                            ),
                            onTap: () => context.go(item.route),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
