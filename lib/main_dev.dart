import 'package:algo_erp_front/app.dart';
import 'package:algo_erp_front/core/bloc/app_bloc_observer.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  AppConfig.init(
    const AppConfig(
      flavor: Flavor.dev,
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      ),
      // Local testing: land on the desk as `user` with full UI access.
      // Disable: --dart-define=SKIP_LOGIN=false
      // Creds: --dart-define=DEV_USERNAME=… --dart-define=DEV_PASSWORD=…
      skipLogin: bool.fromEnvironment('SKIP_LOGIN', defaultValue: true),
      devUsername: String.fromEnvironment('DEV_USERNAME', defaultValue: 'user'),
      devPassword: String.fromEnvironment(
        'DEV_PASSWORD',
        defaultValue: '123456',
      ),
      devFullAccess: bool.fromEnvironment(
        'DEV_FULL_ACCESS',
        defaultValue: true,
      ),
    ),
  );
  await configureDependencies();
  runApp(const App());
}
