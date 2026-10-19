import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/l10n/enum_labels.dart';
import 'package:aeenci_app/l10n/generated/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsFr();

  test('chaque valeur a un libellé non vide', () {
    final labels = <String>[
      for (final v in Gender.values) v.label(l10n),
      for (final v in AdmissionState.values) v.label(l10n),
      for (final v in MemberStatus.values) v.label(l10n),
      for (final v in Engagement.values) v.label(l10n),
      for (final v in MemberCategory.values) v.label(l10n),
      for (final v in ShowcaseStatus.values) v.label(l10n),
      for (final v in ContributionState.values) v.label(l10n),
      for (final v in PaymentPurpose.values) v.label(l10n),
      for (final v in PaymentMethod.values) v.label(l10n),
      for (final v in MobileMoneyOperator.values) v.label(l10n),
      for (final v in EventType.values) v.label(l10n),
      for (final v in AttendanceState.values) v.label(l10n),
      for (final v in NotificationCategory.values) v.label(l10n),
      for (final v in OpportunityType.values) v.label(l10n),
      for (final v in ApplyMethod.values) v.label(l10n),
      for (final v in ScanOutcome.values) v.label(l10n),
    ];
    expect(labels.where((l) => l.trim().isEmpty), isEmpty);
  });

  test('exemples', () {
    expect(MemberCategory.youngProfessional.label(l10n), 'Jeune professionnel');
    expect(PaymentMethod.mtnMomo.label(l10n), 'MTN MoMo');
    expect(Engagement.dormant.label(l10n), 'En sourdine');
    expect(MemberStatus.unknown.label(l10n), 'Non précisé');
  });
}
