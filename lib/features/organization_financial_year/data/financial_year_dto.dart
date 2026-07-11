import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/fy`, matching the backend `financialyear`
/// table.
class FinancialYearDto extends Equatable {
  const FinancialYearDto({
    required this.id,
    required this.fyCode,
    required this.displayName,
    required this.startDate,
    required this.endDate,
    required this.companyId,
    this.status = 'Open',
    this.isDefault = false,
  });

  factory FinancialYearDto.fromJson(Map<String, dynamic> json) =>
      FinancialYearDto(
        id: json['id'] as int,
        fyCode: json['fy_code'] as String,
        displayName: json['display_name'] as String,
        // The backend serializes DATE columns as full ISO timestamps; only
        // the date part matters for this YYYY-MM-DD field.
        startDate: (json['start_date'] as String).substring(0, 10),
        endDate: (json['end_date'] as String).substring(0, 10),
        companyId: json['company_id'] as int,
        status: json['status'] as String? ?? 'Open',
        isDefault: json['is_default'] as bool? ?? false,
      );

  final int id;
  final String fyCode;
  final String displayName;
  final String startDate;
  final String endDate;
  final int companyId;
  final String status;
  final bool isDefault;

  /// `id`/timestamps are server-generated and never sent on write.
  Map<String, dynamic> toJson() => {
        'fy_code': fyCode,
        'display_name': displayName,
        'start_date': startDate,
        'end_date': endDate,
        'company_id': companyId,
        'status': status,
        'is_default': isDefault,
      };

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
