import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adaptive sign-in screen — "closed desk, open for the day".
///
/// Linen canvas, paper card, brand logo. Desktop splits into a soft lagoon
/// wash (ledger lines) + form card; mobile stacks logo + form. Fully token-
/// and RTL-aware. Drives [AuthBloc]; navigation on success is the router's
/// auth redirect.
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
    final brand = tokens.brand;

    return Scaffold(
      backgroundColor: brand.linen,
      body: BlocConsumer<AuthBloc, AuthState>(
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
            showLogo: true,
          );

          if (context.isMobile) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(tokens.spacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: form,
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              const Expanded(flex: 5, child: _DeskWashPanel()),
              Expanded(
                flex: 4,
                child: ColoredBox(
                  color: brand.linen,
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(tokens.spacing.xl),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Card(
                            elevation: tokens.elevation.level2,
                            color: brand.paper,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                tokens.radii.xl,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(tokens.spacing.xl),
                              child: form,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Soft lagoon panel with quiet ledger rules — brand presence, not chrome.
class _DeskWashPanel extends StatelessWidget {
  const _DeskWashPanel();

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;
    return ColoredBox(
      color: brand.lagoon,
      child: CustomPaint(
        painter: _LedgerLinesPainter(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/brand/algo_logo.png',
                  height: 88,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                SizedBox(height: tokens.spacing.lg),
                Text(
                  context.l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: tokens.spacing.sm),
                Text(
                  "Your company's desk — open for the day.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerLinesPainter extends CustomPainter {
  const _LedgerLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 28.0;
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LedgerLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The form body, shared by mobile (bare) and desktop (inside paper card).
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
    required this.showLogo,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final VoidCallback onSubmit;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final theme = Theme.of(context);
    final isMobile = context.isMobile;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: brand.lagoon,
                  borderRadius: BorderRadius.circular(tokens.radii.lg),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacing.lg,
                    vertical: tokens.spacing.md,
                  ),
                  child: Image.asset(
                    'assets/brand/algo_logo.png',
                    height: 56,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.lg),
          ] else if (showLogo) ...[
            // Desktop card: product title only (logo lives on wash panel).
            Text(
              context.l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: tokens.spacing.xs),
          ],
          if (isMobile)
            Text(
              context.l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          SizedBox(height: tokens.spacing.sm),
          Text(
            'Sign in to your desk',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brand.inkMuted,
            ),
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
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
