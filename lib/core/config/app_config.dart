enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  static late AppConfig instance;

  // A method (not a setter) so call sites read as `AppConfig.init(x)`.
  // ignore: use_setters_to_change_properties
  static void init(AppConfig config) => instance = config;

  bool get isProd => flavor == Flavor.prod;
}
