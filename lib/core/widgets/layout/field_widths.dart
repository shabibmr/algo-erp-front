/// Target content widths for form fields, so short inputs (dates, codes) stop
/// stretching to fill a column sized for a long FK picker. Widths are maxima —
/// fields shrink below these on narrow layouts (see `_InvoiceDetailsCard` in
/// the sales-invoice form for the first use).
abstract final class FieldWidths {
  /// FK lookup — variable, potentially long labels ("GD-001 — Main Warehouse").
  static const double picker = 320;

  /// Enum / select dropdown.
  static const double dropdown = 220;

  /// Date field — a formatted day string plus a calendar icon.
  static const double date = 170;

  /// Voucher series and other short codes.
  static const double code = 150;

  /// Never render a usable field narrower than this.
  static const double min = 150;
}
