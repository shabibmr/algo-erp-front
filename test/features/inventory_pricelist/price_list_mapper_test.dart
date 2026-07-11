import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_dto.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_mapper.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = PriceListMapper();

  test(
    'PriceListDto.fromJson reads the non-standard Price_List_ID PK key',
    () {
      final dto = PriceListDto.fromJson(const {
        'Price_List_ID': 1,
        'Price_List_Name': 'Retail',
        'Price_List_Start_Date': '2026-01-01T00:00:00.000Z',
        'Price_List_Default': true,
        'Price_List_ShowInPos': true,
        'Price_List_isOnline': false,
      });

      expect(dto.id, 1);
      expect(dto.priceListName, 'Retail');
      expect(dto.startDate, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(dto.isDefault, isTrue);
      expect(dto.showInPos, isTrue);
      expect(dto.isOnline, isFalse);
    },
  );

  test('PriceListDto.fromJson defaults showInPos to true when absent', () {
    final dto = PriceListDto.fromJson(const {
      'Price_List_ID': 2,
      'Price_List_Name': 'Wholesale',
    });
    expect(dto.showInPos, isTrue);
    expect(dto.isDefault, isFalse);
    expect(dto.isOnline, isFalse);
  });

  test('PriceListMapper.toEntity produces a clean id from Price_List_ID', () {
    const dto = PriceListDto(id: 1, priceListName: 'Retail');
    expect(
      mapper.toEntity(dto),
      const PriceList(id: 1, name: 'Retail'),
    );
  });

  test('PriceListMapper.toDto round-trips back to the wire shape', () {
    const priceList = PriceList(id: 1, name: 'Retail', isDefault: true);
    final dto = mapper.toDto(priceList);

    expect(dto.toJson(), {
      'Price_List_Name': 'Retail',
      'Price_List_Start_Date': null,
      'Price_List_End_Date': null,
      'Price_List_Default': true,
      'Price_List_ShowInPos': true,
      'Price_List_isOnline': false,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    final priceList = PriceList(
      id: 5,
      name: 'VIP',
      startDate: DateTime.utc(2026),
      isOnline: true,
    );
    expect(mapper.toEntity(mapper.toDto(priceList)), priceList);
  });
}
