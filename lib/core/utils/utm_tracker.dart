import 'package:flutter/foundation.dart';

class UtmTracker {
  static String? _utmSource;
  static String? _utmMedium;
  static String? _utmCampaign;

  static String? get utmSource => _utmSource;
  static String? get utmMedium => _utmMedium;
  static String? get utmCampaign => _utmCampaign;

  static Map<String, String?> get params => {
        'utm_source': _utmSource,
        'utm_medium': _utmMedium,
        'utm_campaign': _utmCampaign,
      };

  static bool get hasParams =>
      _utmSource != null || _utmMedium != null || _utmCampaign != null;

  /// Initializes and captures UTM parameters from current URL (on web) or explicit query parameters
  static void captureFromUri([Uri? uri]) {
    try {
      final targetUri = uri ?? (kIsWeb ? Uri.base : null);
      if (targetUri == null) return;

      final queryParams = targetUri.queryParameters;
      if (queryParams.containsKey('utm_source')) {
        _utmSource = queryParams['utm_source'];
      }
      if (queryParams.containsKey('utm_medium')) {
        _utmMedium = queryParams['utm_medium'];
      }
      if (queryParams.containsKey('utm_campaign')) {
        _utmCampaign = queryParams['utm_campaign'];
      }
    } catch (e) {
      debugPrint('UtmTracker error: $e');
    }
  }

  /// Explicitly sets UTM parameters
  static void setParams({
    String? source,
    String? medium,
    String? campaign,
  }) {
    if (source != null) _utmSource = source;
    if (medium != null) _utmMedium = medium;
    if (campaign != null) _utmCampaign = campaign;
  }
}
