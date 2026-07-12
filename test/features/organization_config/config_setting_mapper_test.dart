import 'package:algo_erp_front/features/organization_config/data/config_setting_dto.dart';
import 'package:algo_erp_front/features/organization_config/data/config_setting_mapper.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ConfigSettingMapper();

  test('fromJson maps gm_key / gm_value casing', () {
    final dto = ConfigSettingDto.fromJson(const {
      'id': 1,
      'gm_key': 'default_tax',
      'gm_value': '5',
      'Data_Type': 'integer',
      'display_text': 'Default tax %',
    });

    expect(dto.gmKey, 'default_tax');
    expect(dto.gmValue, '5');
    expect(dto.dataType, 'integer');
    expect(
      mapper.toEntity(dto),
      const ConfigSetting(
        id: 1,
        key: 'default_tax',
        value: '5',
        dataType: 'integer',
        displayText: 'Default tax %',
      ),
    );
  });

  test('toUpdateJson only sends value', () {
    expect(
      mapper
          .toDto(const ConfigSetting(id: 1, key: 'k', value: 'v'))
          .toUpdateJson(),
      {'value': 'v'},
    );
  });
}
