import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adaptive sign-in screen.
///
/// On mobile the form fills the available width; on tablet/desktop it sits in
/// a centered, elevated card. Fully theme- and RTL-aware — spacing/radii/
/// elevation come from `AppTokens` via `context.tokens`, and no colors are
/// hardcoded. Drives (and is driven by) [AuthBloc]; navigation on success is
/// left to the router's auth redirect, which observes the same bloc.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isMobile ? double.infinity : 420,
              ),
              child: BlocConsumer<AuthBloc, AuthState>(
                // Only react to a *general* failure (no field errors) with a
                // snackbar; field-level errors bind to the inputs below.
                listenWhen: (previous, current) =>
                    current is AuthFailure && current.fieldErrors.isEmpty,
                listener: (context, state) {
                  if (state is AuthFailure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(state.failure.message)),
                      );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final fieldErrors = state is AuthFailure
                      ? state.fieldErrors
                      : const <String, String>{};
                  final form = _LoginForm(
                    formKey: _formKey,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    isLoading: isLoading,
                    fieldErrors: fieldErrors,
                    onSubmit: _submit,
                  );

                  if (context.isMobile) return form;
                  return Card(
                    elevation: tokens.elevation.level2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radii.lg),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spacing.xl),
                      child: form,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The form body, split out so the same widget renders bare (mobile) or inside
/// a card (tablet/desktop) without duplicating field wiring.
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isLoading,
    required this.fieldErrors,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: tokens.spacing.md),
          Text(
            context.l10n.appTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spacing.xl),
          TextFormField(
            controller: usernameController,
            enabled: !isLoading,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: fieldErrors['username'],
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Username is required'
                : null,
          ),
          SizedBox(height: tokens.spacing.md),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
              ),
              errorText: fieldErrors['password'],
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Password is required'
                : null,
          ),
          SizedBox(height: tokens.spacing.xl),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
