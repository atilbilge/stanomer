import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/tenant_secondary_contact.dart';

class TenantSecondaryContactsSection extends StatefulWidget {
  final List<TenantSecondaryContact> initialContacts;
  final ValueChanged<List<TenantSecondaryContact>> onContactsChanged;

  const TenantSecondaryContactsSection({
    super.key,
    this.initialContacts = const [],
    required this.onContactsChanged,
  });

  @override
  State<TenantSecondaryContactsSection> createState() => TenantSecondaryContactsSectionState();
}

class _ContactEntry {
  final TextEditingController nameController;
  final TextEditingController relationController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  _ContactEntry({
    required this.nameController,
    required this.relationController,
    required this.phoneController,
    required this.emailController,
  });

  void dispose() {
    nameController.dispose();
    relationController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }
}

class TenantSecondaryContactsSectionState extends State<TenantSecondaryContactsSection> {
  final List<_ContactEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    for (final contact in widget.initialContacts) {
      _addEntry(contact);
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addEntry([TenantSecondaryContact? contact]) {
    final entry = _ContactEntry(
      nameController: TextEditingController(text: contact?.fullName ?? ''),
      relationController: TextEditingController(text: contact?.relationship ?? ''),
      phoneController: TextEditingController(text: contact?.phone ?? ''),
      emailController: TextEditingController(text: contact?.email ?? ''),
    );

    entry.nameController.addListener(_notify);
    entry.relationController.addListener(_notify);
    entry.phoneController.addListener(_notify);
    entry.emailController.addListener(_notify);

    setState(() {
      _entries.add(entry);
    });
    _notify();
  }

  void _removeEntry(int index) {
    if (index >= 0 && index < _entries.length) {
      final removed = _entries.removeAt(index);
      removed.dispose();
      setState(() {});
      _notify();
    }
  }

  void _notify() {
    widget.onContactsChanged(getContacts());
  }

  List<TenantSecondaryContact> getContacts() {
    return _entries
        .map((e) => TenantSecondaryContact(
              fullName: e.nameController.text.trim(),
              relationship: e.relationController.text.trim(),
              phone: e.phoneController.text.trim().isEmpty ? null : e.phoneController.text.trim(),
              email: e.emailController.text.trim().isEmpty ? null : e.emailController.text.trim(),
            ))
        .where((c) => c.fullName.isNotEmpty || c.relationship.isNotEmpty || (c.phone != null && c.phone!.isNotEmpty) || (c.email != null && c.email!.isNotEmpty))
        .toList();
  }

  bool validate() {
    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final hasAny = e.nameController.text.trim().isNotEmpty ||
          e.relationController.text.trim().isNotEmpty ||
          e.phoneController.text.trim().isNotEmpty ||
          e.emailController.text.trim().isNotEmpty;
      if (hasAny && e.nameController.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final defaultRoles = [
      loc.rolePersonalAssistant,
      loc.rolePrRep,
      loc.roleFamilyMember,
      loc.roleAuthorizedContact,
      loc.other,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.secondaryContacts,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: StanomerColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addEntry(),
              icon: const Icon(LucideIcons.userPlus, size: 15),
              label: Text(
                loc.addSecondaryContact,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: StanomerColors.brandPrimary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (_entries.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.secondaryContactsOptionalDesc,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ..._entries.asMap().entries.map((item) {
            final idx = item.key;
            final entry = item.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.userCheck, size: 15, color: StanomerColors.brandPrimary),
                          const SizedBox(width: 6),
                          Text(
                            '${loc.secondaryContacts} #${idx + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: StanomerColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeEntry(idx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: entry.nameController,
                    decoration: InputDecoration(
                      labelText: '${loc.fullName} *',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                      isDense: true,
                    ),
                    validator: (val) {
                      if (_entries.isNotEmpty && (val == null || val.trim().isEmpty)) {
                        return loc.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Quick Role Picker
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: defaultRoles.map((role) {
                      final isSelected = entry.relationController.text.trim().toLowerCase() == role.toLowerCase();
                      return ChoiceChip(
                        label: Text(role, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            entry.relationController.text = role;
                            _notify();
                          }
                        },
                        selectedColor: StanomerColors.brandPrimarySurface,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? StanomerColors.brandPrimary : StanomerColors.textSecondary,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.relationController,
                          decoration: InputDecoration(
                            labelText: loc.roleOrRelation,
                            prefixIcon: const Icon(LucideIcons.badgeCheck, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: entry.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: loc.phone,
                            prefixIcon: const Icon(LucideIcons.phone, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: entry.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: loc.email,
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
