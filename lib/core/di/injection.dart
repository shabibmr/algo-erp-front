import 'package:algo_erp_front/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true, asExtension: false)
Future<void> configureDependencies() async => init(getIt);
