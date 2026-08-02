import 'flavors.dart';
import 'main.dart' as app_main;

/// Development Entry Point
///
/// Run command:
/// `flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env.dev`
void main() {
  F.appFlavor = Flavor.dev;
  app_main.main();
}
