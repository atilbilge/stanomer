// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web implementation that uses Blob URLs to bypass Chrome's top-level navigation blocks on data: URIs.
Future<void> openHtmlPrintView(String htmlContent, String title) async {
  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Open in a new tab
  html.window.open(url, '_blank');

  // Keep object URL alive for 5 minutes so user can print, refresh, or view without revocation errors
  Future.delayed(const Duration(minutes: 5), () {
    html.Url.revokeObjectUrl(url);
  });
}
