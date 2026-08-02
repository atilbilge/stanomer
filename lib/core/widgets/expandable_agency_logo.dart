import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_logo.dart';

/// Interactive Agency Logo widget that displays a compact logo in headers/cards
/// and expands into a full-screen zoomable preview modal when tapped.
class ExpandableAgencyLogo extends StatelessWidget {
  final String? logoUrl;
  final String title;
  final double height;
  final double? width;
  final Widget? fallbackWidget;
  final BorderRadius? borderRadius;

  const ExpandableAgencyLogo({
    super.key,
    required this.logoUrl,
    required this.title,
    this.height = 32,
    this.width,
    this.fallbackWidget,
    this.borderRadius,
  });

  void _showExpandedLogo(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _AgencyLogoViewerDialog(
        logoUrl: logoUrl,
        title: title,
        fallbackWidget: fallbackWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(6);
    final rawUrl = logoUrl?.trim();
    final hasUrl = rawUrl != null && rawUrl.isNotEmpty;
    final effectiveUrl = hasUrl && kIsWeb
        ? (rawUrl.contains('supabase.co') || rawUrl.contains('localhost') || rawUrl.contains('127.0.0.1')
            ? rawUrl
            : 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl.replaceFirst(RegExp(r'^https?://'), ''))}')
        : rawUrl;

    Widget childWidget;
    if (hasUrl && effectiveUrl != null) {
      childWidget = ClipRRect(
        borderRadius: effectiveRadius,
        child: Image.network(
          effectiveUrl,
          height: height,
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) {
            return fallbackWidget ?? const AppLogo(height: 28);
          },
        ),
      );
    } else if (fallbackWidget != null) {
      childWidget = fallbackWidget!;
    } else {
      childWidget = const AppLogo(height: 28);
    }

    return Tooltip(
      message: '$title - Büyütmek için dokunun',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExpandedLogo(context),
          borderRadius: effectiveRadius,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Hero(
              tag: 'agency_logo_${logoUrl ?? title}',
              child: childWidget,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgencyLogoViewerDialog extends StatelessWidget {
  final String? logoUrl;
  final String title;
  final Widget? fallbackWidget;

  const _AgencyLogoViewerDialog({
    required this.logoUrl,
    required this.title,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = logoUrl != null && logoUrl!.trim().isNotEmpty;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Acente Logosu',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: Hero(
                          tag: 'agency_logo_${logoUrl ?? title}',
                          child: hasUrl
                              ? Image.network(
                                  logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) =>
                                      fallbackWidget ?? const AppLogo(height: 64),
                                )
                              : (fallbackWidget ?? const AppLogo(height: 64)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Yakınlaştırmak için çift dokunun veya çimdikleyin',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
