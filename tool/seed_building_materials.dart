import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Seeder runner for Building Materials Trading Company sample data.
/// Usage:
///   dart run tool/seed_building_materials.dart [baseUrl]
/// Default baseUrl: http://localhost:5000
void main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args.first : 'http://localhost:5000';
  final client = http.Client();
  final seeder = BuildingMaterialsSeeder(baseUrl: baseUrl, client: client);

  stdout.writeln('--------------------------------------------------');
  stdout.writeln('Building Materials Trading Co. - Seeder Tool');
  stdout.writeln('Target API URL: $baseUrl');
  stdout.writeln('--------------------------------------------------\n');

  try {
    final success = await seeder.run();
    if (success) {
      stdout.writeln('\nSUCCESS: All sample seed data was processed!');
      exit(0);
    } else {
      stderr.writeln('\nFAILED: Seeding encountered errors.');
      exit(1);
    }
  } catch (e, stack) {
    stderr.writeln('\nEXCEPTION during seeding: $e');
    stderr.writeln(stack);
    exit(1);
  } finally {
    client.close();
  }
}

class BuildingMaterialsSeeder {
  BuildingMaterialsSeeder({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;
  String? _authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<bool> run() async {
    // 0. Authenticate
    final authed = await login();
    if (!authed) {
      stdout.writeln(
        'ℹ️ Proceeding without auth token (unauthenticated / dev mode).',
      );
    }

    bool allSuccess = true;

    // 1. Seed UOMs
    stdout.writeln('\n--- 1. Seeding Units of Measure (UOM) ---');
    final uomIdMap = <String, int>{};
    for (final data in sampleUoms) {
      final id = await postItem('/inventory/uom', data, nameKey: 'uom_name');
      if (id != null) {
        uomIdMap[data['uom_code'] as String] = id;
      } else {
        allSuccess = false;
      }
    }

    // 2. Seed Godowns
    stdout.writeln('\n--- 2. Seeding Godowns ---');
    for (final data in sampleGodowns) {
      final id = await postItem(
        '/inventory/godown',
        data,
        nameKey: 'godown_name',
      );
      if (id == null) allSuccess = false;
    }

    // 3. Seed Account Groups
    stdout.writeln('\n--- 3. Seeding Account Groups ---');
    final accGroupIdMap = <String, int>{};
    for (final data in sampleAccountGroups) {
      final code = data['account_group_code'] as String;
      final id = await postItem(
        '/accounts/account-groups',
        data,
        nameKey: 'group_name',
      );
      if (id != null) {
        accGroupIdMap[code] = id;
      } else {
        allSuccess = false;
      }
    }

    // 4. Seed Ledgers
    stdout.writeln('\n--- 4. Seeding Ledgers ---');
    for (final data in sampleLedgers) {
      final id = await postItem(
        '/accounts/ledgers',
        data,
        nameKey: 'Ledger_Name',
      );
      if (id == null) allSuccess = false;
    }

    // 5. Seed Inventory Groups
    stdout.writeln('\n--- 5. Seeding Inventory Groups ---');
    final invGroupIdMap = <String, int>{};
    for (final data in sampleInventoryGroups) {
      final groupKey = data['Group_ID'] as String;
      final id = await postItem(
        '/inventory/group',
        data,
        nameKey: 'Group_Name',
      );
      if (id != null) {
        invGroupIdMap[groupKey] = id;
      } else {
        allSuccess = false;
      }
    }

    // 6. Seed Inventory Items
    stdout.writeln('\n--- 6. Seeding Inventory Items ---');
    for (final rawData in sampleInventoryItems) {
      final data = Map<String, dynamic>.from(rawData);
      final groupKey = data['Group_Id'] as String?;
      if (groupKey != null && invGroupIdMap.containsKey(groupKey)) {
        data['inventory_group_id'] = invGroupIdMap[groupKey];
      }
      final uomCode = data['uom_code'] as String?;
      if (uomCode != null && uomIdMap.containsKey(uomCode)) {
        data['uom_id'] = uomIdMap[uomCode];
      }
      data.remove('uom_code');

      final id = await postItem('/inventory/item', data, nameKey: 'Item_Name');
      if (id == null) allSuccess = false;
    }

    return allSuccess;
  }

  Future<bool> login() async {
    stdout.writeln('Authenticating with backend...');
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'brand.tester',
          'password': 'BrandTest123!',
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        _authToken =
            data?['accessToken'] as String? ?? body['token'] as String?;
        stdout.writeln('✅ Auth token acquired.');
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<int?> postItem(
    String endpoint,
    Map<String, dynamic> payload, {
    required String nameKey,
  }) async {
    final itemName = payload[nameKey] ?? 'Item';
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final res = await client.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        int? id;
        if (data is Map<String, dynamic>) {
          id = (data['id'] as num?)?.toInt();
        }
        stdout.writeln(
          '  [${res.statusCode}] Created "$itemName"${id != null ? ' (ID: $id)' : ''}',
        );
        return id ?? 1;
      } else {
        stdout.writeln('  [${res.statusCode}] Failed "$itemName": ${res.body}');
        return null;
      }
    } catch (e) {
      stdout.writeln('  [ERROR] Posting "$itemName": $e');
      return null;
    }
  }

  // --- Sample Data Definitions ---

  static const sampleUoms = [
    {
      'uom_name': 'Metric Tonne',
      'uom_code': 'MT',
      'symbol': 'MT',
      'decimal_places': 3,
    },
    {
      'uom_name': 'Bag (50kg)',
      'uom_code': 'BAG',
      'symbol': 'bag',
      'decimal_places': 0,
    },
    {
      'uom_name': 'Pieces',
      'uom_code': 'PCS',
      'symbol': 'pcs',
      'decimal_places': 0,
    },
    {
      'uom_name': 'Square Meter',
      'uom_code': 'SQM',
      'symbol': 'sqm',
      'decimal_places': 2,
    },
    {
      'uom_name': 'Cubic Meter',
      'uom_code': 'CBM',
      'symbol': 'cbm',
      'decimal_places': 3,
    },
  ];

  static const sampleGodowns = [
    {
      'godown_name': 'Jebel Ali Central Steel & Cement Yard',
      'godown_code': 'GD-JAFZA',
      'location': 'JAFZA South Zone 2, Street 14, Dubai',
      'is_profit_centre': true,
      'is_default': true,
    },
    {
      'godown_name': 'Al Quoz Hardware & Finishing Warehouse',
      'godown_code': 'GD-ALQ',
      'location': 'Al Quoz Industrial 3, Street 8, Dubai',
      'is_profit_centre': false,
      'is_default': false,
    },
    {
      'godown_name': 'Sharjah Industrial Timber Yard',
      'godown_code': 'GD-SHJ',
      'location': 'Industrial Area 10, Sharjah',
      'is_profit_centre': false,
      'is_default': false,
    },
  ];

  static const sampleAccountGroups = [
    {
      'group_name': 'Assets',
      'account_group_code': 'ASSETS',
      'group_type': 'Asset',
      'nature': 'Debit',
      'parent_group_id': null,
    },
    {
      'group_name': 'Current Assets',
      'account_group_code': 'CURR_ASSETS',
      'group_type': 'Asset',
      'nature': 'Debit',
      'parent_group_id': 1,
    },
    {
      'group_name': 'Sundry Debtors',
      'account_group_code': 'DEBTORS',
      'group_type': 'Asset',
      'nature': 'Debit',
      'parent_group_id': 2,
    },
    {
      'group_name': 'Current Liabilities',
      'account_group_code': 'CURR_LIAB',
      'group_type': 'Liability',
      'nature': 'Credit',
      'parent_group_id': null,
    },
    {
      'group_name': 'Sundry Creditors',
      'account_group_code': 'CREDITORS',
      'group_type': 'Liability',
      'nature': 'Credit',
      'parent_group_id': 4,
    },
  ];

  static const sampleLedgers = [
    {
      'Ledger_Name': 'Al Habtoor Contracting LLC',
      'ledger_code': 'LDG-CUST-01',
      'Ledger_Type': 'SundryDebtor',
      'currency_code': 'AED',
      'Opening_Balance': '145000.00',
      'creditSettings': {
        'credit_limit': '250000.00',
        'credit_period_days': 60,
        'payment_terms': 'NET 60 DAYS',
      },
      'taxSettings': {'trn': '100293847500003'},
    },
    {
      'Ledger_Name': 'Emirates Steel Industries PJSC',
      'ledger_code': 'LDG-VEND-01',
      'Ledger_Type': 'SundryCreditor',
      'currency_code': 'AED',
      'Opening_Balance': '420000.00',
      'creditSettings': {
        'credit_limit': '1000000.00',
        'credit_period_days': 60,
      },
      'taxSettings': {'trn': '100039482100003'},
    },
    {
      'Ledger_Name': 'Building Materials Sales Account',
      'ledger_code': 'LDG-SALES',
      'Ledger_Type': 'Sales',
      'currency_code': 'AED',
      'Opening_Balance': '0.00',
    },
    {
      'Ledger_Name': 'Building Materials Purchase Account',
      'ledger_code': 'LDG-PURCH',
      'Ledger_Type': 'Purchase',
      'currency_code': 'AED',
      'Opening_Balance': '0.00',
    },
  ];

  static const sampleInventoryGroups = [
    {
      'Group_ID': 'GRP-STEEL',
      'Group_Name': 'Structural Steel & Metals',
      'group_code': 'STEEL',
      'Group_Type': 'Material',
      'parent_group_id': null,
    },
    {
      'Group_ID': 'GRP-REBAR',
      'Group_Name': 'Deformed Steel Rebars',
      'group_code': 'REBAR',
      'Group_Type': 'Material',
      'parent_group_id': 1,
    },
    {
      'Group_ID': 'GRP-CEMENT',
      'Group_Name': 'Cement & Aggregates',
      'group_code': 'CEM-AGG',
      'Group_Type': 'Material',
      'parent_group_id': null,
    },
    {
      'Group_ID': 'GRP-CEM-BAG',
      'Group_Name': 'Portland Cement Bags',
      'group_code': 'CEM-BAG',
      'Group_Type': 'Material',
      'parent_group_id': 3,
    },
  ];

  static const sampleInventoryItems = [
    {
      'Item_Name': 'Deformed Steel Rebar 12mm Grade 60 (12m)',
      'Item_Code': 'REBAR-12MM-G60',
      'Group_Id': 'GRP-REBAR',
      'uom_code': 'MT',
      'price': '2750.00',
      'base_price': '2450.00',
      'standard_cost': '2380.00',
      'vat_rate': '5.00',
      'opening_stock': '120.00',
      'reorder_level': '50.00',
      'is_sales_item': true,
      'is_purchase_item': true,
      'is_stock_item': true,
    },
    {
      'Item_Name': 'Ordinary Portland Cement 50kg (OPC Type I)',
      'Item_Code': 'CEM-OPC-50KG',
      'Group_Id': 'GRP-CEM-BAG',
      'uom_code': 'BAG',
      'price': '17.50',
      'base_price': '14.50',
      'standard_cost': '13.80',
      'vat_rate': '5.00',
      'opening_stock': '5000.00',
      'reorder_level': '1000.00',
      'is_sales_item': true,
      'is_purchase_item': true,
      'is_stock_item': true,
    },
    {
      'Item_Name': 'Heavy Duty Glazed Porcelain Tile 60x60cm Grey',
      'Item_Code': 'TILE-PORC-60X60-GRY',
      'Group_Id': 'GRP-STEEL',
      'uom_code': 'SQM',
      'price': '38.00',
      'base_price': '28.00',
      'standard_cost': '24.00',
      'vat_rate': '5.00',
      'opening_stock': '2500.00',
      'reorder_level': '500.00',
      'is_sales_item': true,
      'is_purchase_item': true,
      'is_stock_item': true,
    },
  ];
}
