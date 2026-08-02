import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../data/maintenance_repository.dart';
import 'maintenance_screen.dart';
import 'create_maintenance_screen.dart';

/// Kiracı web tasarımında sol menü "Bakım & Onarım" sekmesine tıklandığında
/// açılan akıllı gateway ekranı.
///
/// Davranış:
///  - Kiracının mülkü yükleniyor → spinner
///  - Mülk bulunamadıysa → bilgi kartı
///  - Bakım talebi(leri) varsa → [MaintenanceScreen] (liste)
///  - Hiç bakım talebi yoksa → [CreateMaintenanceRequestScreen] (yeni talep formu)
class TenantMaintenanceGatewayScreen extends ConsumerWidget {
  const TenantMaintenanceGatewayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesStreamProvider);

    return propertiesAsync.when(
      loading: () => const _LoadingView(),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (properties) {
        // Kiracının aktif mülkü (tenantId = currentUser)
        final Property? tenantProperty = properties.isNotEmpty ? properties.first : null;

        if (tenantProperty == null) {
          return const _NoPropertyView();
        }

        return _MaintenanceRouter(property: tenantProperty);
      },
    );
  }
}

/// Bakım taleplerini kontrol edip uygun ekrana yönlendirir.
class _MaintenanceRouter extends ConsumerWidget {
  final Property property;

  const _MaintenanceRouter({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(maintenanceRequestsProvider(property.id));

    return requestsAsync.when(
      loading: () => const _LoadingView(),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (requests) {
        if (requests.isEmpty) {
          // Hiç bakım talebi yok → yeni talep formu
          return CreateMaintenanceRequestScreen(property: property);
        } else {
          // Bakım talepleri var → liste ekranı
          return MaintenanceScreen(property: property);
        }
      },
    );
  }
}

// ────────────────────────────────────────────
// Yardımcı widget'lar
// ────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text('Bir hata oluştu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _NoPropertyView extends StatelessWidget {
  const _NoPropertyView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.home, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 20),
            Text(
              loc.tenantNoPropertyTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tenantNoPropertyMaintenanceTooltip.replaceAll('\n', ' '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
