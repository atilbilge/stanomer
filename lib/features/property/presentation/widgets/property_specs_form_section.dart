import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class PropertySpecsFormSection extends StatefulWidget {
  final String? propertyType;
  final ValueChanged<String?> onPropertyTypeChanged;
  final TextEditingController? unitNumberController;
  final String? roomCount;
  final ValueChanged<String?> onRoomCountChanged;
  final TextEditingController? areaController;
  final String? floor;
  final ValueChanged<String?> onFloorChanged;
  final TextEditingController? totalFloorsController;
  final String? furnishing;
  final ValueChanged<String?> onFurnishingChanged;
  final String? heatingType;
  final ValueChanged<String?> onHeatingTypeChanged;
  final Set<String> selectedAmenities;
  final ValueChanged<Set<String>> onAmenitiesChanged;
  final TextEditingController? descriptionController;

  const PropertySpecsFormSection({
    super.key,
    required this.propertyType,
    required this.onPropertyTypeChanged,
    this.unitNumberController,
    required this.roomCount,
    required this.onRoomCountChanged,
    this.areaController,
    required this.floor,
    required this.onFloorChanged,
    this.totalFloorsController,
    required this.furnishing,
    required this.onFurnishingChanged,
    required this.heatingType,
    required this.onHeatingTypeChanged,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
    this.descriptionController,
  });

  @override
  State<PropertySpecsFormSection> createState() => _PropertySpecsFormSectionState();
}

class _PropertySpecsFormSectionState extends State<PropertySpecsFormSection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- CARD 1: MEKAN & METRİKLER (SPACE & STRUCTURE) ---
        _buildCardWrapper(
          icon: LucideIcons.building,
          title: loc.structuralAndFinancialMetrics,
          subtitle: loc.localeName == 'tr'
              ? 'Mülk tipi, daire no, oda sayısı ve kat metrikleri'
              : 'Property type, room count, unit number & floor metrics',
          children: [
            _buildPropertyTypeSelector(loc),
            if (widget.unitNumberController != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.unitNumberController,
                decoration: InputDecoration(
                  labelText: loc.unitNumberLabel,
                  hintText: loc.unitNumberHint,
                  prefixIcon: const Icon(LucideIcons.doorOpen, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildRoomCountPills(loc),
            const SizedBox(height: 20),
            _buildMetricsGrid(loc),
          ],
        ),

        const SizedBox(height: 20),

        // --- CARD 2: DONANIM & ISITMA (FURNISHING & HEATING) ---
        _buildCardWrapper(
          icon: LucideIcons.armchair,
          title: loc.equipmentAndHeatingStandards,
          subtitle: loc.localeName == 'tr'
              ? 'Eşya durumu ve ısıtma altyapısı'
              : 'Furnishing status and heating infrastructure',
          children: [
            _buildFurnishingGrid(loc),
            const SizedBox(height: 20),
            _buildHeatingTypeDropdown(loc),
          ],
        ),

        const SizedBox(height: 20),

        // --- CARD 3: OLANAKLAR & DETAYLI AÇIKLAMA (AMENITIES & DESCRIPTION) ---
        _buildCardWrapper(
          icon: LucideIcons.sparkles,
          title: loc.featuredAmenitiesLabel,
          subtitle: loc.localeName == 'tr'
              ? 'Öne çıkan konfor özellikleri ve açıklama'
              : 'Featured amenities and extended description',
          children: [
            _buildAmenitiesGroup(loc),
            if (widget.descriptionController != null) ...[
              const SizedBox(height: 20),
              _buildDescriptionArea(loc),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCardWrapper({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: StanomerColors.brandPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: StanomerColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSelector(AppLocalizations loc) {
    final types = [
      {'id': 'apartment', 'label': loc.propertyTypeApartment, 'icon': LucideIcons.building},
      {'id': 'house', 'label': loc.propertyTypeHouse, 'icon': LucideIcons.home},
      {'id': 'commercial', 'label': loc.propertyTypeCommercial, 'icon': LucideIcons.briefcase},
      {'id': 'garage', 'label': loc.propertyTypeGarage, 'icon': LucideIcons.warehouse},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.propertyTypeLabel,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: types.map((t) {
              final isSelected = widget.propertyType == t['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onPropertyTypeChanged(t['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t['icon'] as IconData,
                          size: 15,
                          color: isSelected ? StanomerColors.brandPrimary : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            t['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? StanomerColors.brandPrimary : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCountPills(AppLocalizations loc) {
    final rooms = ['studio', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '5.0+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.roomCountLabel,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: rooms.map((r) {
            final isSelected = widget.roomCount == r;
            final label = r == 'studio' ? (loc.localeName == 'tr' ? 'Stüdyo' : 'Studio') : r;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => widget.onRoomCountChanged(r),
              selectedColor: const Color(0xFFEFF6FF),
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? StanomerColors.brandPrimary : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? StanomerColors.brandPrimary : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(AppLocalizations loc) {
    final areaField = widget.areaController != null
        ? TextFormField(
            controller: widget.areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.areaSqmLabel,
              hintText: '85',
              suffixText: 'm²',
              prefixIcon: const Icon(LucideIcons.maximize2, size: 18),
            ),
          )
        : const SizedBox.shrink();

    final floorDropdown = DropdownButtonFormField<String>(
      key: ValueKey('floor_${widget.floor}'),
      initialValue: widget.floor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loc.floorLevelLabel,
        prefixIcon: const Icon(LucideIcons.layers, size: 18),
      ),
      items: [
        DropdownMenuItem(value: 'suteren', child: Text(loc.floorSuteren, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'prizemlje', child: Text(loc.floorPrizemlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'visoko_prizemlje', child: Text(loc.floorVisokoPrizemlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '1', child: Text(loc.floorNth('1'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '2', child: Text(loc.floorNth('2'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '3', child: Text(loc.floorNth('3'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '4', child: Text(loc.floorNth('4'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '5', child: Text(loc.floorNth('5'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '6', child: Text(loc.floorNth('6'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '7', child: Text(loc.floorNth('7'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '8', child: Text(loc.floorNth('8'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '9', child: Text(loc.floorNth('9'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '10+', child: Text(loc.floorNth('10+'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'potkrovlje', child: Text(loc.floorPotkrovlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'other', child: Text(loc.floorOther, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: widget.onFloorChanged,
    );

    final totalFloorsField = widget.totalFloorsController != null
        ? TextFormField(
            controller: widget.totalFloorsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.totalFloorsLabel,
              hintText: '6',
              prefixIcon: const Icon(LucideIcons.building2, size: 18),
            ),
          )
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: areaField),
                  const SizedBox(width: 12),
                  Expanded(child: totalFloorsField),
                ],
              ),
              const SizedBox(height: 14),
              floorDropdown,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: areaField),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: floorDropdown),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: totalFloorsField),
          ],
        );
      },
    );
  }

  Widget _buildFurnishingGrid(AppLocalizations loc) {
    final options = [
      {
        'id': 'furnished',
        'title': loc.furnishingFurnished,
        'desc': loc.furnishingFurnishedDesc,
        'icon': LucideIcons.armchair,
      },
      {
        'id': 'semi_furnished',
        'title': loc.furnishingSemi,
        'desc': loc.furnishingSemiDesc,
        'icon': LucideIcons.utensils,
      },
      {
        'id': 'unfurnished',
        'title': loc.furnishingUnfurnished,
        'desc': loc.furnishingUnfurnishedDesc,
        'icon': LucideIcons.box,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.furnishingLabel,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 500;

            if (isWide) {
              return Row(
                children: options.map((opt) {
                  final isSelected = widget.furnishing == opt['id'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildFurnishingItem(opt, isSelected),
                    ),
                  );
                }).toList(),
              );
            }

            return Column(
              children: options.map((opt) {
                final isSelected = widget.furnishing == opt['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildFurnishingItem(opt, isSelected),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFurnishingItem(Map<String, dynamic> opt, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onFurnishingChanged(opt['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? StanomerColors.brandPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  opt['icon'] as IconData,
                  size: 18,
                  color: isSelected ? StanomerColors.brandPrimary : const Color(0xFF64748B),
                ),
                Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 16,
                  color: isSelected ? StanomerColors.brandPrimary : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              opt['title'] as String,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              opt['desc'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatingTypeDropdown(AppLocalizations loc) {
    return DropdownButtonFormField<String>(
      key: ValueKey('heating_${widget.heatingType}'),
      initialValue: widget.heatingType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loc.heatingTypeLabel,
        prefixIcon: const Icon(LucideIcons.flame, size: 18),
      ),
      items: [
        DropdownMenuItem(value: 'cg', child: Text(loc.heatingCg, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'eg', child: Text(loc.heatingEg, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'gas', child: Text(loc.heatingGas, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'underfloor', child: Text(loc.heatingUnderfloor, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'ta', child: Text(loc.heatingTa, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: widget.onHeatingTypeChanged,
    );
  }

  Widget _buildAmenitiesGroup(AppLocalizations loc) {
    final amenities = [
      {'id': 'pets_allowed', 'label': loc.amenityPets, 'icon': LucideIcons.pawPrint},
      {'id': 'elevator', 'label': loc.amenityElevator, 'icon': LucideIcons.arrowUpCircle},
      {'id': 'balcony', 'label': loc.amenityBalcony, 'icon': LucideIcons.sunMedium},
      {'id': 'parking', 'label': loc.amenityParking, 'icon': LucideIcons.car},
      {'id': 'storage', 'label': loc.amenityStorage, 'icon': LucideIcons.package},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) {
        final id = a['id'] as String;
        final isChecked = widget.selectedAmenities.contains(id);
        return GestureDetector(
          onTap: () {
            final next = Set<String>.from(widget.selectedAmenities);
            if (isChecked) {
              next.remove(id);
            } else {
              next.add(id);
            }
            widget.onAmenitiesChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChecked ? StanomerColors.brandPrimary : const Color(0xFFE2E8F0),
                width: isChecked ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isChecked ? LucideIcons.checkSquare : LucideIcons.square,
                  size: 15,
                  color: isChecked ? StanomerColors.brandPrimary : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Icon(
                  a['icon'] as IconData,
                  size: 14,
                  color: isChecked ? StanomerColors.brandPrimary : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  a['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                    color: isChecked ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionArea(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.extendedDescriptionLabel,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            if (widget.descriptionController != null)
              Text(
                '${widget.descriptionController!.text.length} / 2000',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.descriptionController,
          maxLength: 2000,
          maxLines: 4,
          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: loc.extendedDescriptionHint,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
