import '../../../core/utils/academic_year.dart';
import '../../contributions/domain/contribution.dart';
import '../../events/domain/event.dart';
import '../../profile/domain/professional_profile.dart';

/// Cotisation de l'année académique en cours, sinon la plus récente.
Contribution? currentContribution(List<Contribution> all, DateTime now) {
  if (all.isEmpty) return null;
  final year = academicYearOf(now);
  for (final contribution in all) {
    if (contribution.year == year) return contribution;
  }
  // Les années « 2025-2026 » se comparent comme du texte.
  return ([...all]..sort((a, b) => b.year.compareTo(a.year))).first;
}

/// Prochain événement à venir où le membre est inscrit.
Registration? nextRegistration(List<Registration> all, DateTime now) {
  final upcoming = [
    for (final registration in all)
      if (registration.event.startsAt.isAfter(now)) registration,
  ]..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));
  return upcoming.isEmpty ? null : upcoming.first;
}

/// Rappel « Complète ton profil pro » : il manque le CV ou les compétences.
bool profileNeedsCompletion(ProfessionalProfile profile) =>
    profile.cvUrl == null || profile.skills.isEmpty;
