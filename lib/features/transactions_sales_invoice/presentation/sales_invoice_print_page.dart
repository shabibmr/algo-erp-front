import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Print-friendly layout built from [SalesInvoiceDetail] (no extra packages).
/// Use browser/OS print from the host window when needed.
class SalesInvoicePrintPage extends StatelessWidget {
  const SalesInvoicePrintPage({required this.doc, super.key});

  final SalesInvoiceDetail doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Print ${doc.displayNo}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SALES INVOICE',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(doc.displayNo, style: theme.textTheme.titleMedium),
                    Text('Status: ${doc.status}'),
                    if (doc.voucherDate != null)
                      Text('Date: ${doc.voucherDate!.toDayString()}'),
                    const SizedBox(height: 16),
                    Text('Bill to', style: theme.textTheme.titleSmall),
                    Text(doc.billingName ?? doc.customerLabel ?? '—'),
                    if (doc.customerLabel != null &&
                        doc.billingName != doc.customerLabel)
                      Text(doc.customerLabel!),
                    if (doc.godownLabel != null)
                      Text('Godown: ${doc.godownLabel}'),
                    if (doc.narration != null && doc.narration!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Narration: ${doc.narration}'),
                    ],
                    const SizedBox(height: 24),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Qty'), numeric: true),
                        DataColumn(label: Text('Price'), numeric: true),
                        DataColumn(label: Text('Disc%'), numeric: true),
                        DataColumn(label: Text('Tax%'), numeric: true),
                        DataColumn(label: Text('Subtotal'), numeric: true),
                      ],
                      rows: [
                        for (final line in doc.lines)
                          DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  line.itemLabel ??
                                      (line.itemId != null
                                          ? '#${line.itemId}'
                                          : '—'),
                                ),
                              ),
                              DataCell(Text(_d(line.quantity))),
                              DataCell(Text(_d(line.price))),
                              DataCell(Text(_d(line.discountPercent))),
                              DataCell(Text(_d(line.taxRate))),
                              DataCell(Text(_d(line.subtotal))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            _row('Subtotal', doc.total),
                            _row('Discount', doc.discount),
                            _row('VAT', doc.vat),
                            const Divider(),
                            _row(
                              'Total',
                              doc.grossTotal ?? doc.total,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _d(Decimal? v) => v?.toString() ?? '—';

  Widget _row(String label, Decimal? value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value?.toMoney() ?? '—', style: style),
        ],
      ),
    );
  }
}
