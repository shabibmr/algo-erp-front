import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// The TaxCategories master entity — soft-deleted via `is_active` (unlike
/// most other Inventory masters in this batch, which hard-delete).
class TaxCategory extends Equatable {
  const TaxCategory({
    required this.id,
    required this.name,
    required this.rate,
    this.isActive = true,
  });

  final int id;
  final String name;

  /// Percentage rate (0–100) — `Decimal`, never `double`, per house rule.
  final Decimal rate;
  final bool isActive;

  TaxCategory copyWith({
    int? id,
    String? name,
    Decimal? rate,
    bool? isActive,
  }) =>
      TaxCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        rate: rate ?? this.rate,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, name, rate, isActive];
}
