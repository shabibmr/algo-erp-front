import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../../tool/seed_building_materials.dart';

void main() {
  group('BuildingMaterialsSeeder', () {
    test('successfully seeds all entities against mock HTTP client', () async {
      final postedEndpoints = <String>[];

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        postedEndpoints.add(path);

        if (path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'accessToken': 'mock_jwt_token_12345'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 101, 'message': 'Created successfully'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final seeder = BuildingMaterialsSeeder(
        baseUrl: 'http://localhost:5000',
        client: mockClient,
      );

      final result = await seeder.run();

      expect(result, isTrue);
      expect(postedEndpoints, contains('/auth/login'));
      expect(postedEndpoints, contains('/inventory/uom'));
      expect(postedEndpoints, contains('/inventory/godown'));
      expect(postedEndpoints, contains('/accounts/account-groups'));
      expect(postedEndpoints, contains('/accounts/ledgers'));
      expect(postedEndpoints, contains('/inventory/group'));
      expect(postedEndpoints, contains('/inventory/item'));
    });
  });
}
