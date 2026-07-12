import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/brand`, matching `models/backend/prisma/schema.prisma`
/// (`brands` table) exactly. Field names keep the backend's original casing
/// per `feature-contract.md` — the mapper produces clean entity names.
class BrandDto extends Equatable {
  const BrandDto({
    required this.id,
    required this.brandName,
    this.brandDescription,
  });

  factory BrandDto.fromJson(Map<String, dynamic> json) => BrandDto(
    id: json['id'] as int,
    brandName: json['Brand_Name'] as String,
    brandDescription: json['Brand_Description'] as String?,
  );

  final int id;
  final String brandName;
  final String? brandDescription;

  /// Only the two zod-validated fields are ever sent — `id`/timestamps are
  /// server-generated and never accepted on write.
  Map<String, dynamic> toJson() => {
    'Brand_Name': brandName,
    'Brand_Description': brandDescription,
  };

  @override
  List<Object?> get props => [id, brandName, brandDescription];
}
