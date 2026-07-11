import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog to change the signed-in user's password. Reads/writes the ambient
/// [AuthBloc]: it dispatches [AuthChangePasswordRequested] and reacts to the
/// change-password sub-status carried on [AuthAuthenticated] — spinner while
/// in flight, pop on success, inline field errors on validation failure.
///
/// Show it with [ChangePasswordDialog.show] from anywhere under the bloc.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const ChangePasswordDialog(),
      ),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthChangePasswordRequested(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated &&
          current.changePasswordStatus == ChangePasswordStatus.success,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final authed = state is AuthAuthenticated ? state : null;
        final inProgress =
            authed?.changePasswordStatus == ChangePasswordStatus.inProgress;
        final fieldErrors =
            authed?.changePasswordFieldErrors ?? const <String, String>{};
        final generalError =
            (fieldErrors.isEmpty ? authed?.changePasswordFailure : null)
                ?.message;

        return AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentController,
                  enabled: !inProgress,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    errorText: fieldErrors['currentPassword'],
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Current password is required'
                      : null,
                ),
                SizedBox(height: tokens.spacing.md),
                TextFormField(
                  controller: _newController,
                  enabled: !inProgress,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    errorText: fieldErrors['newPassword'],
                  ),
                  // Backend requires min 6 (see api-contract change-password).
                  validator: (value) => (value == null || value.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                if (generalError != null) ...[
                  SizedBox(height: tokens.spacing.md),
                  Text(
                    generalError,
                    style: TextStyle(color: tokens.semanticColors.danger),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: inProgress ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: inProgress ? null : _submit,
              child: inProgress
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        );
      },
    );
  }
}
