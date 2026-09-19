/// Normalizes a phone number to E.164 (`+233...`) so the backend accepts
/// the local formats people actually type (e.g. `050...`) as well as the
/// international one — without this, a locally-formatted number the
/// backend can't match to an account surfaces as a generic error.
String normalizeGhanaPhone(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('+')) return trimmed;
  if (trimmed.startsWith('00')) return '+${trimmed.substring(2)}';
  if (trimmed.startsWith('0')) return '+233${trimmed.substring(1)}';
  if (trimmed.startsWith('233')) return '+$trimmed';
  return '+233$trimmed';
}
