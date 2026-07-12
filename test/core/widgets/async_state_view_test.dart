import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/view_state.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders a spinner for ViewLoading', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncStateView<String>(
          state: const ViewLoading<String>(),
          builder: (context, data) => Text(data),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('renders EmptyState for ViewEmpty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncStateView<String>(
          state: const ViewEmpty<String>(),
          builder: (context, data) => Text(data),
        ),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('renders the data builder for ViewData', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncStateView<String>(
          state: const ViewData<String>('hello world'),
          builder: (context, data) => Text(data),
        ),
      ),
    );

    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('renders ErrorState with the failure message and wires retry', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        AsyncStateView<String>(
          state: const ViewError<String>(Failure.network('offline')),
          onRetry: () => retried = true,
          builder: (context, data) => Text(data),
        ),
      ),
    );

    expect(find.text('offline'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
