import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  testWidgets('renders the given label', (tester) async {
    await tester.pumpWidget(
      _wrap(const StatusChip(status: EntityStatus.posted, label: 'Posted')),
    );

    expect(find.text('Posted'), findsOneWidget);
  });

  testWidgets('shows a sync icon only for pendingSync', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatusChip(status: EntityStatus.pendingSync, label: 'Pending'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sync), findsOneWidget);

    await tester.pumpWidget(
      _wrap(const StatusChip(status: EntityStatus.draft, label: 'Draft')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sync), findsNothing);
  });

  testWidgets('backgrounds the chip with the voucher status token', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const StatusChip(status: EntityStatus.posted, label: 'Posted')),
    );

    final chip = tester.widget<Chip>(find.byType(Chip));
    final tokens = AppTheme.light.extension<AppTokens>()!;
    expect(
      chip.backgroundColor,
      tokens.voucherStatusColors.posted.withValues(alpha: 0.12),
    );
  });
}
