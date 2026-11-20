import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_dropdown_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
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
  final DioClient _dio = getIt<DioClient>();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _assignedAttributes = [];
  Map<int, List<String>> _suggestions = {};

  // Form state: attributeId -> { 'value': String, 'valueId': int? }
  final Map<int, Map<String, dynamic>> _selectedValues = {};
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

    try {
      final attrRes = await _dio.get<Map<String, dynamic>>(
        '/inventory/item/${widget.itemId}/attributes',
      );
      final rawAttrs = attrRes.data?['data'] as List<dynamic>? ?? [];
      _assignedAttributes = rawAttrs.cast<Map<String, dynamic>>();

      final suggRes = await _dio.get<Map<String, dynamic>>(
        '/inventory/item/${widget.itemId}/attribute-suggestions',
      );
      final rawSugg = suggRes.data?['data'] as Map<String, dynamic>? ?? {};
      _suggestions = rawSugg.map((k, v) => MapEntry(
            int.parse(k),
            (v as List<dynamic>).map((e) => e.toString()).toList(),
          ));

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load item attributes: $e';
      });
    }
  }

  Future<void> _resolveAndConfirm() async {
    final attributesPayload = <Map<String, dynamic>>[];

    for (final entry in _selectedValues.entries) {
      final attrId = entry.key;
      final valMap = entry.value;
      final val = valMap['value']?.toString().trim();
      if (val != null && val.isNotEmpty) {
        attributesPayload.add({
          'attributeId': attrId,
          'value': val,
          if (valMap['valueId'] != null) 'valueId': valMap['valueId'],
        });
      }
    }

    if (attributesPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter at least one attribute value')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/inventory/sku/resolve-variant',
        data: {
          'itemId': widget.itemId,
          'attributes': attributesPayload,
        },
      );

      final data = res.data?['data'] as Map<String, dynamic>? ?? {};
      final skuData = data['sku'] as Map<String, dynamic>? ?? {};
      final isNew = data['isNew'] as bool? ?? false;

      final result = ResolvedVariantResult(
        skuId: skuData['id'] as int? ?? 0,
        skuCode: skuData['sku_code'] as String? ?? '',
        skuName: skuData['sku_name'] as String? ?? '',
        attributeSummary: skuData['attribute_summary'] as String? ?? '',
        rate: (skuData['rate'] != null)
            ? double.tryParse(skuData['rate'].toString())
            : null,
        isNew: isNew,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve variant SKU: $e')),
      );
    }
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
                            color: tokens.brand.slate,
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
                        ? Center(child: Text(_error!, style: TextStyle(color: tokens.semanticColors.danger)))
                        : _assignedAttributes.isEmpty
                            ? Center(
                                child: Text(
                                  'No attributes configured for this item.\nAssign attributes in Item Master first.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: tokens.brand.slate),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _assignedAttributes.length,
                                separatorBuilder: (_, __) => SizedBox(height: tokens.spacing.md),
                                itemBuilder: (ctx, i) {
                                  final assign = _assignedAttributes[i];
                                  final attr = assign['attribute'] as Map<String, dynamic>? ?? {};
                                  return _buildAttributeField(attr);
                                },
                              ),
              ),
              Divider(height: tokens.spacing.lg, color: tokens.brand.mist),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  FilledButton.icon(
                    onPressed: _submitting || _assignedAttributes.isEmpty
                        ? null
                        : _resolveAndConfirm,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_submitting ? 'Resolving...' : 'Confirm & Apply SKU'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeField(Map<String, dynamic> attr) {
    final tokens = context.tokens;
    final attrId = attr['id'] as int? ?? 0;
    final attrName = attr['attribute_name'] as String? ?? '';
    final attrType = attr['attribute_type'] as String? ?? 'PREDETERMINED';
    final unit = attr['unit'] as String?;

    if (attrType == 'GROUP') {
      final subAttrs = (attr['sub_attributes'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.brand.mist),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_outlined, size: 18, color: tokens.brand.primary),
                  SizedBox(width: tokens.spacing.xs),
                  Text(
                    attrName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.sm),
              ...subAttrs.map((sub) => Padding(
                    padding: EdgeInsets.only(top: tokens.spacing.xs, bottom: tokens.spacing.xs),
                    child: _buildLeafAttributeInput(sub),
                  )),
            ],
          ),
        ),
      );
    }

    return _buildLeafAttributeInput(attr);
  }

  Widget _buildLeafAttributeInput(Map<String, dynamic> attr) {
    final tokens = context.tokens;
    final attrId = attr['id'] as int? ?? 0;
    final attrName = attr['attribute_name'] as String? ?? '';
    final attrType = attr['attribute_type'] as String? ?? 'PREDETERMINED';
    final unit = attr['unit'] as String?;
    final labelWithUnit = unit != null ? '$attrName ($unit)' : attrName;

    if (attrType == 'PREDETERMINED') {
      final options = (attr['values'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final currentValue = _selectedValues[attrId]?['value'] as String?;

      return AppDropdownField<String>(
        label: labelWithUnit,
        value: currentValue,
        items: options
            .map((opt) => DropdownMenuItem<String>(
                  value: opt['attribute_value'] as String,
                  child: Text(
                    opt['value_code'] != null && opt['value_code'] != opt['attribute_value']
                        ? '${opt['attribute_value']} (${opt['value_code']})'
                        : opt['attribute_value'] as String,
                  ),
                ))
            .toList(),
        onChanged: (val) {
          if (val == null) {
            _selectedValues.remove(attrId);
          } else {
            final matched = options.firstWhere(
              (o) => o['attribute_value'] == val,
              orElse: () => {},
            );
            _selectedValues[attrId] = {
              'value': val,
              'valueId': matched['id'],
            };
          }
          setState(() {});
        },
      );
    }

    // EDITABLE: Combobox ("Dropdown + Add New")
    final suggestions = _suggestions[attrId] ?? [];
    final currentValue = _selectedValues[attrId]?['value'] as String? ?? '';

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: currentValue),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final filtered = suggestions.where((s) => s.toLowerCase().contains(query)).toList();
        if (textEditingValue.text.isNotEmpty && !suggestions.contains(textEditingValue.text)) {
          return [textEditingValue.text, ...filtered];
        }
        return filtered;
      },
      onSelected: (selection) {
        _selectedValues[attrId] = {
          'value': selection,
          'valueId': null,
        };
        setState(() {});
      },
      fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
        return AppTextField(
          controller: controller,
          focusNode: focusNode,
          label: labelWithUnit,
          hintText: suggestions.isNotEmpty
              ? 'Select past (${suggestions.take(2).join(', ')}) or type new...'
              : 'Enter $attrName...',
          onChanged: (val) {
            _selectedValues[attrId] = {
              'value': val,
              'valueId': null,
            };
          },
        );
      },
    );
  }
}
