/// Année de cotisation (année académique, de septembre à août) d'une date :
/// « 2026-2027 » du 1er septembre 2026 au 31 août 2027.
String academicYearOf(DateTime date) {
  final start = date.month >= DateTime.september ? date.year : date.year - 1;
  return '$start-${start + 1}';
}
