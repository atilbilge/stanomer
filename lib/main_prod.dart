import 'flavors.dart';
import 'main.dart' as app_main;

/// Production Entry Point
///
/// Run command:
/// `flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=.env.prod`
void main() {
  F.appFlavor = Flavor.prod;
  app_main.main();
}
