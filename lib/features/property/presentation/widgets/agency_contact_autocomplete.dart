import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../agency/domain/agency_contact.dart';
import '../../data/property_repository.dart';

class AgencyContactAutocomplete extends ConsumerStatefulWidget {
  final ValueChanged<AgencyContact> onContactSelected;
  final VoidCallback? onCleared;

  const AgencyContactAutocomplete({
    super.key,
    required this.onContactSelected,
    this.onCleared,
  });

  @override
  ConsumerState<AgencyContactAutocomplete> createState() => _AgencyContactAutocompleteState();
}

class _AgencyContactAutocompleteState extends ConsumerState<AgencyContactAutocomplete> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  AgencyContact? _selectedContact;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectContact(AgencyContact contact) {
    setState(() {
      _selectedContact = contact;
      _searchController.text = contact.name;
    });
    _focusNode.unfocus();
    widget.onContactSelected(contact);
  }

  void _clearSelection() {
    setState(() {
      _selectedContact = null;
      _searchController.clear();
    });
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTr = loc.localeName == 'tr';
    final isRu = loc.localeName == 'ru';
    final isSr = loc.localeName.startsWith('sr');

    final contactsAsync = ref.watch(agencyContactsProvider);

    return contactsAsync.when(
      data: (contacts) {
        if (contacts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StanomerColors.bgPage,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StanomerColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.contact, size: 16, color: StanomerColors.brandPrimary),
                      const SizedBox(width: 8),
                      Text(
                        isTr
                            ? 'Kayıtlı Kişilerden Hızlı Doldur'
                            : (isRu
                                ? 'Быстрое заполнение из контактов'
                                : (isSr
                                    ? 'Brzo popunjavanje iz kontakata'
                                    : 'Quick Fill from Existing Contacts')),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: StanomerColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedContact != null)
                        GestureDetector(
                          onTap: _clearSelection,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.x, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                isTr ? 'Temizle' : (isRu ? 'Очистить' : (isSr ? 'Obriši' : 'Clear')),
                                style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RawAutocomplete<AgencyContact>(
                    textEditingController: _searchController,
                    focusNode: _focusNode,
                    displayStringForOption: (contact) => contact.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.trim().toLowerCase();
                      if (query.isEmpty) {
                        return contacts.take(6);
                      }
                      return contacts.where((c) {
                        final nameMatch = c.name.toLowerCase().contains(query);
                        final emailMatch = c.email?.toLowerCase().contains(query) ?? false;
                        final phoneMatch = c.phone?.toLowerCase().contains(query) ?? false;
                        return nameMatch || emailMatch || phoneMatch;
                      });
                    },
                    onSelected: _selectContact,
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: isTr
                              ? 'Ev sahibi veya kiracı ara (İsim, e-posta, tel)...'
                              : (isRu
                                  ? 'Поиск арендодателя или арендатора...'
                                  : (isSr
                                      ? 'Pretraži stanodavca ili stanara...'
                                      : 'Search landlord or tenant (Name, email, phone)...')),
                          hintStyle: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                          prefixIcon: const Icon(LucideIcons.search, size: 16, color: StanomerColors.textTertiary),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 14),
                                  onPressed: _clearSelection,
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: StanomerColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: StanomerColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: StanomerColors.brandPrimary),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
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
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
                                          radius: 15,
                                          backgroundColor: isLandlord
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFFECFDF5),
                                          child: Icon(
                                            isLandlord ? LucideIcons.userCheck : LucideIcons.keyRound,
                                            size: 15,
                                            color: isLandlord
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF059669),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
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
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: StanomerColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isLandlord
                                                          ? const Color(0xFFDBEAFE)
                                                          : const Color(0xFFD1FAE5),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      isLandlord
                                                          ? (isTr ? 'Ev Sahibi' : (isSr ? 'Stanodavac' : 'Landlord'))
                                                          : (isTr ? 'Kiracı' : (isSr ? 'Zakupac' : 'Tenant')),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isLandlord
                                                            ? const Color(0xFF1E40AF)
                                                            : const Color(0xFF065F46),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  if (contact.email != null && contact.email!.isNotEmpty)
                                                    Expanded(
                                                      child: Text(
                                                        contact.email!,
                                                        style: const TextStyle(fontSize: 11, color: StanomerColors.textSecondary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  if (contact.propertySummary != null) ...[
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '• ${contact.propertySummary}',
                                                      style: const TextStyle(fontSize: 10, color: StanomerColors.textTertiary),
                                                    ),
                                                  ],
                                                ],
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

                  // Callout for Tenant selected
                  if (_selectedContact != null && _selectedContact!.isTenant) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isTr
                                  ? 'Bu kişi şu anda portföyünüzde kiracı olarak kayıtlıdır. Bu yeni mülk için Ev Sahibi olarak atanacaktır. (Kullanıcı aynı hesapla her iki role de erişebilecektir).'
                                  : (isRu
                                      ? 'Этот пользователь в настоящее время зарегистрирован как арендатор. Для этого объекта он будет назначен арендодателем.'
                                      : (isSr
                                          ? 'Ova osoba je trenutno evidentirana kao zakupac. Za ovu nekretninu biće dodeljena kao stanodavac.'
                                          : 'This contact is currently registered as a tenant. They will be assigned as the Landlord for this new property.')),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
