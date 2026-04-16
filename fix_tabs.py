import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Revert PropertyDetailScreenState
state_class_regex = r"""class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin \{
  TabController\? _tabController;
  final ValueNotifier<String> _settingsSectionNotifier = ValueNotifier\('contract'\);
  final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>\(\); // Kept just in case
  bool\? _isLandlord;

  @override
  void dispose\(\) \{
    _tabController\?\.dispose\(\);
    super\.dispose\(\);
  \}"""

state_class_replace = """class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<String> _settingsSectionNotifier = ValueNotifier('contract');
  final GlobalKey<_SettingsTabState> _settingsKey = GlobalKey<_SettingsTabState>(); // Kept just in case

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }"""
content = re.sub(state_class_regex, state_class_replace, content, 1)

build_regex = r"""  @override
  Widget build\(BuildContext context\) \{
    final loc = AppLocalizations.of\(context\)[\!];
    final propertiesAsync = ref.watch\(propertiesStreamProvider\);
    final user = ref.watch\(currentUserProvider\);
    final currentIsLandlord = widget.property.landlordId == user\?.id;

    if \(_isLandlord \!= currentIsLandlord \|\| _tabController == null\) \{
      _isLandlord = currentIsLandlord;
      _tabController\?\.dispose\(\);
      _tabController = TabController\(length: _isLandlord\! \? 4 : 3, vsync: this\);
    \}
    
    // Find the current property in the stream to get up-to-date info
    final property = propertiesAsync\.when\("""
build_replace = """  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    
    // Find the current property in the stream to get up-to-date info
    final property = propertiesAsync.when("""
content = re.sub(build_regex, build_replace, content, 1)

tabview_regex = r"""      appBar: AppBar\(
        title: Text\(property\.name\),
        bottom: TabBar\(
          controller: _tabController,
          tabs: \[
            Tab\(text: loc\.overview\),
            Tab\(text: loc\.financials\),
            Tab\(text: loc\.activity\),
            if \(_isLandlord\!\) Tab\(text: loc\.propertySettings\),
          \],
        \),
      \),
      body: TabBarView\(
        controller: _tabController,
        children: \[
          _OverviewTab\(property: property, tabController: _tabController\!, settingsSectionNotifier: _settingsSectionNotifier\),
          _FinancialsTab\(property: property\),
          _ActivityTab\(property: property\),
          if \(_isLandlord\!\) _SettingsTab\(property: property, tabController: _tabController\!, settingsSectionNotifier: _settingsSectionNotifier\),
        \],
      \),"""
tabview_replace = """      appBar: AppBar(
        title: Text(property.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.overview),
            Tab(text: loc.financials),
            Tab(text: loc.activity),
            Tab(text: loc.propertySettings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier),
          _FinancialsTab(property: property),
          _ActivityTab(property: property),
          _SettingsTab(property: property, tabController: _tabController, settingsSectionNotifier: _settingsSectionNotifier),
        ],
      ),"""
content = re.sub(tabview_regex, tabview_replace, content, 1)

with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

