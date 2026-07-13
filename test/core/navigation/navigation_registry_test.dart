import 'package:algo_erp_front/core/navigation/navigation_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry includes desk and reports', () {
    final all = NavigationRegistry.all();
    expect(all.any((d) => d.route == '/dashboard'), isTrue);
    expect(all.any((d) => d.route.startsWith('/reports/')), isTrue);
  });

  test('search matches labels', () {
    final hits = NavigationRegistry.search('sales');
    expect(hits, isNotEmpty);
    expect(hits.any((d) => d.label.toLowerCase().contains('sales')), isTrue);
  });
}
