import 'package:flutter/material.dart';
import '../../flavors.dart';
import '../config/env_config.dart';

/// Reusable App Logo widget that automatically displays a "DEV" badge in Dev mode.
class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;

  const AppLogo({
    super.key,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDev = EnvConfig.isDev || F.appFlavor == Flavor.dev;

    final logoImage = Image.asset(
      'assets/images/logo_no_bg.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/android_launcher.png',
        height: height,
        width: width,
      ),
    );

    if (!isDev) {
      return logoImage;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            logoImage,
            Positioned(
              top: -3,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
