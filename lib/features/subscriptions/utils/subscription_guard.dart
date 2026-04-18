import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../property/data/property_repository.dart';
import '../data/subscription_service.dart';

final canAddPropertyProvider = Provider<bool>((ref) {
  final propertiesAsync = ref.watch(propertiesStreamProvider);
  final isPremium = ref.watch(isPremiumProvider);

  return propertiesAsync.when(
    data: (properties) {
      // Rule: Free users can have at most 1 property.
      // If they have 0 properties, they can add 1.
      // If they have 1 or more, they must be premium.
      if (isPremium) return true;
      return properties.length < 1;
    },
    loading: () => false, // Default to false while loading to be conservative
    error: (_, __) => false,
  );
});
