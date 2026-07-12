import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_config/data/config_setting_dto.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';

class ConfigSettingMapper implements Mapper<ConfigSettingDto, ConfigSetting> {
  const ConfigSettingMapper();

  @override
  ConfigSetting toEntity(ConfigSettingDto dto) => ConfigSetting(
    id: dto.id,
    key: dto.gmKey,
    value: dto.gmValue,
    dataType: dto.dataType,
    displayText: dto.displayText,
  );

  @override
  ConfigSettingDto toDto(ConfigSetting entity) => ConfigSettingDto(
    id: entity.id,
    gmKey: entity.key,
    gmValue: entity.value,
    dataType: entity.dataType,
    displayText: entity.displayText,
  );
}
