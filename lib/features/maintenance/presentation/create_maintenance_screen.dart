import 'dart:typed_data';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';

class CreateMaintenanceRequestScreen extends ConsumerStatefulWidget {
  final Property property;

  const CreateMaintenanceRequestScreen({super.key, required this.property});

  @override
  ConsumerState<CreateMaintenanceRequestScreen> createState() => _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState extends ConsumerState<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  MaintenanceCategory _selectedCategory = MaintenanceCategory.other;
  MaintenancePriority _selectedPriority = MaintenancePriority.normal;
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true, // Necessary for web and easier handling
    );

    if (result != null) {
      setState(() {
        _selectedFiles = [..._selectedFiles, ...result.files];
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final activeContract = await ref.read(activeContractProvider(widget.property.id).future);
      
      // 1. Upload photos first
      final List<String> uploadedUrls = [];
      final tempRequestId = DateTime.now().millisecondsSinceEpoch.toString();

      for (var file in _selectedFiles) {
        List<int>? fileBytes = file.bytes?.toList();
        if (fileBytes == null && file.path != null) {
          fileBytes = await io.File(file.path!).readAsBytes();
        }

        if (fileBytes != null) {
          final url = await ref.read(maintenanceRepositoryProvider).uploadMaintenancePhoto(
            requestId: tempRequestId,
            fileName: file.name,
            bytes: Uint8List.fromList(fileBytes),
          );
          uploadedUrls.add(url);
        }
      }

      // 2. Create the request with the photo URLs
      await ref.read(maintenanceRepositoryProvider).createRequest(
        propertyId: widget.property.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        description: _descriptionController.text.trim(),
        contractId: activeContract?.id,
        photosUrls: uploadedUrls,
      );

      // Invalidate the provider so the list refreshes immediately
      ref.invalidate(maintenanceRequestsProvider(widget.property.id));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.maintenanceRequestSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportIssue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.issueTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: loc.issueTitle,
                ),
                validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.issueCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaintenanceCategory>(
                          value: _selectedCategory,
                          items: MaintenanceCategory.values.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(_getCategoryLabel(cat, loc)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.issuePriority, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaintenancePriority>(
                          value: _selectedPriority,
                          items: MaintenancePriority.values.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_getPriorityLabel(p, loc)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedPriority = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(loc.issueDescription, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: loc.issueDescription,
                ),
              ),
              const SizedBox(height: 20),

              _buildPhotoSection(loc),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.getRoleColor(ref.watch(currentUserProvider)?.userMetadata?['role']),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.send),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.photos, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(LucideIcons.camera, size: 16),
              label: Text(loc.add),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StanomerColors.borderDefault),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: file.bytes != null 
                          ? Image.memory(file.bytes!, fit: BoxFit.cover)
                          : const Center(child: Icon(LucideIcons.image)),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return loc.categoryPlumbing;
      case MaintenanceCategory.electrical: return loc.categoryElectrical;
      case MaintenanceCategory.heating: return loc.categoryHeating;
      case MaintenanceCategory.internet: return loc.categoryInternet;
      case MaintenanceCategory.other: return loc.categoryOther;
    }
  }

  String _getPriorityLabel(MaintenancePriority p, AppLocalizations loc) {
    switch (p) {
      case MaintenancePriority.normal: return loc.priorityNormal;
      case MaintenancePriority.urgent: return loc.priorityUrgent;
    }
  }
}
