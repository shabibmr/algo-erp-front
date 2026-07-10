import 'package:algo_erp_front/core/error/safe_call.dart';

/// A single unit of application business logic.
///
/// Every use case is a callable that takes typed [In] params and returns a
/// [Result] (`Either<Failure, Out>`) — never throws, never returns a raw
/// value. Presentation code depends on use cases, use cases depend on
/// repository *interfaces* (never concrete data sources). This is the seam
/// that keeps blocs ignorant of HTTP, drift, or anything else.
///
/// Implement by overriding [call] so instances invoke like functions:
/// ```dart
/// final result = await getBrand(GetBrandParams(id: 1));
/// ```
// ignore: one_member_abstracts — intentional base for many use cases.
abstract class UseCase<Out, In> {
  const UseCase();

  Future<Result<Out>> call(In params);
}

/// Marker for use cases that take no input, e.g. `LogoutUseCase`.
///
/// Preferred over `void`/`null` so the type system distinguishes
/// "intentionally no params" from an accidental omission.
class NoParams {
  const NoParams();
}
