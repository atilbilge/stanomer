import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';

/// Floating contact widget (WhatsApp & Viber) for Stanomer web visitors.
class FloatingContactWidget extends StatefulWidget {
  final String phoneNumber;
  final String rawNumber;

  const FloatingContactWidget({
    super.key,
    this.phoneNumber = '+381 61 6036556',
    this.rawNumber = '381616036556',
  });

  @override
  State<FloatingContactWidget> createState() => _FloatingContactWidgetState();
}

class _FloatingContactWidgetState extends State<FloatingContactWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/${widget.rawNumber}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    _close();
  }

  Future<void> _launchViber() async {
    final viberAppUri = Uri.parse('viber://chat?number=%2B${widget.rawNumber}');
    final viberWebFallback = Uri.parse('https://viber.click/${widget.rawNumber}');

    try {
      final launched = await launchUrl(viberAppUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(viberWebFallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(viberWebFallback, mode: LaunchMode.externalApplication);
    }
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expanded Menu
            SizeTransition(
              sizeFactor: _expandAnimation,
              alignment: Alignment.bottomRight,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: StanomerColors.successPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Hızlı İletişim / Kontakt',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // WhatsApp Item
                      _ContactOptionCard(
                        title: 'WhatsApp',
                        subtitle: widget.phoneNumber,
                        brandColor: const Color(0xFF25D366),
                        icon: LucideIcons.messageCircle,
                        onTap: _launchWhatsApp,
                      ),
                      const SizedBox(height: 8),

                      // Viber Item
                      _ContactOptionCard(
                        title: 'Viber',
                        subtitle: widget.phoneNumber,
                        brandColor: const Color(0xFF7360F2),
                        icon: LucideIcons.phoneCall,
                        onTap: _launchViber,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Trigger Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isOpen ? const Color(0xFF1E293B) : StanomerColors.brandPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isOpen
                                ? const Color(0xFF1E293B)
                                : StanomerColors.brandPrimary)
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: Icon(
                          _isOpen ? LucideIcons.x : LucideIcons.messageCircleMore,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      if (!_isOpen)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color brandColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ContactOptionCard({
    required this.title,
    required this.subtitle,
    required this.brandColor,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ContactOptionCard> createState() => _ContactOptionCardState();
}

class _ContactOptionCardState extends State<_ContactOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.brandColor.withValues(alpha: 0.08)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.brandColor.withValues(alpha: 0.35)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.brandColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.arrowUpRight,
                size: 16,
                color: _isHovered ? widget.brandColor : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
