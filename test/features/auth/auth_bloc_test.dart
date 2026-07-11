import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/auth/domain/auth_repository.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockAuthRepository repo;
  late _MockTokenStorage storage;

  const user = AuthUser(
    id: 1,
    username: 'admin',
    roleId: 1,
    roleName: 'Administrator',
  );

  AuthBloc build() => AuthBloc(repo, storage);

  setUp(() {
    repo = _MockAuthRepository();
    storage = _MockTokenStorage();
  });

  group('AuthStarted', () {
    blocTest<AuthBloc, AuthState>(
      'no stored token → unauthenticated (never hits /me)',
      setUp: () =>
          when(() => storage.accessToken).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthUnauthenticated>()],
      verify: (_) => verifyNever(() => repo.me()),
    );

    blocTest<AuthBloc, AuthState>(
      'stored token + valid session → [loading, authenticated]',
      setUp: () {
        when(() => storage.accessToken).thenAnswer((_) async => 'token');
        when(() => repo.me()).thenAnswer((_) async => const Right(user));
      },
      build: build,
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'stored token but /me fails → [loading, unauthenticated]',
      setUp: () {
        when(() => storage.accessToken).thenAnswer((_) async => 'stale');
        when(() => repo.me()).thenAnswer(
          (_) async => const Left(Failure.unauthorized('expired')),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'success → [loading, authenticated]',
      setUp: () => when(
        () => repo.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(user)),
      build: build,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(username: 'admin', password: 'pw'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'failure → [loading, failure] with the failure preserved',
      setUp: () => when(
        () => repo.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(Failure.unauthorized('Invalid credentials')),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(username: 'admin', password: 'bad'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.failure,
          'failure',
          const Failure.unauthorized('Invalid credentials'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'validation failure → field errors are stripped of the body prefix',
      setUp: () => when(
        () => repo.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.validation('Invalid', [
            ValidationFieldError(field: 'body.username', message: 'Required'),
          ]),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(username: '', password: 'pw'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.fieldErrors,
          'fieldErrors',
          {'username': 'Required'},
        ),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'AuthLogoutRequested → unauthenticated',
    setUp: () =>
        when(() => repo.logout()).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [isA<AuthUnauthenticated>()],
    verify: (_) => verify(() => repo.logout()).called(1),
  );

  group('AuthChangePasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'success → in-progress then success, keeping the user',
      setUp: () => when(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const AuthAuthenticated(user),
      act: (bloc) => bloc.add(
        const AuthChangePasswordRequested(
          currentPassword: 'old',
          newPassword: 'newpass',
        ),
      ),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.changePasswordStatus,
          'status',
          ChangePasswordStatus.inProgress,
        ),
        isA<AuthAuthenticated>()
            .having(
              (s) => s.changePasswordStatus,
              'status',
              ChangePasswordStatus.success,
            )
            .having((s) => s.user, 'user', user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'ignored when not authenticated',
      build: build,
      seed: () => const AuthUnauthenticated(),
      act: (bloc) => bloc.add(
        const AuthChangePasswordRequested(
          currentPassword: 'old',
          newPassword: 'newpass',
        ),
      ),
      expect: () => const <AuthState>[],
      verify: (_) => verifyNever(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ),
    );
  });
}
