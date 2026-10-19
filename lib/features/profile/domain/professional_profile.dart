import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'professional_profile.freezed.dart';
part 'professional_profile.g.dart';

/// `GET /me/profile` : profil professionnel et état de la vitrine.
@freezed
abstract class ProfessionalProfile with _$ProfessionalProfile {
  const factory ProfessionalProfile({
    String? headline,
    String? domain,
    String? city,
    String? summary,
    @Default(<String>[]) List<String> skills,
    @Default(<Language>[]) List<Language> languages,
    @Default(<Experience>[]) List<Experience> experiences,
    @Default(<PortfolioItem>[]) List<PortfolioItem> portfolio,
    String? cvUrl,
    String? linkedinUrl,
    required bool isPublic,
    @JsonKey(unknownEnumValue: ShowcaseStatus.unknown)
    required ShowcaseStatus showcaseStatus,
    DateTime? consentedAt,
  }) = _ProfessionalProfile;

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalProfileFromJson(json);
}

@freezed
abstract class Language with _$Language {
  const factory Language({required String name, String? level}) = _Language;

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}

/// `/me/experiences`.
@freezed
abstract class Experience with _$Experience {
  const factory Experience({
    required int id,
    required String title,
    required String organization,
    String? location,
    @DateOnlyConverter() required DateTime startedOn,
    @NullableDateOnlyConverter() DateTime? endedOn,
    String? description,
  }) = _Experience;

  factory Experience.fromJson(Map<String, dynamic> json) =>
      _$ExperienceFromJson(json);
}

/// `/me/portfolio-items`.
@freezed
abstract class PortfolioItem with _$PortfolioItem {
  const factory PortfolioItem({
    required int id,
    required String title,
    String? description,
    String? url,
    String? fileUrl,
  }) = _PortfolioItem;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) =>
      _$PortfolioItemFromJson(json);
}
