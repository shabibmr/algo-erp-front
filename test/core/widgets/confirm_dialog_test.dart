import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(ValueChanged<BuildContext> onBuild) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () => onBuild(context),
            child: const Text('open'),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('resolves true when the confirm button is tapped', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _wrap((context) async {
        result = await showConfirmDialog(
          context,
          title: 'Delete brand?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
      }),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete brand?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('resolves false when cancel is tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap((context) async {
        result = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: 'Unsaved edits will be lost.',
        );
      }),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('resolves false when dismissed without a choice', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _wrap((context) async {
        result = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: 'Unsaved edits will be lost.',
        );
      }),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the modal barrier, outside the dialog card, to dismiss it.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
