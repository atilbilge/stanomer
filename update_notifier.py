import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Update _PropertyDetailScreenState
content = content.replace(
    'final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>();',
    "final ValueNotifier<String> _settingsSectionNotifier = ValueNotifier('contract');\n  final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>(); // Kept just in case"
)

content = content.replace(
    '          _OverviewTab(property: property, tabController: _tabController, settingsKey: _settingsKey),\n',
    '          _OverviewTab(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier),\n'
)

content = content.replace(
    '          _SettingsTab(key: _settingsKey, property: property, tabController: _tabController),\n',
    '          _SettingsTab(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier),\n'
)

# 2. Update _OverviewTab
content = content.replace(
    '  final GlobalKey<_SettingsTabState> settingsKey;\n  const _OverviewTab({required this.property, required this.tabController, required this.settingsKey});\n',
    "  final ValueNotifier<String> settingsSectionNotifier;\n  const _OverviewTab({required this.property, required this.tabController, required this.settingsSectionNotifier});\n"
)

# 3. Update TextButtons in _OverviewTab
content = content.replace(
    "settingsKey.currentState?.scrollToContractSection();",
    "settingsSectionNotifier.value = 'contract';"
)

content = content.replace(
    "settingsKey.currentState?.scrollToPropertySection();",
    "settingsSectionNotifier.value = 'property';"
)

# 4. Update _SettingsTab
content = content.replace(
    '  final TabController tabController;\n  const _SettingsTab({super.key, required this.property, required this.tabController});',
    '  final TabController tabController;\n  final ValueNotifier<String> settingsSectionNotifier;\n  const _SettingsTab({super.key, required this.property, required this.tabController, required this.settingsSectionNotifier});'
)

# 5. Update _SettingsTabState
# Remove local _activeSection
content = content.replace(
    "  // Active section toggle\n  String _activeSection = 'contract'; // 'contract' | 'property'\n\n  // Kept for external callers from Overview bottom sheet Edit buttons\n  void scrollToContractSection() {\n    setState(() => _activeSection = 'contract');\n  }\n\n  void scrollToPropertySection() {\n    setState(() => _activeSection = 'property');\n  }\n",
    ""
)

# Replace remaining _activeSection occurences with widget.settingsSectionNotifier.value using a ValueListenableBuilder or just by adding a listener
# Actually, since it's a ValueNotifier, we can listen to it.
listener_code = """
  @override
  void initState() {
    super.initState();
    widget.settingsSectionNotifier.addListener(_onSectionChanged);
"""

content = content.replace("  @override\n  void initState() {\n    super.initState();", listener_code, 1)

dispose_code = """
  @override
  void dispose() {
    widget.settingsSectionNotifier.removeListener(_onSectionChanged);
"""

content = content.replace("  @override\n  void dispose() {", dispose_code, 1)


# Add method
content = content.replace("class _SettingsTabState extends ConsumerState<_SettingsTab> {", "class _SettingsTabState extends ConsumerState<_SettingsTab> {\n  void _onSectionChanged() {\n    if (mounted) setState(() {});\n  }\n", 1)


# Replace usages of _activeSection
content = content.replace("_activeSection == 'contract'", "widget.settingsSectionNotifier.value == 'contract'")
content = content.replace("_activeSection", "widget.settingsSectionNotifier.value")

# Replace SegmentedButton stuff
content = content.replace("selected: {widget.settingsSectionNotifier.value},", "selected: {widget.settingsSectionNotifier.value},")
content = content.replace("onSelectionChanged: (val) => setState(() => widget.settingsSectionNotifier.value = val.first),", "onSelectionChanged: (val) => widget.settingsSectionNotifier.value = val.first,")


with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

