// Pure Dart helpers (no Flutter imports, so they are easy to unit test).

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String toIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayIso() => toIso(DateTime.now());

DateTime? parseIso(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "2024-03-05" -> "5 Mar 2024". Returns "-" when empty/invalid.
String showDate(String? iso) {
  final d = parseIso(iso);
  if (d == null) return '-';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Short age text from a hatch date: "20d", "5m", "2y 3m". Empty if unknown.
String ageText(String? hatchIso, {DateTime? now}) {
  final h = parseIso(hatchIso);
  if (h == null) return '';
  final n = now ?? DateTime.now();
  if (n.isBefore(h)) return '';
  var months = (n.year - h.year) * 12 + (n.month - h.month);
  if (n.day < h.day) months -= 1;
  if (months >= 12) {
    final y = months ~/ 12;
    final r = months % 12;
    return r == 0 ? '${y}y' : '${y}y ${r}m';
  }
  if (months >= 1) return '${months}m';
  return '${n.difference(h).inDays}d';
}
