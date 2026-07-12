import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sales Invoice create / Draft-edit form via DocumentSurface + LineEngine.
class SalesInvoiceFormPage extends StatefulWidget {
  const SalesInvoiceFormPage({super.key, this.entityId});

  /// When set, loads a Draft SI for edit (`PUT` lifecycle).
  final int? entityId;

  @override
  State<SalesInvoiceFormPage> createState() => _SalesInvoiceFormPageState();
}

class _SalesInvoiceFormPageState extends State<SalesInvoiceFormPage> {
  static const _bp = VoucherBlueprints.salesInvoice;

  final _formKey = GlobalKey<FormState>();
  late final _repo = createSalesInvoiceRepository(getIt<DioClient>());
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());
  late final _batchRepo = createItemBatchRepository(getIt<DioClient>());

  late SalesInvoiceDraft _draft;
  Ledger? _customer;
  Godown? _godown;
  EmployeeLite? _salesperson;
  ProjectLite? _project;

  /// Empty string = no conversion source.
  String _sourceType = '';
  SourceVoucherLite? _source;
  bool _posting = false;
  bool _loading = false;
  String? _error;
  bool get _isEdit => widget.entityId != null;

  @override
  void initState() {
    super.initState();
    _draft = SalesInvoiceDraft(
      voucherPrefix: _bp.defaultPrefix ?? 'SI',
      financialYear: _defaultFyCode(),
    );
    if (_isEdit) {
      _loadDraft();
    }
  }

  String _defaultFyCode() {
    final now = DateTime.now();
    return now.year.toString();
  }

  Future<void> _loadDraft() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getById(
      widget.entityId!,
      resolveItemLabel: _resolveItemLabel,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _loading = false;
          _error = _messageOf(failure);
        });
      },
      (detail) {
        if (detail.status != 'Draft') {
          setState(() {
            _loading = false;
            _error =
                'Only Draft invoices can be edited '
                '(status is ${detail.status}).';
          });
          return;
        }
        setState(() {
          _loading = false;
          _draft = SalesInvoiceDto.detailToDraft(detail);
          _customer = detail.customerLedgerId == null
              ? null
              : Ledger(
                  id: detail.customerLedgerId!,
                  name:
                      detail.billingName ??
                      'Ledger #${detail.customerLedgerId}',
                  openingBalance: Decimal.zero,
                );
          _godown = detail.godownId == null
              ? null
              : Godown(
                  id: detail.godownId!,
                  name: 'Godown #${detail.godownId}',
                );
          if (detail.salespersonEmployeeId != null) {
            _salesperson = EmployeeLite(
              id: detail.salespersonEmployeeId!,
              name:
                  detail.salespersonLabel ??
                  'Employee #${detail.salespersonEmployeeId}',
            );
          }
          if (detail.voucherProjectId != null) {
            _project = ProjectLite(
              id: detail.voucherProjectId!,
              name:
                  detail.projectLabel ?? 'Project #${detail.voucherProjectId}',
            );
          }
        });
        // Best-effort resolve display names.
        if (detail.godownId != null) {
          _godownRepo.getById(detail.godownId!).then((r) {
            r.fold((_) {}, (g) {
              if (mounted) setState(() => _godown = g);
            });
          });
        }
        if (detail.customerLedgerId != null) {
          _ledgerRepo.getById(detail.customerLedgerId!).then((r) {
            r.fold((_) {}, (l) {
              if (mounted) setState(() => _customer = l);
            });
          });
        }
        if (detail.salespersonEmployeeId != null) {
          _repo.getEmployee(detail.salespersonEmployeeId!).then((r) {
            r.fold((_) {}, (e) {
              if (mounted && e != null) setState(() => _salesperson = e);
            });
          });
        }
        if (detail.voucherProjectId != null) {
          _repo.getProject(detail.voucherProjectId!).then((r) {
            r.fold((_) {}, (p) {
              if (mounted && p != null) setState(() => _project = p);
            });
          });
        }
      },
    );
  }

  Future<String?> _resolveItemLabel(int itemId) async {
    final r = await _itemRepo.getById(itemId);
    return r.fold(
      (_) => null,
      (item) => item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
    );
  }

  LineInput? _lineInput(SalesInvoiceLine row) {
    if (!row.isComplete) return null;
    return LineInput(
      quantity: row.quantity,
      price: row.price,
      discountPercent: row.discountPercent,
      taxRate: row.taxRate,
    );
  }

  Future<void> _submit({required String status}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_draft.customerLedgerId == null) {
      setState(() => _error = 'Customer is required');
      return;
    }
    if (_draft.godownId == null) {
      setState(() => _error = 'Godown is required');
      return;
    }
    final complete = _draft.lines.where((l) => l.isComplete).toList();
    if (complete.isEmpty) {
      setState(
        () => _error = 'Add at least one complete line (item, qty, price)',
      );
      return;
    }
    if (!_isEdit && _draft.financialYear.trim().isEmpty) {
      setState(() => _error = 'Financial year is required');
      return;
    }

    setState(() {
      _posting = true;
      _error = null;
    });

    final draft = _draft.copyWith(lines: complete, saveStatus: status);

    if (_isEdit) {
      // Draft edit: replace header/lines; optional follow-up post via detail.
      final result = await _repo.updateDraft(widget.entityId!, draft);
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _posting = false;
            _error = _messageOf(failure);
          });
        },
        (_) {
          setState(() => _posting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Draft updated')));
          context.go('/transactions/sales-invoices/${widget.entityId}');
        },
      );
      return;
    }

    final result = await _repo.post(draft);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _posting = false;
          _error = _messageOf(failure);
        });
      },
      (posted) {
        final verb = status == 'Draft' ? 'Saved draft' : 'Posted';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$verb ${posted.voucherNo} · ${posted.total}'),
          ),
        );
        context.go('/transactions/sales-invoices/${posted.id}');
      },
    );
  }

  Future<void> _post() => _submit(status: 'Posted');

  Future<void> _saveDraft() => _submit(status: 'Draft');

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };

  void _updateLine(int index, SalesInvoiceLine line) {
    final lines = List<SalesInvoiceLine>.of(_draft.lines);
    lines[index] = line;
    setState(() => _draft = _draft.copyWith(lines: lines));
  }

  Widget _header() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Prefix',
                  initialValue: _draft.voucherPrefix,
                  enabled: !_posting,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(
                      voucherPrefix: v.isEmpty ? 'SI' : v,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Financial year',
                  initialValue: _draft.financialYear,
                  enabled: !_posting,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(financialYear: v),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppDateField(
            label: 'Voucher date',
            value: _draft.voucherDate,
            enabled: !_posting,
            onChanged: (d) {
              if (d != null) {
                setState(() => _draft = _draft.copyWith(voucherDate: d));
              }
            },
          ),
          const SizedBox(height: 12),
          FkLookupField<Ledger>(
            label: 'Customer',
            value: _customer,
            enabled: !_posting,
            displayOf: (l) {
              final code = l.code;
              return (code == null || code.isEmpty)
                  ? l.name
                  : '$code — ${l.name}';
            },
            loader: (q) async {
              final r = await _ledgerRepo.list(PageQuery(search: q));
              return r.fold((_) => const [], (p) => p.items);
            },
            onSelected: (l) => setState(() {
              _customer = l;
              _draft = _draft.copyWith(
                customerLedgerId: l?.id,
                customerLabel: l?.name,
                billingName: l?.name,
              );
            }),
            validator: (v) => v == null ? 'Customer is required' : null,
          ),
          const SizedBox(height: 12),
          FkLookupField<Godown>(
            label: 'Godown',
            value: _godown,
            enabled: !_posting,
            displayOf: (g) => g.name,
            loader: (q) async {
              final r = await _godownRepo.list(PageQuery(search: q));
              return r.fold((_) => const [], (p) => p.items);
            },
            onSelected: (g) => setState(() {
              _godown = g;
              _draft = _draft.copyWith(godownId: g?.id, godownLabel: g?.name);
            }),
            validator: (v) => v == null ? 'Godown is required' : null,
          ),
          const SizedBox(height: 12),
          FkLookupField<EmployeeLite>(
            label: 'Salesperson',
            value: _salesperson,
            enabled: !_posting,
            displayOf: (e) => e.label,
            loader: (q) async {
              final r = await _repo.searchEmployees(q);
              return r.fold((_) => const [], (list) => list);
            },
            onSelected: (e) => setState(() {
              _salesperson = e;
              _draft = _draft.copyWith(
                salespersonEmployeeId: e?.id,
                salespersonLabel: e?.label,
              );
            }),
          ),
          const SizedBox(height: 12),
          FkLookupField<ProjectLite>(
            label: 'Project',
            value: _project,
            enabled: !_posting,
            displayOf: (p) => p.label,
            loader: (q) async {
              final r = await _repo.searchProjects(q);
              return r.fold((_) => const [], (list) => list);
            },
            onSelected: (p) => setState(() {
              _project = p;
              _draft = _draft.copyWith(
                voucherProjectId: p?.id,
                projectLabel: p?.label,
              );
            }),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sourceType,
              decoration: const InputDecoration(
                labelText: 'Convert from',
                helperText: 'Optional Quotation / Sales Order conversion',
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('None')),
                DropdownMenuItem(
                  value: 'SalesOrder',
                  child: Text('Sales order'),
                ),
                DropdownMenuItem(value: 'Quotation', child: Text('Quotation')),
              ],
              onChanged: _posting
                  ? null
                  : (v) => setState(() {
                      _sourceType = v ?? '';
                      _source = null;
                      _draft = _draft.copyWith(
                        sourceVoucherId: null,
                        sourceVoucherType: null,
                        sourceVoucherLabel: null,
                      );
                    }),
            ),
            if (_sourceType.isNotEmpty) ...[
              const SizedBox(height: 12),
              FkLookupField<SourceVoucherLite>(
                label: 'Source $_sourceType',
                value: _source,
                enabled: !_posting,
                helperText: 'Loads customer, godown, and lines',
                displayOf: (s) => '${s.type} ${s.displayNo}',
                loader: (q) async {
                  final r = await _repo.searchSourceVouchers(
                    type: _sourceType,
                    query: q,
                  );
                  return r.fold((_) => const [], (list) => list);
                },
                onSelected: (s) async {
                  if (s == null) {
                    setState(() {
                      _source = null;
                      _draft = _draft.copyWith(
                        sourceVoucherId: null,
                        sourceVoucherType: null,
                        sourceVoucherLabel: null,
                      );
                    });
                    return;
                  }
                  final full = await _repo.getSourceVoucher(
                    type: s.type,
                    id: s.id,
                  );
                  if (!mounted) return;
                  full.fold((f) => setState(() => _error = _messageOf(f)), (
                    src,
                  ) {
                    setState(() {
                      _source = src;
                      _draft = _draft.copyWith(
                        sourceVoucherId: src.id,
                        sourceVoucherType: src.type,
                        sourceVoucherLabel: src.displayNo,
                        customerLedgerId: src.customerLedgerId,
                        billingName: src.billingName,
                        godownId: src.godownId ?? _draft.godownId,
                        lines: src.lines,
                      );
                      if (src.customerLedgerId != null) {
                        _customer = Ledger(
                          id: src.customerLedgerId!,
                          name:
                              src.billingName ??
                              'Ledger #${src.customerLedgerId}',
                          openingBalance: Decimal.zero,
                        );
                      }
                      if (src.godownId != null) {
                        _godown = Godown(
                          id: src.godownId!,
                          name: 'Godown #${src.godownId}',
                        );
                        _godownRepo.getById(src.godownId!).then((r) {
                          r.fold((_) {}, (g) {
                            if (mounted) {
                              setState(() {
                                _godown = g;
                                _draft = _draft.copyWith(godownLabel: g.name);
                              });
                            }
                          });
                        });
                      }
                    });
                  });
                },
              ),
            ],
          ],
          const SizedBox(height: 12),
          AppTextField(
            label: 'Billing name',
            initialValue: _draft.billingName,
            enabled: !_posting,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(billingName: v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(height: 12),
          AppNumberField(
            label: 'Credit days',
            initialValue: _draft.creditDays,
            enabled: !_posting,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(creditDays: v ?? 30)),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Narration',
            initialValue: _draft.narration,
            enabled: !_posting,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(narration: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  List<LineItemColumn<SalesInvoiceLine>> get _columns => [
    LineItemColumn(
      label: 'Item',
      flex: 3,
      cellBuilder: (context, row, i) => FkLookupField<InventoryItem>(
        label: 'Item',
        value: row.itemId == null
            ? null
            : InventoryItem(
                id: row.itemId!,
                name: row.itemLabel ?? '',
                code: '',
                price: row.price,
                basePrice: Decimal.zero,
                standardCost: Decimal.zero,
                vatRate: row.taxRate,
                openingStock: Decimal.zero,
                reorderLevel: Decimal.zero,
              ),
        enabled: !_posting,
        displayOf: (item) =>
            item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
        loader: (q) async {
          final r = await _itemRepo.list(PageQuery(search: q));
          return r.fold((_) => const [], (p) => p.items);
        },
        onSelected: (item) {
          if (item == null) {
            _updateLine(
              i,
              row.copyWith(itemId: null, itemLabel: null, batchId: null),
            );
            return;
          }
          _updateLine(
            i,
            row.copyWith(
              itemId: item.id,
              itemLabel: item.name,
              // Reset batch when item changes.
              batchId: null,
              price: item.price,
              taxRate: item.vatRate,
            ),
          );
        },
      ),
    ),
    LineItemColumn(
      label: 'SKU id',
      cellBuilder: (context, row, i) => AppNumberField(
        label: 'SKU',
        initialValue: row.skuId,
        enabled: !_posting,
        helperText: 'Optional',
        onChanged: (v) => _updateLine(i, row.copyWith(skuId: v)),
      ),
    ),
    LineItemColumn(
      label: 'Batch',
      flex: 2,
      cellBuilder: (context, row, i) => FkLookupField<ItemBatch>(
        label: 'Batch',
        value: row.batchId == null
            ? null
            : ItemBatch(
                id: row.batchId!,
                itemId: row.itemId ?? 0,
                batchNumber: '#${row.batchId}',
                costPrice: Decimal.zero,
                sellingPrice: Decimal.zero,
              ),
        enabled: !_posting && row.itemId != null,
        helperText: row.itemId == null
            ? 'Pick item first'
            : 'Optional — filters by item',
        displayOf: (b) => b.batchNumber,
        loader: (q) async {
          if (row.itemId == null) return const [];
          final r = await _batchRepo.list(
            PageQuery(search: q, filters: {'item_id': row.itemId}),
          );
          // Client-side item filter if BE ignores item_id query.
          return r.fold(
            (_) => const [],
            (p) => p.items
                .where((b) => b.itemId == row.itemId)
                .toList(growable: false),
          );
        },
        onSelected: (b) => _updateLine(i, row.copyWith(batchId: b?.id)),
      ),
    ),
    LineItemColumn(
      label: 'Qty',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Qty',
        initialValue: row.quantity,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(quantity: v ?? Decimal.one)),
      ),
    ),
    LineItemColumn(
      label: 'Price',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Price',
        initialValue: row.price,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
      ),
    ),
    LineItemColumn(
      label: 'Disc %',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Disc %',
        initialValue: row.discountPercent,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(discountPercent: v ?? Decimal.zero)),
      ),
    ),
    LineItemColumn(
      label: 'Tax %',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Tax %',
        initialValue: row.taxRate,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(taxRate: v ?? Decimal.zero)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Edit draft ${_bp.label}' : 'New ${_bp.label}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(child: LoadingState())
          else
            Expanded(
              child: DocumentSurface<SalesInvoiceLine>(
                blueprint: _bp,
                header: _header(),
                rows: _draft.lines,
                columns: _columns,
                onRowsChanged: (rows) =>
                    setState(() => _draft = _draft.copyWith(lines: rows)),
                newRow: SalesInvoiceLine.new,
                lineInputsOf: _lineInput,
                // Edit mode only saves draft lines (then approve/post from detail).
                onPost: _isEdit ? () => _submit(status: 'Draft') : _post,
                onSaveDraft: _isEdit ? null : _saveDraft,
                postLabel: _isEdit ? 'Save draft' : 'Post',
                posting: _posting,
                enabled: !_posting,
                errorText: _error,
              ),
            ),
        ],
      ),
    );
  }
}
