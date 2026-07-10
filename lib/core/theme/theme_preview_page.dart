import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:algo_erp_front/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Visual catalog of every design token: colors, type ramp, buttons,
/// status chips — toggleable across light/dark and LTR/RTL so a reviewer
/// can validate the whole system in one screen.
class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  TextDirection _direction = TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final themeCubit = context.read<ThemeCubit>();

    return Directionality(
      textDirection: _direction,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theme Preview'),
          actions: [
            IconButton(
              tooltip: 'Toggle direction',
              icon: const Icon(Icons.format_textdirection_r_to_l),
              onPressed: () => setState(() {
                _direction = _direction == TextDirection.ltr
                    ? TextDirection.rtl
                    : TextDirection.ltr;
              }),
            ),
            IconButton(
              tooltip: 'Toggle theme mode',
              icon: const Icon(Icons.brightness_6),
              onPressed: themeCubit.toggle,
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.all(tokens.spacing.lg),
          children: [
            const _SectionLabel('Semantic colors'),
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: [
                _ColorSwatch('Success', tokens.semanticColors.success),
                _ColorSwatch('Warning', tokens.semanticColors.warning),
                _ColorSwatch('Danger', tokens.semanticColors.danger),
                _ColorSwatch('Info', tokens.semanticColors.info),
              ],
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionLabel('Voucher status colors'),
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: [
                _ColorSwatch('Draft', tokens.voucherStatusColors.draft),
                _ColorSwatch('Approved', tokens.voucherStatusColors.approved),
                _ColorSwatch('Posted', tokens.voucherStatusColors.posted),
                _ColorSwatch(
                  'Cancelled',
                  tokens.voucherStatusColors.cancelled,
                ),
                _ColorSwatch('Rejected', tokens.voucherStatusColors.rejected),
                _ColorSwatch(
                  'Pending sync',
                  tokens.voucherStatusColors.pendingSync,
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionLabel('Typography ramp'),
            Text(
              'Display large',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              'Headline medium',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Title large',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Body large',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Label small',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionLabel('Buttons'),
            Wrap(
              spacing: tokens.spacing.sm,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionLabel('Status chips'),
            Wrap(
              spacing: tokens.spacing.sm,
              children: [
                Chip(
                  label: const Text('Draft'),
                  backgroundColor: tokens.voucherStatusColors.draft
                      .withValues(alpha: 0.15),
                ),
                Chip(
                  label: const Text('Posted'),
                  backgroundColor: tokens.voucherStatusColors.posted
                      .withValues(alpha: 0.15),
                ),
                Chip(
                  label: const Text('Pending sync'),
                  avatar: const Icon(Icons.sync, size: 16),
                  backgroundColor: tokens.voucherStatusColors.pendingSync
                      .withValues(alpha: 0.15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
