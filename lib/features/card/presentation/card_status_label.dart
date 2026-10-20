import '../../../core/domain/enums.dart';
import '../../../l10n/generated/app_localizations.dart';

/// « Membre actif », « Ancienne membre en sourdine », « Aînée active »…
/// accordé d'après le genre de la fiche (`GET /me`).
String cardStatusLabel(
  AppLocalizations l10n, {
  required MemberStatus status,
  required Engagement? engagement,
  required Gender gender,
}) {
  final g = gender == Gender.female ? 'female' : 'other';
  final statusText = switch (status) {
    MemberStatus.member => l10n.cardStatusMember,
    MemberStatus.former => l10n.cardStatusFormer(g),
    MemberStatus.elder => l10n.cardStatusElder(g),
    MemberStatus.unknown => l10n.cardStatusMember,
  };
  final engagementText = switch (engagement) {
    Engagement.active => l10n.cardEngagementActive(g),
    Engagement.dormant => l10n.cardEngagementDormant,
    Engagement.unknown || null => null,
  };
  return engagementText == null
      ? statusText
      : l10n.cardStatusWithEngagement(statusText, engagementText);
}
