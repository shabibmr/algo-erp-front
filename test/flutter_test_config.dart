import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Global test harness. Disables runtime font downloads so widget tests do not
/// thrash the network / OOM on CI and local machines without cache.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
