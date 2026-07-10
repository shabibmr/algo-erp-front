import 'package:algo_erp_front/core/error/failure.dart';

/// The request wrappers the backend validates under — a Zod issue `path`
/// arrives as e.g. `["body", "Brand_Name"]`, and the leading wrapper segment
/// must be stripped before the error maps to a form field.
const _pathWrappers = {'body', 'query', 'params'};

/// Shared form logic for any create/edit bloc: turns a `Failure.validation`
/// into a `field → message` map the UI binds to inputs.
///
/// The verified backend contract (see `docs/feature-contract.md`) is that Zod
/// paths are prefixed with `body`/`query`/`params` because the validator wraps
/// the request that way. This mixin strips that prefix so `body.Brand_Name`
/// binds to the `Brand_Name` field, and joins any remaining nested path with
/// dots (`lines.0.qty`).
mixin FormMixin {
  /// Extracts per-field validation messages from [failure]. Returns an empty
  /// map for any non-validation failure (those surface as a general error).
  Map<String, String> fieldErrorsFrom(Failure failure) {
    if (failure is! ValidationFailure) return const {};
    final result = <String, String>{};
    for (final error in failure.fieldErrors) {
      final field = _normalizeField(error.field);
      if (field.isEmpty) continue;
      result.putIfAbsent(field, () => error.message);
    }
    return result;
  }

  /// `body.Brand_Name` → `Brand_Name`; `body.lines.0.qty` → `lines.0.qty`.
  String _normalizeField(String rawField) {
    final segments = rawField.split('.');
    if (segments.isNotEmpty && _pathWrappers.contains(segments.first)) {
      segments.removeAt(0);
    }
    return segments.join('.');
  }
}
