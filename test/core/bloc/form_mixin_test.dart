import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

class _Formish with FormMixin {}

void main() {
  final formish = _Formish();

  test('strips the body wrapper so it matches a form field key', () {
    const failure = Failure.validation('Invalid', [
      ValidationFieldError(field: 'body.Brand_Name', message: 'Required'),
    ]);

    expect(formish.fieldErrorsFrom(failure), {'Brand_Name': 'Required'});
  });

  test('joins nested paths after stripping the wrapper', () {
    const failure = Failure.validation('Invalid', [
      ValidationFieldError(field: 'body.lines.0.qty', message: 'Invalid qty'),
    ]);

    expect(formish.fieldErrorsFrom(failure), {'lines.0.qty': 'Invalid qty'});
  });

  test('returns an empty map for a non-validation failure', () {
    const failure = Failure.network('offline');
    expect(formish.fieldErrorsFrom(failure), isEmpty);
  });

  test('keeps the first message when the same field errors twice', () {
    const failure = Failure.validation('Invalid', [
      ValidationFieldError(field: 'body.department_id', message: 'first'),
      ValidationFieldError(field: 'body.department_id', message: 'second'),
    ]);

    expect(formish.fieldErrorsFrom(failure), {'department_id': 'first'});
  });
}
