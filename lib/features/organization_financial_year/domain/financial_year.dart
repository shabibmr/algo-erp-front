import 'package:equatable/equatable.dart';

/// The FinancialYear master entity. No soft-delete column and no `DELETE`
/// route at all — `supportsDelete: false` on the manifest hides the Delete
/// action.
///
/// [startDate]/[endDate] are `YYYY-MM-DD` strings, not `DateTime`: the
/// backend's `financialYearSchema` validates them as strings via regex, and
/// `FieldType` has no editable date field yet (`dateTime` is display-only).
/// Modeled as `String` + a manifest validator, same reuse-not-new-type
/// precedent as AddressBook's `contactType` enum.
///
/// [status] is a 3-value backend enum (`Open`/`Closed`/`Locked`), reusing the
/// same `FieldType.text` + validator pattern — the third occurrence of this
/// pattern (after UOMConversion's `conValue`, AddressBook's `contactType`).
/// A real `FieldType.enum` is overdue; not built here to keep this batch
/// scoped to registering entities, not extending the field-type system.
class FinancialYear extends Equatable {
  const FinancialYear({
    required this.id,
    required this.fyCode,
    required this.displayName,
    required this.startDate,
    required this.endDate,
    required this.companyId,
    this.status = 'Open',
    this.isDefault = false,
  });

  static const statuses = ['Open', 'Closed', 'Locked'];

  final int id;
  final String fyCode;
  final String displayName;
  final String startDate;
  final String endDate;
  final int companyId;
  final String status;
  final bool isDefault;

  FinancialYear copyWith({
    int? id,
    String? fyCode,
    String? displayName,
    String? startDate,
    String? endDate,
    int? companyId,
    String? status,
    bool? isDefault,
  }) => FinancialYear(
    id: id ?? this.id,
    fyCode: fyCode ?? this.fyCode,
    displayName: displayName ?? this.displayName,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    companyId: companyId ?? this.companyId,
    status: status ?? this.status,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  List<Object?> get props => [
    id,
    fyCode,
    displayName,
    startDate,
    endDate,
    companyId,
    status,
    isDefault,
  ];
}
