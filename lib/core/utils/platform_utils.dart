import 'package:flutter/foundation.dart';

/// Returns true if in-app purchases are supported on the current platform.
/// Purchases are only available on iOS and Android (not web or macOS).
bool get isPurchaseSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
}

/// Returns true if Apple Sign-In should be shown.
bool get isAppleSignInSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
}

/// Returns true if Google Sign-In should be shown.
bool get isGoogleSignInSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
}
