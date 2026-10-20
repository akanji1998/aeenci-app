import 'professional_profile.dart';

/// Les 8 critères du taux de complétion, de même poids. LinkedIn et les
/// réalisations ne comptent pas : ce sont des bonus.
List<bool> completionCriteria(ProfessionalProfile profile) {
  bool filled(String? value) => value != null && value.trim().isNotEmpty;
  return [
    filled(profile.headline),
    filled(profile.domain),
    filled(profile.city),
    filled(profile.summary),
    profile.skills.isNotEmpty,
    profile.languages.isNotEmpty,
    profile.experiences.isNotEmpty,
    profile.cvUrl != null,
  ];
}

/// Taux de complétion du profil professionnel, de 0 à 100.
int profileCompletion(ProfessionalProfile profile) {
  final criteria = completionCriteria(profile);
  return (criteria.where((c) => c).length * 100 / criteria.length).round();
}
