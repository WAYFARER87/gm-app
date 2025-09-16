bool parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    final n = num.tryParse(lower);
    if (n != null) return n != 0;
  }
  return false;
}
