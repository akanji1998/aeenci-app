import 'package:freezed_annotation/freezed_annotation.dart';

part 'education.freezed.dart';
part 'education.g.dart';

/// `/me/educations` : une formation du parcours scolaire.
@freezed
abstract class Education with _$Education {
  const factory Education({
    required int id,

    /// Une `value` de `/education-levels`.
    required String level,
    required String school,
    required String fieldOfStudy,
    String? diploma,
    int? startYear,
    int? endYear,
  }) = _Education;

  factory Education.fromJson(Map<String, dynamic> json) =>
      _$EducationFromJson(json);
}

/// `GET /education-levels` : niveaux d'études tenus par le bureau.
@freezed
abstract class EducationLevel with _$EducationLevel {
  const factory EducationLevel({required String value, required String label}) =
      _EducationLevel;

  factory EducationLevel.fromJson(Map<String, dynamic> json) =>
      _$EducationLevelFromJson(json);
}
