import 'package:algo_erp_front/app.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(
    const AppConfig(
      flavor: Flavor.staging,
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://staging-api.algoerp.internal',
      ),
    ),
  );
  await configureDependencies();
  runApp(const App());
}
