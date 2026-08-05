import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _entryTypeLabels = <int, String>{
  0: 'Custom',
  1: 'Standard',
  2: 'MRP',
};

/// Nested entries grid for a saved price list (edit mode only).
class PriceListEntriesPanel extends StatefulWidget {
  const PriceListEntriesPanel({
    required this.priceListId,
    required this.repository,
    super.key,
  });

  final int priceListId;
  final Repository<PriceListEntry, int> repository;

  @override
  State<PriceListEntriesPanel> createState() => _PriceListEntriesPanelState();
}

class _PriceListEntriesPanelState extends State<PriceListEntriesPanel> {
  bool _loading = true;
  String? _error;
  List<PriceListEntry> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PriceListEntriesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.priceListId != widget.priceListId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.list(
      PageQuery(
        filters: {'Price_List_ID': widget.priceListId},
        limit: 100,
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _items = const [];
      }),
      (page) => setState(() {
        _loading = false;
        _error = null;
        _items = page.items;
      }),
    );
  }

  Future<void> _openEditor({PriceListEntry? existing}) async {
    final draft = await showDialog<PriceListEntry>(
      context: context,
      builder: (ctx) => _EntryEditorDialog(
        priceListId: widget.priceListId,
        existing: existing,
      ),
    );
    if (draft == null || !mounted) return;

    final result = existing == null
        ? await widget.repository.create(draft)
        : await widget.repository.update(existing.id, draft);
    if (!mounted) return;
    result.fold(
      (f) => _snack(f.message, isError: true),
      (_) {
        _snack(existing == null ? 'Entry created' : 'Entry updated');
        _load();
      },
    );
  }

  Future<void> _delete(PriceListEntry entry) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete entry?',
      message:
          'Permanently delete the rate for item "${entry.itemId}"? '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final result = await widget.repository.delete(entry.id);
    if (!mounted) return;
    result.fold(
      (f) => _snack(f.message, isError: true),
      (_) {
        _snack('Entry deleted');
        _load();
      },
    );
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price list entries',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Per-item rates. Item code matches inventory '
                        'Item_Code.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
                FilledButton.tonalIcon(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (!_loading && _items.isEmpty && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No entries yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_items.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Item code')),
                    DataColumn(label: Text('Price'), numeric: true),
                    DataColumn(label: Text('UOM')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('%'), numeric: true),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final e in _items)
                      DataRow(
                        cells: [
                          DataCell(Text(e.itemId)),
                          DataCell(Text(e.price.toStringAsFixed(2))),
                          DataCell(
                            Text(
                              (e.uomId?.isNotEmpty ?? false) ? e.uomId! : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              _entryTypeLabels[e.entryType] ?? 'Custom',
                            ),
                          ),
                          DataCell(
                            Text(
                              e.percent != null
                                  ? e.percent!.toStringAsFixed(1)
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => _openEditor(existing: e),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  onPressed: () => _delete(e),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({required this.priceListId, this.existing});

  final int priceListId;
  final PriceListEntry? existing;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  late final TextEditingController _itemCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _uomCtrl;
  late final TextEditingController _percentCtrl;
  late int _entryType;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _itemCtrl = TextEditingController(text: e?.itemId ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? e.price.toString() : '',
    );
    _uomCtrl = TextEditingController(text: e?.uomId ?? '');
    _percentCtrl = TextEditingController(
      text: e?.percent != null ? e!.percent.toString() : '',
    );
    _entryType = e?.entryType ?? 0;
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _priceCtrl.dispose();
    _uomCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final itemId = _itemCtrl.text.trim();
    if (itemId.isEmpty) {
      setState(() => _error = 'Item code is required');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      setState(() => _error = 'Price must be a number');
      return;
    }
    final percentText = _percentCtrl.text.trim();
    final percent = percentText.isEmpty ? null : double.tryParse(percentText);
    if (percentText.isNotEmpty && percent == null) {
      setState(() => _error = 'Percent must be a number');
      return;
    }
    final uom = _uomCtrl.text.trim();
    Navigator.of(context).pop(
      PriceListEntry(
        id: widget.existing?.id ?? 0,
        itemId: itemId,
        price: price,
        priceListId: widget.priceListId,
        percent: percent,
        uomId: uom.isEmpty ? null : uom,
        entryType: _entryType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add entry' : 'Edit entry'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextField(
                controller: _itemCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item code',
                  hintText: 'Inventory Item_Code',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _uomCtrl,
                decoration: const InputDecoration(
                  labelText: 'UOM Id (optional)',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownMenu<int>(
                initialSelection: _entryType,
                label: const Text('Price type'),
                dropdownMenuEntries: [
                  for (final e in _entryTypeLabels.entries)
                    DropdownMenuEntry(value: e.key, label: e.value),
                ],
                onSelected: (v) {
                  if (v != null) setState(() => _entryType = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _percentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Percent (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
