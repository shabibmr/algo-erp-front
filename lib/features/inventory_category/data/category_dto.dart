import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/category`, matching the backend `category`
/// table.
class CategoryDto extends Equatable {
  const CategoryDto({
    required this.id,
    required this.categoryName,
    this.categoryCode,
    this.description,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
    id: json['id'] as int,
    categoryName: json['category_name'] as String,
    categoryCode: json['category_code'] as String?,
    description: json['Description'] as String?,
  );

  final int id;
  final String categoryName;
  final String? categoryCode;
  final String? description;

  Map<String, dynamic> toJson() => {
    'category_name': categoryName,
    'category_code': categoryCode,
    'Description': description,
  };

  @override
  List<Object?> get props => [id, categoryName, categoryCode, description];
}
