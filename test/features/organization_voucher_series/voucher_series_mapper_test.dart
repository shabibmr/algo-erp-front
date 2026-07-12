import 'package:algo_erp_front/features/organization_voucher_series/data/voucher_series_dto.dart';
import 'package:algo_erp_front/features/organization_voucher_series/data/voucher_series_mapper.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = VoucherSeriesMapper();

  test('fromJson reads require_approval', () {
    final dto = VoucherSeriesDto.fromJson(const {
      'id': 1,
      'voucher_type': 'SalesInvoice',
      'prefix': 'SI',
      'display_name': 'Sales SI',
      'company_id': 1,
      'require_approval': true,
      'is_default': true,
      'is_active': true,
    });
    expect(dto.requireApproval, isTrue);
    expect(mapper.toEntity(dto).requireApproval, isTrue);
  });

  test('toJson includes require_approval and omits id', () {
    const series = VoucherSeries(
      id: 2,
      voucherType: 'SalesInvoice',
      prefix: 'SI',
      displayName: 'Sales',
      companyId: 1,
      requireApproval: true,
    );
    final json = mapper.toDto(series).toJson();
    expect(json['require_approval'], isTrue);
    expect(json['voucher_type'], 'SalesInvoice');
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('is_active'), isFalse);
  });

  test('round-trip', () {
    const series = VoucherSeries(
      id: 3,
      voucherType: 'Payment',
      prefix: 'PV',
      displayName: 'Payments',
      companyId: 1,
      branchId: 2,
      numberLength: 6,
      requireApproval: false,
    );
    expect(mapper.toEntity(mapper.toDto(series)), series);
  });
}
