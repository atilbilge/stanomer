import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Provide `bool isLandlord` property to `_showPropertySettingsSheet` and conditionally render Edit button.
sheet_def_regex = r"""  void _showPropertySettingsSheet\(BuildContext context\) \{
    final isTr = Localizations.localeOf\(context\).languageCode == 'tr';
    showModalBottomSheet\("""
sheet_def_replace = """  void _showPropertySettingsSheet(BuildContext context, bool isLandlord) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    showModalBottomSheet("""
content = re.sub(sheet_def_regex, sheet_def_replace, content, 1)

row_regex = r"""            Row\(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: \[
                Text\(isTr \? 'Ev Ayarları' : 'Property Settings', style: const TextStyle\(fontSize: 18, fontWeight: FontWeight.bold\)\),
                TextButton.icon\("""
row_replace = """            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isTr ? 'Ev Ayarları' : 'Property Settings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isLandlord)
                  TextButton.icon("""
content = re.sub(row_regex, row_replace, content, 1)

# 2. Update call site to _showPropertySettingsSheet
nav_regex = r"""                _ModernNavRow\(
                  icon: LucideIcons.settings,
                  title: isTr \? 'Ev ayarları' : 'Property settings',
                  subtitle: liveProperty.name,
                  onTap: \(\) => _showPropertySettingsSheet\(context\),
                \),"""
nav_replace = """                _ModernNavRow(
                  icon: LucideIcons.settings,
                  title: isTr ? 'Ev ayarları' : 'Property settings',
                  subtitle: liveProperty.name,
                  onTap: () => _showPropertySettingsSheet(context, effectiveIsLandlord),
                ),"""
content = re.sub(nav_regex, nav_replace, content, 1)

# 3. Dynamic TabController in _PropertyDetailScreenState
state_class_regex = r"""class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin \{
  late TabController _tabController;
  final ValueNotifier<String> _settingsSectionNotifier = ValueNotifier\('contract'\);
  final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>\(\); // Kept just in case


  @override
  void initState\(\) \{
    super.initState\(\);
    _tabController = TabController\(length: 4, vsync: this\);
  \}


  @override
  void dispose\(\) \{
    _tabController.dispose\(\);
    super.dispose\(\);
  \}"""
state_class_replace = """class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final ValueNotifier<String> _settingsSectionNotifier = ValueNotifier('contract');
  final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>(); // Kept just in case
  bool? _isLandlord;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }"""
content = re.sub(state_class_regex, state_class_replace, content, 1)


# 4. Modify build method in _PropertyDetailScreenState to init TabController dynamically
build_regex = r"""  @override
  Widget build\(BuildContext context\) \{
    final loc = AppLocalizations.of\(context\)[\!];
    final propertiesAsync = ref.watch\(propertiesStreamProvider\);
    
    // Find the current property in the stream to get up-to-date info
    final property = propertiesAsync.when\("""
build_replace = """  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final authState = ref.watch(authStateProvider);
    final currentIsLandlord = widget.property.ownerId == authState.user?.uid;

    if (_isLandlord != currentIsLandlord || _tabController == null) {
      _isLandlord = currentIsLandlord;
      _tabController?.dispose();
      _tabController = TabController(length: _isLandlord! ? 4 : 3, vsync: this);
    }
    
    // Find the current property in the stream to get up-to-date info
    final property = propertiesAsync.when("""
content = re.sub(build_regex, build_replace, content, 1)

# 5. Modify TabBar tabs and TabBarView children
tabbar_regex = r"""      appBar: AppBar\(
        title: Text\(property.name\),
        bottom: TabBar\(
          controller: _tabController,
          tabs: \[
            Tab\(text: loc.overview\),
            Tab\(text: loc.financials\),
            Tab\(text: loc.activity\),
            Tab\(text: loc.propertySettings\),
          \],
        \),
      \),
      body: TabBarView\(
        controller: _tabController,
        children: \[
          _OverviewTab\(property: property, tabController: _tabController!, settingsSectionNotifier: _settingsSectionNotifier\),
          _FinancialsTab\(property: property\),
          _ActivityTab\(property: property\),
          _SettingsTab\(property: property, tabController: _tabController!, settingsSectionNotifier: _settingsSectionNotifier\),
        \],
      \),"""
tabbar_replace = """      appBar: AppBar(
        title: Text(property.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.overview),
            Tab(text: loc.financials),
            Tab(text: loc.activity),
            if (_isLandlord!) Tab(text: loc.propertySettings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(property: property, tabController: _tabController!, settingsSectionNotifier: _settingsSectionNotifier),
          _FinancialsTab(property: property),
          _ActivityTab(property: property),
          if (_isLandlord!) _SettingsTab(property: property, tabController: _tabController!, settingsSectionNotifier: _settingsSectionNotifier),
        ],
      ),"""

# Let's verify how it was exactly matched:
tabbar_regex2 = r"""      appBar: AppBar\(
        title: Text\(property.name\),
        bottom: TabBar\(
          controller: _tabController,
          tabs: \[
            Tab\(text: loc.overview\),
            Tab\(text: loc.financials\),
            Tab\(text: loc.activity\),
            Tab\(text: loc.propertySettings\),
          \],
        \),
      \),
      body: TabBarView\(
        controller: _tabController,
        children: \[
          _OverviewTab\(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier\),
          _FinancialsTab\(property: property\),
          _ActivityTab\(property: property\),
          _SettingsTab\(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier\),
        \],
      \),"""

content = re.sub(tabbar_regex2, tabbar_replace, content, 1)


with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

