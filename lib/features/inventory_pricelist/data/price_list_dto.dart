import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/pricelist`, matching the backend `price_lists`
/// table. Note the PK JSON key is `Price_List_ID`, not `id` — the Prisma
/// model field is literally named that (no `@map("id")` renaming it), so
/// this is what the API actually returns.
class PriceListDto extends Equatable {
  const PriceListDto({
    required this.id,
    required this.priceListName,
    this.startDate,
    this.endDate,
    this.isDefault = false,
    this.showInPos = true,
    this.isOnline = false,
  });

  factory PriceListDto.fromJson(Map<String, dynamic> json) => PriceListDto(
        id: json['Price_List_ID'] as int,
        priceListName: json['Price_List_Name'] as String,
        startDate: json['Price_List_Start_Date'] == null
            ? null
            : DateTime.parse(json['Price_List_Start_Date'] as String),
        endDate: json['Price_List_End_Date'] == null
            ? null
            : DateTime.parse(json['Price_List_End_Date'] as String),
        isDefault: json['Price_List_Default'] as bool? ?? false,
        showInPos: json['Price_List_ShowInPos'] as bool? ?? true,
        isOnline: json['Price_List_isOnline'] as bool? ?? false,
      );

  final int id;
  final String priceListName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isDefault;
  final bool showInPos;
  final bool isOnline;

  Map<String, dynamic> toJson() => {
        'Price_List_Name': priceListName,
        'Price_List_Start_Date': startDate?.toIso8601String(),
        'Price_List_End_Date': endDate?.toIso8601String(),
        'Price_List_Default': isDefault,
        'Price_List_ShowInPos': showInPos,
        'Price_List_isOnline': isOnline,
      };

  @override
  List<Object?> get props =>
      [id, priceListName, startDate, endDate, isDefault, showInPos, isOnline];
}
