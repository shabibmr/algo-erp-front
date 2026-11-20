import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_dropdown_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_repository.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_di.dart';
import 'package:flutter/material.dart';

class ResolvedVariantResult {
  const ResolvedVariantResult({
    required this.skuId,
    required this.skuCode,
    required this.skuName,
    required this.attributeSummary,
    this.rate,
    this.isNew = false,
  });

  final int skuId;
  final String skuCode;
  final String skuName;
  final String attributeSummary;
  final double? rate;
  final bool isNew;
}

class VariantPickerDialog extends StatefulWidget {
  const VariantPickerDialog({
    required this.itemId,
    required this.itemName,
    super.key,
    this.itemCode,
    this.currentSkuId,
  });

  final int itemId;
  final String itemName;
  final String? itemCode;
  final int? currentSkuId;

  static Future<ResolvedVariantResult?> show(
    BuildContext context, {
    required int itemId,
    required String itemName,
    String? itemCode,
    int? currentSkuId,
  }) {
    return showDialog<ResolvedVariantResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VariantPickerDialog(
        itemId: itemId,
        itemName: itemName,
        itemCode: itemCode,
        currentSkuId: currentSkuId,
      ),
    );
  }

  @override
  State<VariantPickerDialog> createState() => _VariantPickerDialogState();
}

class _VariantPickerDialogState extends State<VariantPickerDialog> {
  late final ItemAttributeRepository _repo = itemAttributeRepository();

  bool _loading = true;
  String? _error;
  List<ItemAttributeAssignment> _assigned = [];
  Map<int, List<String>> _suggestions = {};

  // Form state: attributeId -> chosen value (valueId set for predetermined options)
  final Map<int, VariantAttributeInput> _selectedValues = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final assigned = await _repo.getAssignments(widget.itemId);
    final suggestions = await _repo.getSuggestions(widget.itemId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      assigned.fold(
        (f) => _error = failureText(f, 'Failed to load item attributes'),
        (v) => _assigned = v,
      );
      if (_error == null) {
        suggestions.fold(
          (f) => _error = failureText(f, 'Failed to load item attributes'),
          (v) => _suggestions = v,
        );
      }
    });
  }

  Future<void> _resolveAndConfirm() async {
    final inputs = [
      for (final e in _selectedValues.values)
        if (e.value.trim().isNotEmpty)
          VariantAttributeInput(
            attributeId: e.attributeId,
            value: e.value.trim(),
            valueId: e.valueId,
          ),
    ];

    if (inputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter at least one attribute value'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final res = await _repo.resolveVariant(widget.itemId, inputs);
    if (!mounted) return;

    res.fold(
      (f) {
        setState(() {
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureText(f, 'Failed to resolve variant SKU')),
          ),
        );
      },
      (r) => Navigator.of(context).pop(
        ResolvedVariantResult(
          skuId: r.sku.id,
          skuCode: r.sku.skuCode,
          skuName: r.sku.skuName,
          attributeSummary: r.sku.attributeSummary,
          rate: r.sku.rate?.toDouble(),
          isNew: r.isNew,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Variant Attributes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: tokens.spacing.xs),
                        Text(
                          widget.itemName,
                          style: TextStyle(
                            color: tokens.brand.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Divider(height: tokens.spacing.lg, color: tokens.brand.mist),
              Expanded(
                child: _loading
                    ? const Center(child: LoadingState())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: tokens.semanticColors.danger),
                        ),
                      )
                    : _assigned.isEmpty
                    ? Center(
                        child: Text(
                          'No attributes configured for this item.\nAssign attributes in Item Master first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.brand.inkMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _assigned.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: tokens.spacing.md),
                        itemBuilder: (ctx, i) {
                          return _buildAttributeField(_assigned[i].attribute);
                        },
                      ),
              ),
              Divider(height: tokens.spacing.lg, color: tokens.brand.mist),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  FilledButton.icon(
                    onPressed: _submitting || _assigned.isEmpty
                        ? null
                        : _resolveAndConfirm,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      _submitting ? 'Resolving...' : 'Confirm & Apply SKU',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeField(ProductAttribute attr) {
    final tokens = context.tokens;

    if (attr.isGroup) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.brand.mist),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 18,
                    color: tokens.brand.lagoon,
                  ),
                  SizedBox(width: tokens.spacing.xs),
                  Text(
                    attr.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.sm),
              ...attr.subAttributes.map(
                (sub) => Padding(
                  padding: EdgeInsets.only(
                    top: tokens.spacing.xs,
                    bottom: tokens.spacing.xs,
                  ),
                  child: _buildLeafAttributeInput(sub),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildLeafAttributeInput(attr);
  }

  Widget _buildLeafAttributeInput(ProductAttribute attr) {
    final attrId = attr.id;
    final labelWithUnit = attr.unit != null
        ? '${attr.name} (${attr.unit})'
        : attr.name;

    if (attr.isPredetermined) {
      final options = attr.options;
      final currentValue = _selectedValues[attrId]?.value;

      final labels = {
        for (final opt in options)
          opt.value: opt.valueCode != null && opt.valueCode != opt.value
              ? '${opt.value} (${opt.valueCode})'
              : opt.value,
      };

      return AppDropdownField<String>(
        label: labelWithUnit,
        value: currentValue,
        items: options.map((o) => o.value).toList(),
        labelOf: (v) => labels[v] ?? v,
        onChanged: (val) {
          if (val == null) {
            _selectedValues.remove(attrId);
          } else {
            final matched = options.where((o) => o.value == val).firstOrNull;
            _selectedValues[attrId] = VariantAttributeInput(
              attributeId: attrId,
              value: val,
              valueId: matched?.id,
            );
          }
          setState(() {});
        },
      );
    }

    // EDITABLE: Combobox ("Dropdown + Add New")
    final suggestions = _suggestions[attrId] ?? [];
    final currentValue = _selectedValues[attrId]?.value ?? '';

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: currentValue),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final filtered = suggestions
            .where((s) => s.toLowerCase().contains(query))
            .toList();
        if (textEditingValue.text.isNotEmpty &&
            !suggestions.contains(textEditingValue.text)) {
          return [textEditingValue.text, ...filtered];
        }
        return filtered;
      },
      onSelected: (selection) {
        _selectedValues[attrId] = VariantAttributeInput(
          attributeId: attrId,
          value: selection,
        );
        setState(() {});
      },
      fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
        return AppTextField(
          controller: controller,
          focusNode: focusNode,
          label: labelWithUnit,
          hintText: suggestions.isNotEmpty
              ? 'Select past (${suggestions.take(2).join(', ')}) or type new...'
              : 'Enter ${attr.name}...',
          onChanged: (val) {
            _selectedValues[attrId] = VariantAttributeInput(
              attributeId: attrId,
              value: val,
            );
          },
        );
      },
    );
  }
}
