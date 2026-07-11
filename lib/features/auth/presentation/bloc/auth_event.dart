import 'package:equatable/equatable.dart';

/// Everything the UI can ask of `AuthBloc`. Sealed so the bloc's handler
/// registration is exhaustive.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once at app boot: if a token is already stored, validate the session
/// via `/auth/me`; otherwise go straight to unauthenticated.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Submit the login form.
final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

/// Sign out and clear local tokens.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Change the current user's password (only valid while authenticated).
final class AuthChangePasswordRequested extends AuthEvent {
  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
