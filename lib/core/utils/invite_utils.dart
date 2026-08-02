/// Utility to parse token from invitation URLs or raw token strings.
String extractToken(String rawInput) {
  final trimmed = rawInput.trim();
  if (trimmed.isEmpty) return '';

  final match = RegExp(r'[?&]token=([^&/#\s]+)').firstMatch(trimmed) ??
                RegExp(r'token=([^&/#\s]+)').firstMatch(trimmed);

  if (match != null && match.group(1) != null) {
    return match.group(1)!;
  }

  return trimmed;
}
