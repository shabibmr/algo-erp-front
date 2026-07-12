import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/tax-category`, matching the backend
/// `tax_categories` table.
class TaxCategoryDto extends Equatable {
  const TaxCategoryDto({
    required this.id,
    required this.taxName,
    required this.taxRate,
    required this.isActive,
  });

  factory TaxCategoryDto.fromJson(Map<String, dynamic> json) => TaxCategoryDto(
    id: json['id'] as int,
    taxName: json['tax_name'] as String,
    taxRate: Decimal.parse(json['tax_rate'].toString()),
    isActive: json['is_active'] as bool? ?? true,
  );

  final int id;
  final String taxName;
  final Decimal taxRate;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'tax_name': taxName,
    'tax_rate': taxRate.toDouble(),
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, taxName, taxRate, isActive];
}
