/// Compare deux versions `majeur.mineur.correctif` (suffixes `-dev`, `+5`
/// ignorés). Négatif si [a] < [b], 0 si égales, positif sinon.
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  for (var i = 0; i < 3; i++) {
    final diff = left[i] - right[i];
    if (diff != 0) return diff;
  }
  return 0;
}

List<int> _parts(String version) {
  final core = version.trim().split(RegExp('[-+]')).first;
  final parts = core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  return parts;
}
