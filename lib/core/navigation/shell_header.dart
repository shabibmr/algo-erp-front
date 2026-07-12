import 'package:algo_erp_front/core/navigation/session_context_bar.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/auth/presentation/widgets/change_password_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top chrome for the binder shell: workplace context + tools + account.
class ShellHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShellHeader({
    super.key,
    this.title,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  final String? title;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final isMobile = context.isMobile;

    return Material(
      color: brand.paper,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: brand.mist)),
          ),
          child: Row(
            children: [
              if (showMenuButton)
                IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                  onPressed: onMenuPressed,
                ),
              if (title != null && isMobile) ...[
                SizedBox(width: tokens.spacing.xs),
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ] else ...[
                Expanded(child: SessionContextBar(compact: isMobile)),
              ],
              IconButton(
                tooltip: 'Command palette (coming soon)',
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Command palette will arrive with the full '
                          'manifest registry.',
                        ),
                      ),
                    );
                },
                icon: const Icon(Icons.search),
              ),
              // Subtle kbd hint on desktop only — not a second control.
              if (!isMobile)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: tokens.spacing.xs),
                  child: Text(
                    _paletteShortcutLabel(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: brand.inkMuted),
                  ),
                ),
              const _AccountMenu(),
            ],
          ),
        ),
      ),
    );
  }

  String _paletteShortcutLabel() {
    final isApple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return isApple ? '⌘K' : 'Ctrl+K';
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final label = user?.username ?? 'Account';
        final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';

        return PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 40),
          onSelected: (value) async {
            switch (value) {
              case 'password':
                await ChangePasswordDialog.show(context);
              case 'logout':
                context.read<AuthBloc>().add(const AuthLogoutRequested());
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'password',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text('Change password'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('Sign out'),
                dense: true,
              ),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.tokens.spacing.xs,
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: brand.lagoonSoft,
              foregroundColor: brand.lagoon,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: brand.lagoon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
