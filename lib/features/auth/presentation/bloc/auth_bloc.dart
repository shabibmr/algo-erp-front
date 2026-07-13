import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/features/auth/domain/auth_repository.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_event.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Owns the app's authentication status.
///
/// Token attach and 401→refresh→replay live in `AuthInterceptor` at the Dio
/// layer, so this bloc never touches the refresh flow — it only boots the
/// session, logs in/out, and changes the password. Login and change-password
/// validation errors are turned into per-field messages via [FormMixin], so
/// the forms can bind them to inputs.
///
/// **Dev auto-login:** when [AppConfig.shouldAutoLogin] is true and no token
/// is stored, boot signs in as the configured test user so the login page is
/// skipped during local testing.
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> with FormMixin {
  AuthBloc(this._repository, this._tokenStorage) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthChangePasswordRequested>(_onChangePassword);
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final token = await _tokenStorage.accessToken;
    if (token == null) {
      if (AppConfig.shouldAutoLogin) {
        await _autoLogin(emit);
        return;
      }
      emit(const AuthUnauthenticated());
      return;
    }
    // A token exists — confirm it's still valid. If `/auth/me` fails (even
    // after the interceptor's refresh attempt), treat the session as gone.
    emit(const AuthLoading());
    final result = await _repository.me();
    await result.fold((_) async {
      if (AppConfig.shouldAutoLogin) {
        await _autoLogin(emit);
        return;
      }
      emit(const AuthUnauthenticated());
    }, (user) async => emit(AuthAuthenticated(user)));
  }

  /// Signs in with [AppConfig] dev credentials. On failure, falls through to
  /// the login page so a down backend is still visible.
  Future<void> _autoLogin(Emitter<AuthState> emit) async {
    final config = AppConfig.instance;
    emit(const AuthLoading());
    final result = await _repository.login(
      username: config.devUsername,
      password: config.devPassword,
    );
    result.fold(
      (failure) =>
          emit(AuthFailure(failure, fieldErrors: fieldErrorsFrom(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.login(
      username: event.username,
      password: event.password,
    );
    result.fold(
      (failure) =>
          emit(AuthFailure(failure, fieldErrors: fieldErrorsFrom(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // The repository clears local tokens regardless of the server's response,
    // so the app always lands in a clean signed-out state.
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    emit(current.withChangePassword(status: ChangePasswordStatus.inProgress));
    final result = await _repository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(
        current.withChangePassword(
          status: ChangePasswordStatus.idle,
          failure: failure,
          fieldErrors: fieldErrorsFrom(failure),
        ),
      ),
      (_) => emit(
        current.withChangePassword(status: ChangePasswordStatus.success),
      ),
    );
  }
}
