import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/responsive/master_detail_layout.dart';
import 'package:algo_erp_front/core/responsive/responsive_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Breakpoints Unit Tests', () {
    test('classifies screen widths correctly into DeviceClass', () {
      expect(Breakpoints.classify(375), DeviceClass.mobile);
      expect(Breakpoints.classify(599), DeviceClass.mobile);
      expect(Breakpoints.classify(600), DeviceClass.tablet);
      expect(Breakpoints.classify(1023), DeviceClass.tablet);
      expect(Breakpoints.classify(1024), DeviceClass.desktop);
      expect(Breakpoints.classify(1439), DeviceClass.desktop);
      expect(Breakpoints.classify(1440), DeviceClass.large);
      expect(Breakpoints.classify(1920), DeviceClass.large);
    });
  });

  group('ResponsiveBuilder Widget Tests', () {
    testWidgets('renders mobile layout on mobile screen width (< 600px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              mobile: (_) => const Text('Mobile Layout'),
              desktop: (_) => const Text('Desktop Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('renders desktop layout on desktop web size (>= 1024px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              mobile: (_) => const Text('Mobile Layout'),
              desktop: (_) => const Text('Desktop Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
    });
  });

  group('AdaptiveLayout Widget Tests', () {
    testWidgets('constrains content width and applies desktop padding on wide screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLayout(
              maxContentWidth: 1200,
              child: SizedBox(height: 100, child: Text('Content')),
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.text('Content'),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrainedBox.constraints.maxWidth, equals(1200.0));
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('MasterDetailLayout Widget Tests', () {
    testWidgets('renders side-by-side list & detail on desktop screen width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MasterDetailLayout(
              list: Text('List Pane'),
              detail: Text('Detail Pane'),
            ),
          ),
        ),
      );

      expect(find.text('List Pane'), findsOneWidget);
      expect(find.text('Detail Pane'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('renders single list pane on mobile screen width when no detail selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MasterDetailLayout(
              list: Text('List Pane'),
            ),
          ),
        ),
      );

      expect(find.text('List Pane'), findsOneWidget);
      expect(find.byType(Row), findsNothing);
    });
  });
}
