import 'package:json_annotation/json_annotation.dart';

/// Date sans heure (`2026-10-13`), lue et renvoyée telle quelle.
///
/// Lue en date locale à minuit, pour qu'aucun fuseau ne décale le jour.
/// Accepte aussi une date-heure ISO 8601 (on garde son jour local).
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(String json) {
    final value = json.trim();
    if (value.length == 10) {
      final parsed = DateTime.parse(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final local = DateTime.parse(value).toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  String toJson(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Variante pour les champs facultatifs.
class NullableDateOnlyConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateOnlyConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : const DateOnlyConverter().fromJson(json);

  @override
  String? toJson(DateTime? date) =>
      date == null ? null : const DateOnlyConverter().toJson(date);
}
