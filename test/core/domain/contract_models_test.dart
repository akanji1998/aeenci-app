import 'package:aeenci_app/core/api/paginated.dart';
import 'package:aeenci_app/core/domain/date_only.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/features/app_config/domain/app_config.dart';
import 'package:aeenci_app/features/auth/domain/auth_user.dart';
import 'package:aeenci_app/features/auth/domain/invitation.dart';
import 'package:aeenci_app/features/auth/domain/membership_application.dart';
import 'package:aeenci_app/features/card/domain/member_card.dart';
import 'package:aeenci_app/features/contributions/domain/contact_info.dart';
import 'package:aeenci_app/features/contributions/domain/contribution.dart';
import 'package:aeenci_app/features/events/domain/event.dart';
import 'package:aeenci_app/features/news/domain/news.dart';
import 'package:aeenci_app/features/notifications/domain/app_notification.dart';
import 'package:aeenci_app/features/opportunities/domain/opportunity.dart';
import 'package:aeenci_app/features/profile/domain/education.dart';
import 'package:aeenci_app/features/profile/domain/member.dart';
import 'package:aeenci_app/features/profile/domain/professional_profile.dart';
import 'package:aeenci_app/features/scan/domain/attendance_scan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('compte', () {
    test('réponse de connexion', () {
      final session = AuthSession.fromJson(fixture('auth_login'));
      expect(session.token, '1|jeton-de-test');
      expect(session.user.memberId, 10);
      expect(session.user.roles, ['member']);
      expect(session.user.abilities, isEmpty);
    });

    test('utilisateur sans fiche ni listes', () {
      final user = AuthUser.fromJson({
        'id': 2,
        'email': 'admin.test@exemple.com',
      });
      expect(user.memberId, isNull);
      expect(user.abilities, isEmpty);
    });

    test('invitation', () {
      final invitation = Invitation.fromJson(fixture('invitation'));
      expect(invitation.firstNames, 'Prénom Test');
      expect(invitation.expiresAt, DateTime.utc(2026, 10, 25, 23, 59, 59));
    });

    test('suivi de l\'adhésion refusée', () {
      final application = MembershipApplication.fromJson(
        fixtureData('membership_application'),
      );
      expect(application.state, AdmissionState.rejected);
      expect(application.decisionReason, isNotNull);
    });
  });

  group('fiche', () {
    test('membre admis', () {
      final member = Member.fromJson(fixtureData('me'));
      expect(member.memberNumber, 'TEST-0001');
      expect(member.birthDate, DateTime(2004, 5, 17));
      expect(member.category, MemberCategory.youngProfessional);
      expect(member.status, MemberStatus.member);
      expect(member.engagement, Engagement.active);
      expect(member.joinedAt, DateTime(2025, 10, 4));
      expect(member.isAdmitted, isTrue);
      expect(member.can(Abilities.attendanceScan), isTrue);
    });

    test('candidat : champs nuls avant validation', () {
      final candidate = Member.fromJson(fixtureData('me_candidate'));
      expect(candidate.memberNumber, isNull);
      expect(candidate.status, isNull);
      expect(candidate.joinedAt, isNull);
      expect(candidate.isAdmitted, isFalse);
      expect(candidate.can(Abilities.attendanceScan), isFalse);
    });

    test('valeur d\'énumération inconnue → unknown', () {
      final json = {
        ...fixtureData('me'),
        'category': 'nouvelle_categorie',
        'status': 'autre',
      };
      final member = Member.fromJson(json);
      expect(member.category, MemberCategory.unknown);
      expect(member.status, MemberStatus.unknown);
    });

    test('parcours scolaire et niveaux', () {
      final education = Education.fromJson(fixtureList('educations').single);
      expect(education.fieldOfStudy, 'Informatique');
      expect(education.endYear, isNull);
      final levels = fixtureList(
        'education_levels',
      ).map(EducationLevel.fromJson);
      expect(levels.map((l) => l.value), ['terminale', 'licence']);
    });

    test('profil professionnel', () {
      final profile = ProfessionalProfile.fromJson(fixtureData('profile'));
      expect(profile.skills, ['Flutter', 'SQL']);
      expect(profile.languages.last.level, isNull);
      expect(profile.experiences.single.endedOn, DateTime(2025, 8, 31));
      expect(profile.portfolio.single.url, 'https://exemple.com/projet');
      expect(profile.showcaseStatus, ShowcaseStatus.pending);
      expect(profile.isPublic, isTrue);
    });

    test('profil vide : listes par défaut', () {
      final profile = ProfessionalProfile.fromJson({
        'is_public': false,
        'showcase_status': 'private',
      });
      expect(profile.skills, isEmpty);
      expect(profile.experiences, isEmpty);
      expect(profile.showcaseStatus, ShowcaseStatus.private);
    });

    test('une expérience se renvoie avec des dates sans heure', () {
      final experience = ProfessionalProfile.fromJson(
        fixtureData('profile'),
      ).experiences.single;
      final json = experience.toJson();
      expect(json['started_on'], '2025-06-01');
      expect(json['ended_on'], '2025-08-31');
      expect(json.containsKey('startedOn'), isFalse);
    });
  });

  group('cotisations', () {
    test('situation par année', () {
      final contributions = fixtureList(
        'contributions',
      ).map(Contribution.fromJson).toList();
      expect(contributions.first.state, ContributionState.partial);
      expect(contributions.first.remainingAmount, 5000);
      expect(contributions.last.remainingAmount, 0);
    });

    test('paiements paginés', () {
      final page = Paginated.fromJson(fixture('payments'), Payment.fromJson);
      expect(page.items.first.method, PaymentMethod.orangeMoney);
      expect(page.items.first.paidOn, DateTime(2026, 10, 2));
      expect(page.items.last.purpose, PaymentPurpose.admission);
      expect(page.items.last.contributionYear, isNull);
    });

    test('coordonnées et Mobile Money', () {
      final contact = ContactInfo.fromJson(fixtureData('contact'));
      expect(contact.mobileMoney.single.operator, MobileMoneyOperator.wave);
      expect(contact.mobileMoney.single.accountName, 'Compte de test');
      expect(contact.socialLinks.single.network, 'facebook');
    });
  });

  group('événements', () {
    test('événement', () {
      final event = Event.fromJson(fixtureList('events').single);
      expect(event.type, EventType.employmentDay);
      expect(event.startsAt, DateTime.utc(2026, 11, 14, 9));
      expect(event.registrationOpen, isTrue);
      expect(event.endsAt, isNull);
    });

    test('inscription', () {
      final registration = Registration.fromJson(
        fixtureList('registrations').single,
      );
      expect(registration.event.type, EventType.joe);
      expect(registration.canCancel, isTrue);
    });

    test('présences et prochaine assemblée', () {
      final attendances = fixtureList('attendances').map(Attendance.fromJson);
      expect(attendances.map((a) => a.state), [
        AttendanceState.present,
        AttendanceState.excused,
      ]);
      final meeting = NextMeeting.fromJson(fixtureData('next_meeting'));
      expect(meeting.location, 'Lieu de test');
    });
  });

  test('actualité', () {
    final page = Paginated.fromJson(fixture('news'), News.fromJson);
    expect(page.items.single.body, contains('**de test**'));
  });

  test('configuration de l\'application', () {
    final config = AppConfig.fromJson(fixtureData('app_config'));
    expect(config.minVersion, '1.0.0');
    expect(config.storeUrls.android, contains('com.aeenci.app'));
    expect(config.maintenance, isFalse);
    expect(config.cardPublicKey, isNotEmpty);
  });

  test('carte de membre : qr_payload gardé tel quel', () {
    final card = MemberCard.fromJson(fixtureData('card'));
    expect(card.qrPayload, 'AEENCI1.eyJtaWQiOjEwfQ.c2lnbmF0dXJlLWRlLXRlc3Q');
    expect(card.engagement, Engagement.dormant);
    expect(card.joinedAt, DateTime(2025, 10, 4));
    expect(card.qrExpiresAt.isUtc, isTrue);
  });

  group('scan', () {
    test('assemblées à scanner', () {
      final meeting = AttendanceMeeting.fromJson(
        fixtureList('attendance_meetings').single,
      );
      expect(meeting.scannedCount, 3);
      expect(meeting.date, DateTime(2026, 10, 18));
    });

    test('envoi groupé au format du contrat', () {
      final batch = ScanBatch(
        meetingId: 12,
        scans: [
          Scan(
            qrPayload: 'AEENCI1.a.b',
            scannedAt: DateTime.utc(2026, 10, 18, 10, 2, 11),
          ),
        ],
      );
      expect(batch.toJson(), {
        'meeting_id': 12,
        'scans': [
          {
            'qr_payload': 'AEENCI1.a.b',
            'scanned_at': '2026-10-18T10:02:11.000Z',
          },
        ],
      });
    });

    test('résultats par carte', () {
      final results = [
        for (final r in fixture('scan_results')['results'] as List<dynamic>)
          ScanResult.fromJson(r as Map<String, dynamic>),
      ];
      expect(results.map((r) => r.outcome), [
        ScanOutcome.recorded,
        ScanOutcome.alreadyRecorded,
        ScanOutcome.invalid,
        ScanOutcome.notMember,
      ]);
      expect(results.first.member!.memberNumber, 'TEST-0001');
      expect(results[2].member, isNull);
      expect(results[3].member, isNull);
    });
  });

  group('notifications', () {
    test('centre de notifications et compteur', () {
      final page = Paginated.fromJson(
        fixture('notifications'),
        AppNotification.fromJson,
      );
      expect(page.count('unread_count'), 1);
      expect(page.items.first.isRead, isFalse);
      expect(page.items.first.route, '/evenements/evenement-test');
      expect(page.items.last.category, NotificationCategory.account);
    });

    test('préférences', () {
      final prefs = fixtureList(
        'notification_preferences',
      ).map(NotificationPreference.fromJson).toList();
      expect(prefs.first.locked, isTrue);
      expect(prefs.last.enabled, isFalse);
    });

    test('enregistrement du téléphone', () {
      const device = DeviceRegistration(
        token: 'fcm',
        platform: DevicePlatform.android,
        appVersion: '1.0.0',
      );
      expect(device.toJson(), {
        'token': 'fcm',
        'platform': 'android',
        'app_version': '1.0.0',
        'locale': 'fr',
      });
    });
  });

  group('opportunités', () {
    test('liste et nombre de nouvelles', () {
      final page = Paginated.fromJson(
        fixture('opportunities'),
        Opportunity.fromJson,
      );
      expect(page.count('unseen_count'), 1);
      expect(page.items.single.type, OpportunityType.internship);
      expect(page.items.single.deadline, DateTime(2026, 11, 30));
    });

    test('détail : critères de correspondance', () {
      final detail = OpportunityDetail.fromJson(
        fixtureData('opportunity_detail'),
      );
      expect(detail.applyMethod, ApplyMethod.viaBureau);
      expect(detail.matchedOn.cities, ['Abidjan']);
      expect(detail.matchedOn.categories, [
        MemberCategory.student,
        MemberCategory.unknown,
      ]);
      expect(detail.deadline, isNull);
    });
  });

  group('DateOnlyConverter', () {
    const converter = DateOnlyConverter();

    test('date sans heure → minuit local, sans décalage', () {
      final date = converter.fromJson('2026-01-01');
      expect([date.year, date.month, date.day, date.hour], [2026, 1, 1, 0]);
      expect(date.isUtc, isFalse);
    });

    test('aller-retour', () {
      expect(converter.toJson(converter.fromJson('2026-10-13')), '2026-10-13');
      expect(converter.toJson(DateTime(987, 3, 4)), '0987-03-04');
    });

    test('accepte une date-heure', () {
      final date = converter.fromJson('2026-10-13T12:00:00+00:00');
      expect(date.day, 13);
    });
  });
}
