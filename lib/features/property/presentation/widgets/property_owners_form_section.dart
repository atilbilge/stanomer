import 'dart:typed_data';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../agency/domain/agency_contact.dart';
import '../../data/property_repository.dart';
import '../../domain/property_owner.dart';

class PropertyOwnersFormSection extends ConsumerStatefulWidget {
  final List<PropertyOwner> initialOwners;
  final ValueChanged<List<PropertyOwner>> onOwnersChanged;
  final String tempPropertyId;

  const PropertyOwnersFormSection({
    super.key,
    required this.initialOwners,
    required this.onOwnersChanged,
    required this.tempPropertyId,
  });

  @override
  ConsumerState<PropertyOwnersFormSection> createState() => PropertyOwnersFormSectionState();
}

class PropertyOwnersFormSectionState extends ConsumerState<PropertyOwnersFormSection> {
  late List<_OwnerFormState> _ownerForms;

  @override
  void initState() {
    super.initState();
    if (widget.initialOwners.isNotEmpty) {
      _ownerForms = widget.initialOwners.map((o) => _OwnerFormState.fromModel(o)).toList();
    } else {
      _ownerForms = [
        _OwnerFormState(isPrimary: true, ownershipPercentage: 100.0),
      ];
    }
  }

  @override
  void dispose() {
    for (final f in _ownerForms) {
      f.dispose();
    }
    super.dispose();
  }

  void _notifyParent() {
    final models = _ownerForms.map((f) => f.toModel()).toList();
    widget.onOwnersChanged(models);
  }

  void _addOwner() {
    setState(() {
      _ownerForms.add(_OwnerFormState(isPrimary: false, ownershipPercentage: 50.0));
      if (_ownerForms.length == 2 && _ownerForms[0].ownershipPercentage == 100.0) {
        _ownerForms[0].ownershipPercentage = 50.0;
        _ownerForms[0].percentController.text = '50';
      }
    });
    _notifyParent();
  }

  void _removeOwner(int index) {
    if (_ownerForms.length <= 1) return;
    setState(() {
      _ownerForms[index].dispose();
      _ownerForms.removeAt(index);
      if (!_ownerForms.any((f) => f.isPrimary)) {
        _ownerForms[0].isPrimary = true;
      }
    });
    _notifyParent();
  }

  bool validate() {
    bool isValid = true;
    for (final f in _ownerForms) {
      if (!f.formKey.currentState!.validate()) {
        isValid = false;
      }
    }
    return isValid;
  }

  List<PropertyOwner> getOwners() {
    return _ownerForms.map((f) => f.toModel()).toList();
  }

  void setPrimaryOwnerFromContact({
    required String name,
    String? email,
    String? phone,
    String? idNumber,
    bool isCompany = false,
    String? companyName,
    String? pib,
    String? representativeName,
  }) {
    if (_ownerForms.isEmpty) {
      _ownerForms = [_OwnerFormState(isPrimary: true, ownershipPercentage: 100.0)];
    }
    final primary = _ownerForms.firstWhere((f) => f.isPrimary, orElse: () => _ownerForms.first);
    setState(() {
      primary.ownerType = isCompany ? PropertyOwnerType.company : PropertyOwnerType.individual;
      if (isCompany) {
        primary.companyNameController.text = companyName ?? name;
        if (pib != null) primary.pibController.text = pib;
        if (representativeName != null) primary.representativeNameController.text = representativeName;
      } else {
        final parts = name.trim().split(' ');
        primary.firstNameController.text = parts.isNotEmpty ? parts.first : name;
        primary.lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      if (email != null) primary.emailController.text = email;
      if (phone != null) primary.phoneController.text = phone;
      if (idNumber != null) primary.idNumberController.text = idNumber;
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(agencyContactsProvider);
    final contacts = contactsAsync.valueOrNull ?? <AgencyContact>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.users, size: 20, color: StanomerColors.brandPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.propertyOwnerInfoTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.propertyOwnerInfoSubtitle,
                    style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Owner Cards
        ...List.generate(_ownerForms.length, (index) {
          return _buildOwnerCard(index, _ownerForms[index], loc, contacts);
        }),

        const SizedBox(height: 8),
        // Add Owner Button
        OutlinedButton.icon(
          onPressed: _addOwner,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: Text(
            loc.addCoOwner,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: StanomerColors.brandPrimary,
            side: const BorderSide(color: StanomerColors.brandPrimary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(
    int index,
    _OwnerFormState form,
    AppLocalizations loc,
    List<AgencyContact> contacts,
  ) {
    final isPrimary = form.isPrimary;
    final isCompany = form.ownerType == PropertyOwnerType.company;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? StanomerColors.brandPrimary.withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
          width: isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: form.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Malik Title, Primary Badge, Share %, Delete Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrimary ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isPrimary ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPrimary ? LucideIcons.crown : LucideIcons.user,
                        size: 13,
                        color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPrimary
                            ? loc.primaryOwnerLabel
                            : loc.coOwnerIndexedLabel(index + 1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPrimary ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Share percentage
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: form.percentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.sharePercentage,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      form.ownershipPercentage = double.tryParse(val) ?? 100.0;
                      _notifyParent();
                    },
                  ),
                ),
                if (!isPrimary) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeOwner(index),
                    tooltip: loc.removeOwner,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Entity Type Toggle: Individual vs Company
            Text(
              loc.ownerType,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.user, size: 14),
                      const SizedBox(width: 6),
                      Text(loc.ownerIndividual),
                    ],
                  ),
                  selected: !isCompany,
                  onSelected: (val) {
                    if (val) {
                      setState(() => form.ownerType = PropertyOwnerType.individual);
                      _notifyParent();
                    }
                  },
                ),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.building2, size: 14),
                      const SizedBox(width: 6),
                      Text(loc.ownerCompany),
                    ],
                  ),
                  selected: isCompany,
                  onSelected: (val) {
                    if (val) {
                      setState(() => form.ownerType = PropertyOwnerType.company);
                      _notifyParent();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Form Fields based on Type
            if (!isCompany) ...[
              // Individual fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.firstNameController,
                      decoration: InputDecoration(
                        labelText: loc.firstNameRequired,
                        prefixIcon: const Icon(LucideIcons.user, size: 18),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? loc.fieldRequired : null,
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: form.lastNameController,
                      decoration: InputDecoration(
                        labelText: loc.lastNameRequired,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? loc.fieldRequired : null,
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.idNumberController,
                      decoration: InputDecoration(
                        labelText: loc.idOrPassportOrJmbg,
                        prefixIcon: const Icon(LucideIcons.idCard, size: 18),
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: form.idDetailsController,
                      decoration: InputDecoration(
                        labelText: loc.idIssuingAuthority,
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Company fields
              TextFormField(
                controller: form.companyNameController,
                decoration: InputDecoration(
                  labelText: loc.companyLegalNameRequired,
                  prefixIcon: const Icon(LucideIcons.building, size: 18),
                ),
                validator: (val) => isCompany && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                onChanged: (_) => _notifyParent(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: form.registeredAddressController,
                decoration: InputDecoration(
                  labelText: loc.registeredOfficeAddress,
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                ),
                onChanged: (_) => _notifyParent(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.pibController,
                      decoration: InputDecoration(
                        labelText: loc.taxIdPibRequired,
                        prefixIcon: const Icon(LucideIcons.hash, size: 18),
                      ),
                      validator: (val) => isCompany && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: form.regNumberController,
                      decoration: InputDecoration(
                        labelText: loc.companyRegNo,
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.representativeNameController,
                      decoration: InputDecoration(
                        labelText: loc.legalRepFullNameRequired,
                        prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                      ),
                      validator: (val) => isCompany && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: form.representativeIdNumberController,
                      decoration: InputDecoration(
                        labelText: loc.repIdJmbg,
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: form.representativeIdDetailsController,
                decoration: InputDecoration(
                  labelText: loc.repAuthorityDetails,
                ),
                onChanged: (_) => _notifyParent(),
              ),
            ],

            const SizedBox(height: 12),
            // Contact Phone & Secondary Contact Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: form.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: loc.contactPhoneRequired,
                      prefixIcon: const Icon(LucideIcons.phone, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? loc.fieldRequired : null,
                    onChanged: (_) => _notifyParent(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: form.secondaryContactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: loc.secondaryContactOptional,
                      hintText: loc.altPhoneOrNote,
                      prefixIcon: const Icon(LucideIcons.phoneCall, size: 18),
                    ),
                    onChanged: (_) => _notifyParent(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Email Address: REQUIRED for primary owner, OPTIONAL for co-owners!
            // Enhanced with inline autocomplete from agency contacts (landlords and tenants)
            RawAutocomplete<AgencyContact>(
              textEditingController: form.emailController,
              focusNode: form.emailFocusNode,
              displayStringForOption: (contact) => contact.email ?? contact.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (contacts.isEmpty) {
                  return const Iterable<AgencyContact>.empty();
                }
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return const Iterable<AgencyContact>.empty();
                }
                return contacts.where((c) {
                  final emailMatch = c.email?.toLowerCase().contains(query) ?? false;
                  final nameMatch = c.name.toLowerCase().contains(query);
                  final phoneMatch = c.phone?.toLowerCase().contains(query) ?? false;
                  return emailMatch || nameMatch || phoneMatch;
                });
              },
              onSelected: (contact) {
                setState(() {
                  form.selectedContact = contact;
                  form.ownerType = contact.isCompany ? PropertyOwnerType.company : PropertyOwnerType.individual;
                  if (contact.isCompany) {
                    form.companyNameController.text = contact.companyName ?? contact.name;
                    if (contact.pib != null) form.pibController.text = contact.pib!;
                    if (contact.representativeName != null) form.representativeNameController.text = contact.representativeName!;
                  } else {
                    final parts = contact.name.trim().split(' ');
                    form.firstNameController.text = parts.isNotEmpty ? parts.first : contact.name;
                    form.lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                  }
                  if (contact.email != null) form.emailController.text = contact.email!;
                  if (contact.phone != null) form.phoneController.text = contact.phone!;
                  if (contact.idNumber != null) form.idNumberController.text = contact.idNumber!;
                });
                _notifyParent();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isPrimary
                        ? loc.emailAddressRequiredForPrimary
                        : loc.emailAddressOptional,
                    hintText: 'ornek@email.com',
                    helperText: isPrimary
                        ? null
                        : loc.coOwnerEmailHelper,
                    helperMaxLines: 2,
                    prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    suffixIcon: form.selectedContact != null
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            tooltip: loc.clearSelectionTooltip,
                            onPressed: () {
                              setState(() {
                                form.selectedContact = null;
                                form.emailController.clear();
                              });
                              _notifyParent();
                            },
                          )
                        : null,
                  ),
                  validator: (val) {
                    if (isPrimary && (val == null || val.trim().isEmpty)) {
                      return loc.fieldRequired;
                    }
                    if (val != null && val.trim().isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return loc.invalidEmail;
                      }
                    }
                    return null;
                  },
                  onChanged: (val) {
                    if (form.selectedContact != null && form.selectedContact!.email != val.trim()) {
                      setState(() {
                        form.selectedContact = null;
                      });
                    }
                    _notifyParent();
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250, maxWidth: 360),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (BuildContext context, int index) {
                          final contact = options.elementAt(index);
                          final isLandlord = contact.isLandlord;

                          return InkWell(
                            onTap: () => onSelected(contact),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isLandlord
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFECFDF5),
                                    child: Icon(
                                      isLandlord ? LucideIcons.userCheck : LucideIcons.keyRound,
                                      size: 14,
                                      color: isLandlord
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                contact.name,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: StanomerColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isLandlord
                                                    ? const Color(0xFFDBEAFE)
                                                    : const Color(0xFFD1FAE5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isLandlord
                                                    ? loc.landlord
                                                    : loc.tenant,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLandlord
                                                      ? const Color(0xFF1D4ED8)
                                                      : const Color(0xFF047857),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (contact.email != null)
                                          Text(
                                            contact.email!,
                                            style: const TextStyle(fontSize: 11, color: StanomerColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (contact.propertySummary != null)
                                          Text(
                                            contact.propertySummary!,
                                            style: const TextStyle(fontSize: 10, color: StanomerColors.textTertiary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            if (form.selectedContact?.isTenant == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.contactTenantAsLandlordInfo(form.selectedContact!.propertySummary ?? ''),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (form.selectedContact?.isLandlord == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    loc.registeredLandlordDetailsAutofilled,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Supporting Documents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      loc.supportingPdfDocuments,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                // Document upload action menu
                PopupMenuButton<OwnerDocumentType>(
                  tooltip: loc.uploadDocumentTooltip,
                  onSelected: (docType) => _pickAndUploadDocument(form, docType),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: OwnerDocumentType.idDocument,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.idCard, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.docTypePassportCopy),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.ownershipProof,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileCheck, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.docTypeProofOfOwnership),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.powerOfAttorney,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.award, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.docTypePowerOfAttorney),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.other,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.filePlus, size: 16),
                          const SizedBox(width: 8),
                          Text(loc.docTypeOtherDocument),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: StanomerColors.brandPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.uploadCloud, size: 14, color: StanomerColors.brandPrimary),
                        const SizedBox(width: 6),
                        Text(
                          loc.addPdfDocument,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: StanomerColors.brandPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Render uploaded document list chips
            if (form.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  loc.noDocumentsAttachedYet,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: form.documents.map((doc) {
                  final label = _getDocumentTypeLabel(doc.type, loc);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            '$label: ${doc.name}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 14, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: loc.delete,
                          onPressed: () {
                            setState(() {
                              form.documents.remove(doc);
                            });
                            _notifyParent();
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _getDocumentTypeLabel(OwnerDocumentType type, AppLocalizations loc) {
    switch (type) {
      case OwnerDocumentType.idDocument:
        return loc.docTypeLabelId;
      case OwnerDocumentType.ownershipProof:
        return loc.docTypeLabelTitleDeed;
      case OwnerDocumentType.powerOfAttorney:
        return loc.docTypeLabelPoa;
      case OwnerDocumentType.other:
        return loc.docTypeLabelOther;
    }
  }

  Future<void> _pickAndUploadDocument(_OwnerFormState form, OwnerDocumentType docType) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'PDF', 'jpg', 'jpeg', 'png', 'PNG'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      List<int>? fileBytes = file.bytes?.toList();
      if (fileBytes == null && file.path != null) {
        fileBytes = await io.File(file.path!).readAsBytes();
      }

      if (fileBytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(loc.fileUnreadable)));
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.localeName == 'tr' ? 'Belge yükleniyor...' : 'Uploading document...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final url = await ref.read(propertyRepositoryProvider).uploadOwnerDocument(
            propertyId: widget.tempPropertyId,
            fileName: file.name,
            bytes: Uint8List.fromList(fileBytes),
          );

      setState(() {
        form.documents.add(
          PropertyOwnerDocument(
            type: docType,
            name: file.name,
            url: url,
            uploadedAt: DateTime.now(),
          ),
        );
      });
      _notifyParent();

      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.localeName == 'tr' ? 'Belge başarıyla yüklendi.' : 'Document successfully uploaded.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _OwnerFormState {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  PropertyOwnerType ownerType;
  bool isPrimary;
  double ownershipPercentage;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController secondaryContactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  AgencyContact? selectedContact;
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController idDetailsController = TextEditingController();

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController registeredAddressController = TextEditingController();
  final TextEditingController pibController = TextEditingController();
  final TextEditingController regNumberController = TextEditingController();
  final TextEditingController representativeNameController = TextEditingController();
  final TextEditingController representativeIdNumberController = TextEditingController();
  final TextEditingController representativeIdDetailsController = TextEditingController();
  final TextEditingController percentController = TextEditingController();

  List<PropertyOwnerDocument> documents = [];

  _OwnerFormState({
    this.ownerType = PropertyOwnerType.individual,
    this.isPrimary = false,
    this.ownershipPercentage = 100.0,
  }) {
    percentController.text = ownershipPercentage.toStringAsFixed(0);
  }

  factory _OwnerFormState.fromModel(PropertyOwner model) {
    final s = _OwnerFormState(
      ownerType: model.ownerType,
      isPrimary: model.isPrimary,
      ownershipPercentage: model.ownershipPercentage,
    );
    s.firstNameController.text = model.firstName ?? '';
    s.lastNameController.text = model.lastName ?? '';
    s.phoneController.text = model.phone ?? '';
    s.secondaryContactController.text = model.secondaryContact ?? '';
    s.emailController.text = model.email ?? '';
    s.idNumberController.text = model.idDocumentNumber ?? '';
    s.idDetailsController.text = model.idDetails ?? '';
    s.companyNameController.text = model.companyName ?? '';
    s.registeredAddressController.text = model.registeredAddress ?? '';
    s.pibController.text = model.pib ?? '';
    s.regNumberController.text = model.registrationNumber ?? '';
    s.representativeNameController.text = model.representativeName ?? '';
    s.representativeIdNumberController.text = model.representativeIdNumber ?? '';
    s.representativeIdDetailsController.text = model.representativeIdDetails ?? '';
    s.percentController.text = model.ownershipPercentage.toStringAsFixed(0);
    s.documents = List.from(model.documents);
    return s;
  }

  PropertyOwner toModel() {
    return PropertyOwner(
      ownerType: ownerType,
      isPrimary: isPrimary,
      ownershipPercentage: double.tryParse(percentController.text) ?? ownershipPercentage,
      firstName: firstNameController.text.trim().isEmpty ? null : firstNameController.text.trim(),
      lastName: lastNameController.text.trim().isEmpty ? null : lastNameController.text.trim(),
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      secondaryContact: secondaryContactController.text.trim().isEmpty ? null : secondaryContactController.text.trim(),
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      idDocumentNumber: idNumberController.text.trim().isEmpty ? null : idNumberController.text.trim(),
      idDetails: idDetailsController.text.trim().isEmpty ? null : idDetailsController.text.trim(),
      companyName: companyNameController.text.trim().isEmpty ? null : companyNameController.text.trim(),
      registeredAddress: registeredAddressController.text.trim().isEmpty ? null : registeredAddressController.text.trim(),
      pib: pibController.text.trim().isEmpty ? null : pibController.text.trim(),
      registrationNumber: regNumberController.text.trim().isEmpty ? null : regNumberController.text.trim(),
      representativeName: representativeNameController.text.trim().isEmpty ? null : representativeNameController.text.trim(),
      representativeIdNumber: representativeIdNumberController.text.trim().isEmpty ? null : representativeIdNumberController.text.trim(),
      representativeIdDetails: representativeIdDetailsController.text.trim().isEmpty ? null : representativeIdDetailsController.text.trim(),
      documents: List.from(documents),
    );
  }

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    secondaryContactController.dispose();
    emailController.dispose();
    emailFocusNode.dispose();
    idNumberController.dispose();
    idDetailsController.dispose();
    companyNameController.dispose();
    registeredAddressController.dispose();
    pibController.dispose();
    regNumberController.dispose();
    representativeNameController.dispose();
    representativeIdNumberController.dispose();
    representativeIdDetailsController.dispose();
    percentController.dispose();
  }
}
