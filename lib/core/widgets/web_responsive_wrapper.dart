import 'package:flutter/material.dart';
import 'web_language_switcher.dart';
import 'app_logo.dart';

/// A wrapper that constrains the app content on wide desktop/web screens
/// so it sits centered in a sleek, modern mobile/tablet shell instead of stretching 100%.
class WebResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const WebResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Return full-width responsive child directly so desktop layouts expand naturally
    return child;
  }
}
