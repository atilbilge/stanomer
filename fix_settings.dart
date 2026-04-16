import 'dart:io';

void main() {
  final file = File('lib/features/property/presentation/property_settings_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll('_SettingsTab', 'PropertySettingsScreen');

  content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../property/domain/contract.dart';
import '../../property/domain/expense_item.dart';
import '../../auth/data/auth_providers.dart';
import '../data/property_repository.dart';
import '../data/property_providers.dart';
import '../presentation/widgets/payment_responsibility_selector.dart';

''' + content;

  // Fix constructor
  content = content.replaceFirst(
'''class PropertySettingsScreen extends ConsumerStatefulWidget {
  final Property property;
  final TabController tabController;
  final ValueNotifier<String> settingsSectionNotifier;
  const PropertySettingsScreen({super.key, required this.property, required this.tabController, required this.settingsSectionNotifier});''',
'''class PropertySettingsScreen extends ConsumerStatefulWidget {
  final Property property;
  final String initialTab;
  const PropertySettingsScreen({super.key, required this.property, this.initialTab = 'contract'});'''
  );

  // Fix state class init
  content = content.replaceFirst(
'''class _PropertySettingsScreenState extends ConsumerState<PropertySettingsScreen> {
  void _onSectionChanged() {
    if (mounted) setState(() {});
  }''',
'''class _PropertySettingsScreenState extends ConsumerState<PropertySettingsScreen> {
  late final ValueNotifier<String> settingsSectionNotifier;

  void _onSectionChanged() {
    if (mounted) setState(() {});
  }'''
  );

  content = content.replaceFirst(
'''  @override
  void initState() {
    super.initState();
    widget.settingsSectionNotifier.addListener(_onSectionChanged);''',
'''  @override
  void initState() {
    super.initState();
    settingsSectionNotifier = ValueNotifier(widget.initialTab);
    settingsSectionNotifier.addListener(_onSectionChanged);'''
  );

  content = content.replaceFirst(
'''  @override
  void dispose() {
    widget.settingsSectionNotifier.removeListener(_onSectionChanged);''',
'''  @override
  void dispose() {
    settingsSectionNotifier.removeListener(_onSectionChanged);
    settingsSectionNotifier.dispose();'''
  );

  // Fix build return to be a Scaffold
  content = content.replaceFirst(
'''    final user = ref.watch(currentUserProvider);
    final isLandlord = widget.property.landlordId == user?.id;

    return Column(
      children: [
        // ── Toggle ─────────────────────────────────────────────''',
'''    final user = ref.watch(currentUserProvider);
    final isLandlord = widget.property.landlordId == user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.propertySettingsLabel),
      ),
      body: Column(
        children: [
          // ── Toggle ─────────────────────────────────────────────'''
  );

  content = content.replaceFirst(
'''        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: (isLandlord && widget.settingsSectionNotifier.value == 'property')
                ? _buildPropertyPanel(loc)
                : _buildContractPanel(loc),
          ),
        ),
      ],
    );''',
'''        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: (isLandlord && settingsSectionNotifier.value == 'property')
                ? _buildPropertyPanel(loc)
                : _buildContractPanel(loc),
          ),
        ),
      ],
      ),
    );'''
  );

  content = content.replaceAll('widget.settingsSectionNotifier.value', 'settingsSectionNotifier.value');

  file.writeAsStringSync(content);
}
