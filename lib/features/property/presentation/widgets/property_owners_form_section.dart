import 'dart:typed_data';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTr = loc.localeName == 'tr';
    final isRu = loc.localeName == 'ru';
    final isSr = loc.localeName.startsWith('sr');

    final sectionTitle = isTr
        ? 'Mülk Sahibi / Malik Bilgileri'
        : (isRu
            ? 'Информация о собственниках'
            : (isSr
                ? 'Podaci o vlasnicima nekretnine'
                : 'Property Owner Information'));

    final sectionSubtitle = isTr
        ? 'Birden fazla hisseli malik ekleyebilir, şirket veya bireysel olarak kimlik ve tapu/vekalet belgelerini yükleyebilirsiniz.'
        : (isRu
            ? 'Вы можете добавить нескольких собственников, юридические или физические лица, и загрузить подтверждающие документы.'
            : (isSr
                ? 'Možete dodati više suvlasnika, pravna ili fizička lica, kao i priložiti dokumenta o vlasništvu i ovlašćenja.'
                : 'Add multiple co-owners, individual or company entities, and upload ownership documents or POA.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.users, color: StanomerColors.brandPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sectionSubtitle,
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
          return _buildOwnerCard(index, _ownerForms[index], isTr, isRu, isSr, loc);
        }),

        const SizedBox(height: 8),
        // Add Owner Button
        OutlinedButton.icon(
          onPressed: _addOwner,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: Text(
            isTr
                ? '+ Ortak Malik Ekle'
                : (isRu
                    ? '+ Добавить совладельца'
                    : (isSr
                        ? '+ Dodaj suvlasnika'
                        : '+ Add Co-Owner')),
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
    bool isTr,
    bool isRu,
    bool isSr,
    AppLocalizations loc,
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
                            ? (isTr ? '1. Malik (Ana Malik)' : (isRu ? '1. Собственник (Основной)' : (isSr ? '1. Vlasnik (Glavni)' : '1. Owner (Primary)')))
                            : '${index + 1}. ${isTr ? "Ortak Malik" : (isRu ? "Совладелец" : (isSr ? "Suvlasnik" : "Co-Owner"))}',
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
                      labelText: isTr ? 'Hisse %' : (isRu ? 'Доля %' : (isSr ? 'Udeo %' : 'Share %')),
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
                    tooltip: isTr ? 'Maliki Sil' : 'Remove Owner',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Entity Type Toggle: Individual vs Company
            Text(
              isTr ? 'Malik Türü' : (isRu ? 'Тип собственника' : (isSr ? 'Vrsta vlasnika' : 'Owner Type')),
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
                      Text(isTr ? 'Gerçek Kişi (Bireysel)' : (isRu ? 'Физическое лицо' : (isSr ? 'Fizičko lice' : 'Individual'))),
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
                      Text(isTr ? 'Tüzel Kişi / Şirket' : (isRu ? 'Юридическое лицо / Компания' : (isSr ? 'Pravno lice / Kompanija' : 'Company / Legal Entity'))),
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
                        labelText: isTr ? 'Adı *' : (isRu ? 'Имя *' : (isSr ? 'Ime *' : 'First Name *')),
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
                        labelText: isTr ? 'Soyadı *' : (isRu ? 'Фамилия *' : (isSr ? 'Prezime *' : 'Last Name *')),
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
                        labelText: isTr ? 'Kimlik / Pasaport / JMBG No' : (isRu ? 'Номер паспорта / удостоверения' : (isSr ? 'Broj l.k. / Pasoša / JMBG' : 'ID / Passport / JMBG No')),
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
                        labelText: isTr ? 'Kimlik Detayı (Veren makam vb.)' : (isRu ? 'Орган выдачи документа' : (isSr ? 'Organ izdavanja' : 'ID Issuing Authority / Details')),
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
                  labelText: isTr ? 'Şirket Tam Yasal Unvanı *' : (isRu ? 'Полное юридическое наименование *' : (isSr ? 'Puni naziv pravnog lica *' : 'Full Legal Company Name *')),
                  prefixIcon: const Icon(LucideIcons.building, size: 18),
                ),
                validator: (val) => isCompany && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                onChanged: (_) => _notifyParent(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: form.registeredAddressController,
                decoration: InputDecoration(
                  labelText: isTr ? 'Resmi Sicil Adresi' : (isRu ? 'Юридический адрес' : (isSr ? 'Sedište / Adresa registracije' : 'Registered Office Address')),
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
                        labelText: isTr ? 'Vergi No (PIB) *' : (isRu ? 'ИНН / PIB *' : (isSr ? 'PIB *' : 'Tax ID (PIB) *')),
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
                        labelText: isTr ? 'Şirket Sicil No (Matični broj)' : (isRu ? 'ОГРН / Matični broj' : (isSr ? 'Matični broj' : 'Company Reg No (Matični broj)')),
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
                        labelText: isTr ? 'Yasal Temsilci Ad Soyad *' : (isRu ? 'ФИО представителя *' : (isSr ? 'Ime i prezime zastupnika *' : 'Legal Representative Full Name *')),
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
                        labelText: isTr ? 'Temsilci Kimlik / JMBG No' : (isRu ? 'Паспорт представителя' : (isSr ? 'Broj l.k./JMBG zastupnika' : 'Rep. ID / JMBG Number')),
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
                  labelText: isTr ? 'Temsilci Yetki Detayları (İmza sirküleri vb.)' : (isRu ? 'Детали полномочий представителя' : (isSr ? 'Detalji ovlašćenja zastupnika' : 'Representative Authority Details / Title')),
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
                      labelText: isTr ? 'İletişim Telefonu *' : (isRu ? 'Контактный телефон *' : (isSr ? 'Kontakt telefon *' : 'Contact Phone *')),
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
                      labelText: isTr ? 'İkinci İletişim (İsteğe bağlı)' : (isRu ? 'Доп. контакт (Опционально)' : (isSr ? 'Drugi kontakt (Opciono)' : 'Secondary Contact (Optional)')),
                      hintText: isTr ? 'Alternatif Tel / Not' : (isSr ? 'Alternativni tel.' : 'Alt. Phone / Note'),
                      prefixIcon: const Icon(LucideIcons.phoneCall, size: 18),
                    ),
                    onChanged: (_) => _notifyParent(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Email Address: REQUIRED for primary owner, OPTIONAL for co-owners!
            TextFormField(
              controller: form.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isPrimary
                    ? (isTr ? 'E-posta Adresi (Ana Malik İçin Zorunlu) *' : (isRu ? 'Email (Обязательно для основного) *' : (isSr ? 'Email adresa (Obavezno za glavnog) *' : 'Email Address (Required for Primary) *')))
                    : (isTr ? 'E-posta Adresi (İsteğe Bağlı)' : (isRu ? 'Email (Опционально)' : (isSr ? 'Email adresa (Opciono)' : 'Email Address (Optional)'))),
                hintText: 'ornek@email.com',
                helperText: isPrimary
                    ? null
                    : (isTr
                        ? 'E-posta girilirse malik bu adresle giriş yaptığında mülkü ev sahibi olarak görür.'
                        : (isRu
                            ? 'При указании email совладелец сможет видеть объект после входа в систему.'
                            : (isSr
                                ? 'Ukoliko unesete email, suvlasnik će videti nekretninu u svom nalogu.'
                                : 'If entered, the co-owner will see the property in their landlord dashboard upon login.'))),
                helperMaxLines: 2,
                prefixIcon: const Icon(LucideIcons.mail, size: 18),
              ),
              validator: (val) {
                if (isPrimary && (val == null || val.trim().isEmpty)) {
                  return loc.fieldRequired;
                }
                if (val != null && val.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                    return isTr ? 'Geçerli bir e-posta giriniz' : 'Please enter a valid email address';
                  }
                }
                return null;
              },
              onChanged: (_) => _notifyParent(),
            ),

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
                      isTr ? 'Destekleyici PDF Belgeleri' : (isRu ? 'Подтверждающие PDF документы' : (isSr ? 'Prateća PDF dokumenta' : 'Supporting PDF Documents')),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                // Document upload action menu
                PopupMenuButton<OwnerDocumentType>(
                  tooltip: isTr ? 'Belge Yükle' : 'Upload Document',
                  onSelected: (docType) => _pickAndUploadDocument(form, docType),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: OwnerDocumentType.idDocument,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.idCard, size: 16),
                          const SizedBox(width: 8),
                          Text(isTr ? 'Kimlik Fotokopisi (PDF)' : (isSr ? 'Kopija l.k. / Pasoša' : 'ID Document Copy')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.ownershipProof,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileCheck, size: 16),
                          const SizedBox(width: 8),
                          Text(isTr ? 'Tapu / Mülkiyet Belgesi (PDF)' : (isSr ? 'Vlasnički list / Dokaz' : 'Proof of Ownership / Title Deed')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.powerOfAttorney,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.award, size: 16),
                          const SizedBox(width: 8),
                          Text(isTr ? 'Vekaletname / Yetki Belgesi (PDF)' : (isSr ? 'Ovlašćenje / Punomoćje' : 'Power of Attorney (POA)')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: OwnerDocumentType.other,
                      child: Row(
                        children: [
                          const Icon(LucideIcons.filePlus, size: 16),
                          const SizedBox(width: 8),
                          Text(isTr ? 'Diğer İlgili Belge (PDF)' : (isSr ? 'Ostala dokumentacija' : 'Other Document')),
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
                          isTr ? '+ PDF Belge Ekle' : (isSr ? '+ Priloži PDF' : '+ Add PDF Document'),
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
                  isTr
                      ? 'Henüz belge yüklenmedi (Kimlik, Tapu veya Vekaletname ekleyebilirsiniz).'
                      : (isRu
                          ? 'Документы еще не загружены.'
                          : (isSr
                              ? 'Nema priloženih dokumenata (Možete dodati l.k., vlasnički list ili ovlašćenje).'
                              : 'No documents attached yet (You can attach ID, Title deed or POA).')),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: form.documents.map((doc) {
                  final label = _getDocumentTypeLabel(doc.type, isTr, isRu, isSr);
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
                          tooltip: isTr ? 'Sil' : 'Remove',
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

  String _getDocumentTypeLabel(OwnerDocumentType type, bool isTr, bool isRu, bool isSr) {
    switch (type) {
      case OwnerDocumentType.idDocument:
        return isTr ? 'Kimlik' : (isSr ? 'L.K.' : 'ID');
      case OwnerDocumentType.ownershipProof:
        return isTr ? 'Tapu' : (isSr ? 'Vlasnički list' : 'Title Deed');
      case OwnerDocumentType.powerOfAttorney:
        return isTr ? 'Vekaletname' : (isSr ? 'Ovlašćenje' : 'POA');
      case OwnerDocumentType.other:
        return isTr ? 'Belge' : (isSr ? 'Dokument' : 'Doc');
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
