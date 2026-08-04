import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../agency/presentation/agency_dashboard_screen.dart';
import '../../data/property_repository.dart';

class OwnershipShareSheet extends ConsumerStatefulWidget {
  final String propertyName;
  final String landlordName;
  final String landlordEmail;
  final String token;

  const OwnershipShareSheet({
    super.key,
    required this.propertyName,
    required this.landlordName,
    required this.landlordEmail,
    required this.token,
  });

  static Future<void> show(
    BuildContext context, {
    required String propertyName,
    required String landlordName,
    required String landlordEmail,
    required String token,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnershipShareSheet(
        propertyName: propertyName,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        token: token,
      ),
    );
  }

  @override
  ConsumerState<OwnershipShareSheet> createState() => _OwnershipShareSheetState();
}

class _OwnershipShareSheetState extends ConsumerState<OwnershipShareSheet> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    _listenForAcceptance();
  }

  void _listenForAcceptance() {
    try {
      _subscription = Supabase.instance.client
          .from('invitations')
          .stream(primaryKey: ['id'])
          .eq('token', widget.token)
          .listen((data) {
            if (data.isNotEmpty) {
              final status = data.first['status'] as String?;
              if (status == 'accepted' && mounted && !_isAccepted) {
                setState(() {
                  _isAccepted = true;
                });
                ref.invalidate(agencyPropertiesProvider);
                ref.invalidate(propertiesFutureProvider);
                Future.delayed(const Duration(milliseconds: 2000), () {
                  if (mounted) Navigator.of(context).pop();
                });
              }
            }
          });
    } catch (e) {
      debugPrint('Error listening to invitation realtime stream: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String get inviteUrl => 'stanomer://invite/landlord?token=${widget.token}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_isAccepted) {
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: StanomerColors.successPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: StanomerColors.successPrimary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.landlordAcceptedInviteTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: StanomerColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.landlordOwnershipTransferredDesc(widget.propertyName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: StanomerColors.textTertiary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.successPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(loc.ok, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.keyRound, color: StanomerColors.brandPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.landlordOwnershipInviteTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.propertyName,
                          style: const TextStyle(fontSize: 13, color: StanomerColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: StanomerColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.userCheck, color: StanomerColors.brandPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.landlordName.isNotEmpty ? widget.landlordName : loc.landlordOwnershipInviteTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (widget.landlordEmail.isNotEmpty)
                            Text(
                              widget.landlordEmail,
                              style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        loc.invitePending,
                        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: StanomerColors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: inviteUrl,
                      version: QrVersions.auto,
                      size: 180,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: StanomerColors.brandPrimary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: StanomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.landlordShareQrInstruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.ownershipLinkCopied)),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 18),
                      label: Text(loc.copy),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          loc.landlordShareMessage(
                            widget.landlordName.isNotEmpty ? widget.landlordName : loc.roleLandlord,
                            widget.propertyName,
                            inviteUrl,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.share2, size: 18),
                      label: Text(loc.share),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StanomerColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
