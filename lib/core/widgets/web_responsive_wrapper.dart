import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_language_switcher.dart';

/// A wrapper that constrains the app content on wide desktop/web screens
/// so it sits centered in a sleek, modern mobile/tablet shell instead of stretching 100%.
class WebResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const WebResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width > 600px (Desktop / Laptop / Wide Tablet view)
        if (constraints.maxWidth > 600) {
          const double maxAppWidth = 480.0;
          final double currentWidth = constraints.maxWidth;
          final double appWidth = currentWidth > maxAppWidth ? maxAppWidth : currentWidth;
          
          final double availableHeight = constraints.maxHeight;
          final double appHeight = availableHeight > 960 ? 900 : (availableHeight > 640 ? availableHeight - 48 : availableHeight);

          final mediaQuery = MediaQuery.of(context);

          return Scaffold(
            backgroundColor: const Color(0xFF0B0F19), // Dark luxury slate background
            body: Stack(
              children: [
                // Top Ambient Background Glow (Brand Blue)
                Positioned(
                  top: -120,
                  left: -80,
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                    ),
                  ),
                ),
                // Bottom Ambient Background Glow (Brand Green)
                Positioned(
                  bottom: -120,
                  right: -80,
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withOpacity(0.10),
                    ),
                  ),
                ),

                // Top Desktop Header Bar (Logo & Language Switcher)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Brand Header
                          Row(
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                width: 28,
                                height: 28,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.home_work_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Stanomer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                child: const Text(
                                  'Web',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF60A5FA),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Desktop Language Switcher
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: Theme.of(context).textTheme.copyWith(
                                  bodyMedium: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              child: const WebLanguageSwitcher(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Centered App Frame
                Center(
                  child: Container(
                    width: appWidth,
                    height: appHeight,
                    margin: const EdgeInsets.only(top: 40, bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 50,
                          spreadRadius: 4,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaQuery(
                      data: mediaQuery.copyWith(
                        size: Size(appWidth, appHeight),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // On mobile screen widths (<= 600px), return normal 100% full screen
        return child;
      },
    );
  }
}
