import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/utils/academic_year.dart';
import 'package:aeenci_app/features/contributions/domain/contribution.dart';
import 'package:aeenci_app/features/events/domain/event.dart';
import 'package:aeenci_app/features/home/domain/home_rules.dart';
import 'package:aeenci_app/features/profile/domain/professional_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Contribution contribution(String year) => Contribution(
  year: year,
  dueAmount: 6000,
  paidAmount: 0,
  state: ContributionState.unpaid,
);

Registration registration(int id, DateTime startsAt) => Registration(
  id: id,
  event: EventSummary(
    slug: 'e$id',
    type: EventType.joe,
    title: 'E$id',
    startsAt: startsAt,
  ),
  createdAt: DateTime.utc(2026),
  canCancel: true,
);

void main() {
  group('année académique', () {
    test('de septembre à août', () {
      expect(academicYearOf(DateTime(2026, 9)), '2026-2027');
      expect(academicYearOf(DateTime(2026, 12, 31)), '2026-2027');
      expect(academicYearOf(DateTime(2027, 8, 31)), '2026-2027');
      expect(academicYearOf(DateTime(2026, 8, 31)), '2025-2026');
      expect(academicYearOf(DateTime(2026)), '2025-2026');
    });
  });

  group('cotisation de l\'année', () {
    test('celle de l\'année académique en cours', () {
      final all = [contribution('2025-2026'), contribution('2026-2027')];
      expect(
        currentContribution(all, DateTime(2026, 10, 20))!.year,
        '2026-2027',
      );
    });

    test('sinon la plus récente', () {
      final all = [contribution('2023-2024'), contribution('2024-2025')];
      expect(
        currentContribution(all, DateTime(2026, 10, 20))!.year,
        '2024-2025',
      );
    });

    test('aucune', () {
      expect(currentContribution(const [], DateTime(2026, 10, 20)), isNull);
    });
  });

  group('prochain événement', () {
    final now = DateTime.utc(2026, 10, 20, 12);

    test('le plus proche des événements à venir', () {
      final all = [
        registration(1, now.subtract(const Duration(days: 1))),
        registration(2, now.add(const Duration(days: 10))),
        registration(3, now.add(const Duration(days: 2))),
      ];
      expect(nextRegistration(all, now)!.id, 3);
    });

    test('aucun événement à venir', () {
      expect(
        nextRegistration([
          registration(1, now.subtract(const Duration(hours: 1))),
        ], now),
        isNull,
      );
    });
  });

  group('rappel du profil pro', () {
    ProfessionalProfile profile({String? cv, List<String> skills = const []}) =>
        ProfessionalProfile(
          isPublic: false,
          showcaseStatus: ShowcaseStatus.private,
          cvUrl: cv,
          skills: skills,
        );

    test('CV ou compétences manquants : rappel', () {
      expect(profileNeedsCompletion(profile()), isTrue);
      expect(profileNeedsCompletion(profile(cv: 'https://x/cv')), isTrue);
      expect(profileNeedsCompletion(profile(skills: ['Flutter'])), isTrue);
    });

    test('CV et compétences : pas de rappel', () {
      expect(
        profileNeedsCompletion(
          profile(cv: 'https://x/cv', skills: ['Flutter']),
        ),
        isFalse,
      );
    });
  });
}
