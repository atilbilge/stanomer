with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# Fix PropertyDetailScreenState
bad_init = """  @override
  void initState() {
    super.initState();
    widget.settingsSectionNotifier.addListener(_onSectionChanged);

    _tabController = TabController(length: 4, vsync: this);
  }"""
good_init = """  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }"""

bad_dispose = """  @override
  void dispose() {
    widget.settingsSectionNotifier.removeListener(_onSectionChanged);

    _tabController.dispose();
    super.dispose();
  }"""
good_dispose = """  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }"""

content = content.replace(bad_init, good_init)
content = content.replace(bad_dispose, good_dispose)

# Add listener to _SettingsTabState
settings_tab_init_regex = r"""class _SettingsTabState extends ConsumerState<_SettingsTab> \{
  void _onSectionChanged\(\) \{
    if \(mounted\) setState\(\(\) \{\}\);
  \}
([\s\S]*?)  @override
  void initState\(\) \{
    super.initState\(\);"""

settings_tab_init_replacement = r"""class _SettingsTabState extends ConsumerState<_SettingsTab> {
  void _onSectionChanged() {
    if (mounted) setState(() {});
  }
\1  @override
  void initState() {
    super.initState();
    widget.settingsSectionNotifier.addListener(_onSectionChanged);"""

import re
content = re.sub(settings_tab_init_regex, settings_tab_init_replacement, content, count=1)

settings_tab_dispose_regex = r"""  @override
  void dispose\(\) \{
    _nameController.dispose\(\);"""

settings_tab_dispose_replacement = r"""  @override
  void dispose() {
    widget.settingsSectionNotifier.removeListener(_onSectionChanged);
    _nameController.dispose();"""

content = re.sub(settings_tab_dispose_regex, settings_tab_dispose_replacement, content, count=1)

with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

