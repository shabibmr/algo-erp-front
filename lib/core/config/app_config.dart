enum Flavor { dev, staging, prod }

/// Process-wide runtime config (flavor, API base URL, dev test helpers).
///
/// Call [init] once from each flavor entrypoint before DI / `runApp`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    this.skipLogin = false,
    this.devUsername = '',
    this.devPassword = '',
    this.devFullAccess = false,
  });

  final Flavor flavor;
  final String apiBaseUrl;

  /// When true (dev only), boot signs in with [devUsername]/[devPassword]
  /// instead of showing the login screen.
  final bool skipLogin;

  /// Dev auto-login username (set in `main_dev.dart`, typically `user`).
  final String devUsername;

  /// Dev auto-login password (set in `main_dev.dart`).
  final String devPassword;

  /// When true (dev only), permission checks allow every module/action so hub
  /// tiles and gates are usable even if the role matrix is incomplete.
  final bool devFullAccess;

  static AppConfig? _instance;

  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig.init must be called before use');
    }
    return config;
  }

  /// Whether [init] has run (false in unit tests that never boot the app).
  static bool get isReady => _instance != null;

  // A method (not a setter) so call sites read as `AppConfig.init(x)`.
  // ignore: use_setters_to_change_properties
  static void init(AppConfig config) => _instance = config;

  bool get isProd => flavor == Flavor.prod;
  bool get isDev => flavor == Flavor.dev;

  /// Safe to use from AuthBloc / permissions even when [isReady] is false.
  static bool get shouldAutoLogin =>
      isReady && !instance.isProd && instance.skipLogin;

  static bool get shouldGrantFullAccess =>
      isReady && !instance.isProd && instance.devFullAccess;
}
