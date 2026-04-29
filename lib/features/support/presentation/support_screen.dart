import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/support_service.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Support';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email from auth state if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user?.email != null) {
        _emailController.text = user!.email!;
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(supportServiceProvider).sendTicket(
      subject: _subjectController.text,
      email: _emailController.text,
      category: _selectedCategory,
      message: _messageController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.messageSent),
            backgroundColor: StanomerColors.successPrimary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSendingMessage),
            backgroundColor: StanomerColors.alertPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.support_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.support_desc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StanomerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: loc.subject,
                  prefixIcon: const Icon(LucideIcons.type, size: 20),
                ),
                validator: (value) => (value == null || value.isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.email,
                  prefixIcon: const Icon(LucideIcons.mail, size: 20),
                ),
                validator: (value) => (value == null || !value.contains('@')) ? loc.invalidEmail : null,
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: loc.category,
                  prefixIcon: const Icon(LucideIcons.tag, size: 20),
                ),
                items: [
                  DropdownMenuItem(value: 'Support', child: Text(loc.support)),
                  DropdownMenuItem(value: 'Bug', child: Text(loc.bug)),
                  DropdownMenuItem(value: 'Other', child: Text(loc.other)),
                ],
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: loc.message,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc.send),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
