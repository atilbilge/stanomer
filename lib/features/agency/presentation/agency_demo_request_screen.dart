import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../data/agency_demo_service.dart';

class AgencyDemoRequestScreen extends ConsumerStatefulWidget {
  const AgencyDemoRequestScreen({super.key});

  @override
  ConsumerState<AgencyDemoRequestScreen> createState() => _AgencyDemoRequestScreenState();
}

class _AgencyDemoRequestScreenState extends ConsumerState<AgencyDemoRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestsController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _agencyNameController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(agencyDemoServiceProvider).submitDemoRequest(
      agencyName: _agencyNameController.text,
      email: _emailController.text,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      specialRequests: _requestsController.text.isNotEmpty ? _requestsController.text : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _isSubmitted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo talebi gönderilirken bir hata oluştu. Lütfen tekrar deneyiniz.'),
            backgroundColor: StanomerColors.alertPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emlak Ofisi Demo Talebi'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _isSubmitted
                ? _buildSuccessCard(context, isDark)
                : _buildFormCard(context, loc, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.building2,
                    color: StanomerColors.brandPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emlak Ofisi Demosu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : StanomerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Özel Portföy Yönetim Ekranı',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StanomerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: StanomerColors.brandPrimary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 20, color: StanomerColors.brandPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emlak ofisiniz için özel demo hesabı tanımlanacak ve giriş bilgileriniz e-posta adresinize gönderilecektir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Agency Name
            Text(
              'Emlak Ofisinin Adı *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _agencyNameController,
              decoration: const InputDecoration(
                hintText: 'Örn: Belgrad Gayrimenkul A.Ş.',
                prefixIcon: Icon(LucideIcons.building, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Lütfen emlak ofisinizin adını giriniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email Address
            Text(
              'E-posta Adresi *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu e-posta adresi ile demoya giriş için kullanıcı oluşturulacaktır.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StanomerColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'ofis@emlakofisi.com',
                prefixIcon: Icon(LucideIcons.mail, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty || !val.contains('@')) {
                  return 'Lütfen geçerli bir e-posta adresi giriniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Website URL
            Text(
              'Web Sitesi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://www.emlakofisiniz.com',
                prefixIcon: Icon(LucideIcons.globe, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Phone Number
            Text(
              'İletişim Numarası',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+381 60 123 4567',
                prefixIcon: Icon(LucideIcons.phone, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Special Requests & Notes
            Text(
              'Özelleşmiş Talepler & Notlar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _requestsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Portföy büyüklüğünüz, ihtiyaç duyduğunuz özel entegrasyonlar veya sorularınızı buraya yazabilirsiniz...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(LucideIcons.send, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Demo Talebini Gönder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StanomerColors.successPrimary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40.0),
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
          const SizedBox(height: 24),
          Text(
            'Demo Talebiniz Alındı!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : StanomerColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${_emailController.text} e-posta adresiniz için emlak ofisi demo hesabı hazırlanıyor. Giriş şifreniz ve kurulum detayları en kısa sürede e-posta adresinize iletilecektir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StanomerColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: StanomerColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ),
        ],
      ),
    );
  }
}
