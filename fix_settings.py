import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Update _SettingsTabState build
build_regex = r"""  @override
  Widget build\(BuildContext context\) \{
    final loc = AppLocalizations.of\(context\)[\!];
    final isTr = loc.localeName == 'tr';

    return Column\(
      children: \[
        // ── Toggle ─────────────────────────────────────────────
        Padding\(
          padding: const EdgeInsets.fromLTRB\(24, 20, 24, 0\),
          child: SegmentedButton<String>\(
            segments: \[
              ButtonSegment\(
                value: 'contract',
                label: Text\(isTr \? 'Kontrat Ayarları' : 'Contract Settings', style: const TextStyle\(fontSize: 12\)\),
                icon: const Icon\(LucideIcons.fileEdit, size: 15\),
              \),
              ButtonSegment\(
                value: 'property',
                label: Text\(isTr \? 'Ev Ayarları' : 'Property Settings', style: const TextStyle\(fontSize: 12\)\),
                icon: const Icon\(LucideIcons.home, size: 15\),
              \),
            \],
            selected: \{widget.settingsSectionNotifier.value\},
            onSelectionChanged: \(val\) => widget.settingsSectionNotifier.value = val.first,
            style: SegmentedButton.styleFrom\(
              selectedBackgroundColor: StanomerColors.brandPrimary,
              selectedForegroundColor: Colors.white,
            \),
          \),
        \),

        // ── Panel ──────────────────────────────────────────────
        Expanded\(
          child: SingleChildScrollView\(
            padding: const EdgeInsets.all\(24\),
            child: widget.settingsSectionNotifier.value == 'contract'
                \? _buildContractPanel\(loc, isTr\)
                : _buildPropertyPanel\(loc, isTr\),
          \),
        \),
      \],
    \);
  \}"""

build_replace = """  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTr = loc.localeName == 'tr';
    final user = ref.watch(currentUserProvider);
    final isLandlord = widget.property.landlordId == user?.id;

    return Column(
      children: [
        // ── Toggle ─────────────────────────────────────────────
        if (isLandlord)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'contract',
                  label: Text(isTr ? 'Kontrat Ayarları' : 'Contract Settings', style: const TextStyle(fontSize: 12)),
                  icon: const Icon(LucideIcons.fileEdit, size: 15),
                ),
                ButtonSegment(
                  value: 'property',
                  label: Text(isTr ? 'Ev Ayarları' : 'Property Settings', style: const TextStyle(fontSize: 12)),
                  icon: const Icon(LucideIcons.home, size: 15),
                ),
              ],
              selected: {widget.settingsSectionNotifier.value},
              onSelectionChanged: (val) => widget.settingsSectionNotifier.value = val.first,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: StanomerColors.brandPrimary,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ),

        // ── Panel ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: (isLandlord && widget.settingsSectionNotifier.value == 'property')
                ? _buildPropertyPanel(loc, isTr)
                : _buildContractPanel(loc, isTr),
          ),
        ),
      ],
    );
  }"""

content = re.sub(build_regex, build_replace, content, 1)

# 2. Update the Tab Title depending on role
tabbar_regex = r"""            Tab\(text: loc.overview\),
            Tab\(text: loc.financials\),
            Tab\(text: loc.activity\),
            Tab\(text: loc.propertySettings\),"""

tabbar_replace = """            Tab(text: loc.overview),
            Tab(text: loc.financials),
            Tab(text: loc.activity),
            Tab(text: currentIsLandlord ? loc.propertySettings : (loc.localeName == 'tr' ? 'Kontrat Ayarları' : 'Contract Settings')),"""

content = re.sub(tabbar_regex, tabbar_replace, content, 1)

with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

