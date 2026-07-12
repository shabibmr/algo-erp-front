import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';

/// Admin matrix for a role — `GET/PUT /organization/roles/:id/permissions`.
class RolePermissionsRepository {
  RolePermissionsRepository(this._client);

  final DioClient _client;

  Future<Result<List<ModulePermissions>>> list(int roleId) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/organization/roles/$roleId/permissions',
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      final list = data is List ? data : const <dynamic>[];
      return [
        for (final raw in list)
          if (raw is Map<String, dynamic>) _fromRow(raw),
      ];
    });
  }

  Future<Result<List<ModulePermissions>>> save(
    int roleId,
    List<ModulePermissions> permissions,
  ) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '/organization/roles/$roleId/permissions',
        data: {
          'permissions': [
            for (final p in permissions)
              {
                'module_name': p.module,
                'Allow_Create': p.create,
                'Allow_Read': p.read,
                'Allow_Update': p.update,
                'Allow_Delete': p.delete,
                'Allow_Share': p.share,
              },
          ],
        },
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      final list = data is List ? data : const <dynamic>[];
      return [
        for (final raw in list)
          if (raw is Map<String, dynamic>) _fromRow(raw),
      ];
    });
  }

  ModulePermissions _fromRow(Map<String, dynamic> json) {
    bool flag(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return false;
    }

    return ModulePermissions(
      module: json['module_name'] as String? ?? '',
      create: flag(json['Allow_Create']),
      read: flag(json['Allow_Read']),
      update: flag(json['Allow_Update']),
      delete: flag(json['Allow_Delete']),
      share: flag(json['Allow_Share']),
    );
  }
}

/// Modules shown on the matrix editor (bootstrap + trading).
const kPermissionMatrixModules = <String>[
  'CompanyProfile',
  'FinancialYear',
  'Branch',
  'Currency',
  'CurrencyRate',
  'VoucherSeries',
  'AddressBook',
  'UserRole',
  'UserAccessPermission',
  'UserCredentials',
  'ProjectMaster',
  'ConfigSetting',
  'ErrorReporting',
  'Accounts',
  'AccountGroup',
  'Ledger',
  'Inventory',
  'Employee',
  'Transactions',
  'SalesInvoice',
  'PurchaseInvoice',
  'PaymentVoucher',
  'ReceiptVoucher',
  'JournalVoucher',
  'ContraVoucher',
  'CreditNote',
  'DebitNote',
  'Quotation',
  'SalesOrder',
  'PurchaseOrder',
  'DeliveryNote',
  'ReceiptNote',
  'GodownTransfer',
  'MaterialIn',
  'Requirement',
  'StockRequest',
];
