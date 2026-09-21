import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'floating_contact_widget.dart';

/// A wrapper that constrains the app content on wide desktop/web screens
/// and presents floating utility overlays like the WhatsApp & Viber contact button on Web.
class WebResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const WebResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobileWeb = screenWidth < 768;

    return Stack(
      children: [
        child,
        Positioned(
          right: isMobileWeb ? 16 : 24,
          bottom: isMobileWeb ? 80 : 24,
          child: const FloatingContactWidget(),
        ),
      ],
    );
  }
}

