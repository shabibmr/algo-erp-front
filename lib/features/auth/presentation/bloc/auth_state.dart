import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:equatable/equatable.dart';

/// Progress of the in-session change-password action. Carried *on*
/// [AuthAuthenticated] rather than as its own top-level state, so a password
/// change never flips the app to loading/unauthenticated and never trips the
/// router's auth redirect.
enum ChangePasswordStatus { idle, inProgress, success }

/// The app's authentication status. Sealed so every consumer's `switch` is
/// exhaustive. The router redirect keys off exactly three cases —
/// [AuthInitial]/[AuthLoading] (wait), [AuthAuthenticated] (allow), everything
/// else (send to `/login`).
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Nothing checked yet (pre-boot). Router shows a splash and waits.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A login or boot session-check is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Signed in. [changePasswordStatus]/[changePasswordFailure]/
/// [changePasswordFieldErrors] surface the change-password dialog's progress
/// without leaving this state.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(
    this.user, {
    this.changePasswordStatus = ChangePasswordStatus.idle,
    this.changePasswordFailure,
    this.changePasswordFieldErrors = const {},
  });

  final AuthUser user;
  final ChangePasswordStatus changePasswordStatus;
  final Failure? changePasswordFailure;
  final Map<String, String> changePasswordFieldErrors;

  /// Returns a copy with a new change-password sub-status, keeping [user].
  AuthAuthenticated withChangePassword({
    required ChangePasswordStatus status,
    Failure? failure,
    Map<String, String> fieldErrors = const {},
  }) {
    return AuthAuthenticated(
      user,
      changePasswordStatus: status,
      changePasswordFailure: failure,
      changePasswordFieldErrors: fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    user,
    changePasswordStatus,
    changePasswordFailure,
    changePasswordFieldErrors,
  ];
}

/// Signed out (no/expired token) — router sends the user to `/login`.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// A login attempt failed. [fieldErrors] carries per-field validation messages
/// (username/password) extracted by `FormMixin`; [failure] is the general one.
final class AuthFailure extends AuthState {
  const AuthFailure(this.failure, {this.fieldErrors = const {}});

  final Failure failure;
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [failure, fieldErrors];
}
