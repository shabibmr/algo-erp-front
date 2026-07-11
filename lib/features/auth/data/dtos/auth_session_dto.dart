import 'package:algo_erp_front/features/auth/data/dtos/auth_user_dto.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of `POST /auth/login`'s `data`: the token pair plus the user.
/// The repository persists [accessToken]/[refreshToken] through `TokenStorage`
/// and maps [user] to the domain entity.
class AuthSessionDto extends Equatable {
  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
