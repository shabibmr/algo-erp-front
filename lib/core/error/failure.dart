import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@immutable
class ValidationFieldError {
  const ValidationFieldError({required this.field, required this.message});

  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ValidationFieldError &&
      other.field == field &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, message);
}

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.timeout(String message) = TimeoutFailure;
  const factory Failure.unauthorized(String message) = UnauthorizedFailure;
  const factory Failure.forbidden(String message) = ForbiddenFailure;
  const factory Failure.validation(
    String message,
    List<ValidationFieldError> fieldErrors,
  ) = ValidationFailure;
  const factory Failure.notFound(String message) = NotFoundFailure;
  const factory Failure.conflict(String message) = ConflictFailure;
  const factory Failure.server(String message, {String? code}) = ServerFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.unknown(String message) = UnknownFailure;
}
