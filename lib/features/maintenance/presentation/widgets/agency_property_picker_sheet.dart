import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../property/domain/property.dart';

/// Displays a modal bottom sheet allowing an agency user to search and select
/// one of their managed properties before navigating to the maintenance request form.
Future<Property?> showAgencyPropertyPickerSheet({
  required BuildContext context,
  required List<Property> properties,
  Property? initialSelectedProperty,
  Color? primaryColor,
}) {
  final themeColor = primaryColor ?? const Color(0xFF0284C7);

  return showModalBottomSheet<Property>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (ctx) => ResilientBottomSheetWrapper(
      child: AgencyPropertyPickerSheet(
        properties: properties,
        initialSelectedProperty: initialSelectedProperty,
        primaryColor: themeColor,
      ),
    ),
  );
}

class AgencyPropertyPickerSheet extends StatefulWidget {
  final List<Property> properties;
  final Property? initialSelectedProperty;
  final Color primaryColor;

  const AgencyPropertyPickerSheet({
    super.key,
    required this.properties,
    this.initialSelectedProperty,
    required this.primaryColor,
  });

  @override
  State<AgencyPropertyPickerSheet> createState() => _AgencyPropertyPickerSheetState();
}

class _AgencyPropertyPickerSheetState extends State<AgencyPropertyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> _getLocalizedTexts(String lang) {
    switch (lang) {
      case 'tr':
        return {
          'title': 'Mülk Seçin',
          'subtitle': 'Bakım talebi oluşturulacak mülkü seçiniz',
          'search_hint': 'Mülk veya adres ara...',
          'empty_search': 'Aramanıza uygun mülk bulunamadı',
          'empty_properties': 'Yönetilen mülk bulunamadı',
          'current_badge': 'Mevcut',
        };
      case 'sr':
        return {
          'title': 'Izaberite nekretninu',
          'subtitle': 'Izaberite nekretninu za prijavu kvara / održavanja',
          'search_hint': 'Pretraži po nazivu ili adresi...',
          'empty_search': 'Nema nekretnina koje odgovaraju pretrazi',
          'empty_properties': 'Nema registrovanih nekretnina',
          'current_badge': 'Trenutna',
        };
      case 'ru':
        return {
          'title': 'Выберите объект',
          'subtitle': 'Выберите объект для оформления заявки на ремонт',
          'search_hint': 'Поиск по названию или адресу...',
          'empty_search': 'Объекты не найдены',
          'empty_properties': 'Нет зарегистрированных объектов',
          'current_badge': 'Текущий',
        };
      case 'en':
      default:
        return {
          'title': 'Select Property',
          'subtitle': 'Choose the property to submit a maintenance request for',
          'search_hint': 'Search by name or address...',
          'empty_search': 'No matching properties found',
          'empty_properties': 'No managed properties found',
          'current_badge': 'Current',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final txt = _getLocalizedTexts(lang);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    // Filter properties based on search query
    final filtered = widget.properties.where((p) {
      if (_searchQuery.isEmpty) return true;
      final nameMatch = p.name.toLowerCase().contains(_searchQuery);
      final addrMatch = p.address.toLowerCase().contains(_searchQuery);
      return nameMatch || addrMatch;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag indicator
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.wrench,
                          color: widget.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txt['title']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              txt['subtitle']!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search field (if more than 2 properties or active query)
                if (widget.properties.length > 2 || _searchQuery.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: txt['search_hint'],
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Property List
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.building,
                                  size: 24,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? txt['empty_search']!
                                    : txt['empty_properties']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final property = filtered[index];
                            final isSelected = widget.initialSelectedProperty?.id == property.id;

                            return Material(
                              color: isSelected
                                  ? widget.primaryColor.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(property),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? widget.primaryColor
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Property Thumbnail / Icon
                                      _buildDefaultThumbnail(isSelected),
                                      const SizedBox(width: 14),

                                      // Property Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    property.name,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected
                                                          ? widget.primaryColor
                                                          : const Color(0xFF0F172A),
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: widget.primaryColor
                                                          .withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      txt['current_badge']!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: widget.primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              [
                                                if (property.address.isNotEmpty) property.address,
                                                if (property.unitNumber != null && property.unitNumber!.isNotEmpty)
                                                  'No: ${property.unitNumber}',
                                                if (property.city != null && property.city!.isNotEmpty)
                                                  property.city!,
                                              ].join(', '),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // Trailing Icon
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? widget.primaryColor.withValues(alpha: 0.1)
                                              : const Color(0xFFF8FAFC),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? widget.primaryColor.withValues(alpha: 0.3)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? LucideIcons.check
                                              : LucideIcons.chevronRight,
                                          size: 16,
                                          color: isSelected
                                              ? widget.primaryColor
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail(bool isSelected) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isSelected
            ? widget.primaryColor.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        LucideIcons.building2,
        color: isSelected ? widget.primaryColor : const Color(0xFF64748B),
        size: 22,
      ),
    );
  }
}
