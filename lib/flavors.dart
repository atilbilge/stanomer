import 'core/config/env_config.dart';

enum Flavor {
  dev,
  prod,
}

class F {
  static Flavor? _appFlavor;

  static Flavor get appFlavor {
    if (_appFlavor != null) return _appFlavor!;

    // Flutter CLI automatically passes FLUTTER_APP_FLAVOR when using --flavor
    const cliFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    if (cliFlavor.toLowerCase() == 'dev') return Flavor.dev;
    if (cliFlavor.toLowerCase() == 'prod') return Flavor.prod;

    // Default fallback to Production
    return Flavor.prod;
  }

  static set appFlavor(Flavor flavor) {
    _appFlavor = flavor;
  }

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'Stanomer Dev';
      case Flavor.prod:
        return 'Stanomer';
    }
  }
}
