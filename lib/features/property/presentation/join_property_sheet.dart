import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/invite_utils.dart';
import '../data/property_repository.dart';

class JoinPropertySheet extends ConsumerStatefulWidget {
  const JoinPropertySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const JoinPropertySheet(),
    );
  }

  @override
  ConsumerState<JoinPropertySheet> createState() => _JoinPropertySheetState();
}

class _JoinPropertySheetState extends ConsumerState<JoinPropertySheet> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _errorMessage;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _tokenController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _submitToken([String? rawValue]) async {
    final raw = rawValue ?? _tokenController.text;
    final token = extractToken(raw);

    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir davet bağlantısı veya davet kodu girin.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    if (token.startsWith('landlord_')) {
      final repo = ref.read(propertyRepositoryProvider);
      final success = await repo.claimLandlordOwnership(token: token);
      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          ref.invalidate(propertiesFutureProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tebrikler! Mülk ev sahibi sahipliği başarıyla hesabınıza devredildi.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sahiplik daveti geçersiz, süresi dolmuş veya zaten kabul edilmiş.'),
              backgroundColor: StanomerColors.alertPrimary,
            ),
          );
        }
      }
    } else {
      Navigator.of(context).pop();
      context.push('/invite?token=$token');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _tokenController.text = data.text!;
        _errorMessage = null;
      });
    }
  }

  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _scannerController = MobileScannerController();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StanomerColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.qrCode,
                  color: StanomerColors.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Eve Dahil Ol',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: StanomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'QR kodu tarayın veya ev sahibinizin gönderdiği davet bağlantısını/kodunu girin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: StanomerColors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scanning mode or input form
          if (_isScanning) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 260,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? rawValue = barcode.rawValue;
                      if (rawValue != null && rawValue.isNotEmpty) {
                        _scannerController?.stop();
                        _submitToken(rawValue);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _toggleScanner,
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text('Kamerayı Kapat'),
            ),
          ] else ...[
            // QR Scan Toggle Button
            InkWell(
              onTap: _toggleScanner,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StanomerColors.brandPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: StanomerColors.brandPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.camera,
                      color: StanomerColors.brandPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'QR Kod Tara',
                      style: TextStyle(
                        color: StanomerColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VEYA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: StanomerColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // URL or Token TextField
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Davet Bağlantısı veya Token Kodu',
                hintText: 'https://.../invite?token=... veya kod',
                prefixIcon: const Icon(LucideIcons.link, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.clipboard, size: 18),
                  tooltip: 'Yapıştır',
                  onPressed: _pasteFromClipboard,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (val) => _submitToken(val),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: StanomerColors.alertPrimary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _submitToken(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Katıl ve İncele',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
