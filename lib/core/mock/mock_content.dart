// Contenus factices de l'accueil et de la carte (lot 3), conformes au
// contrat v3. Les dates sont calculées par rapport à [now] pour que la
// démonstration reste cohérente quel que soit le jour.

import '../utils/academic_year.dart';
import 'mock_data.dart';

String _iso(DateTime date) => date.toUtc().toIso8601String();

String _day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Map<String, Object?> _page(
  List<Map<String, Object?>> items, [
  Map<String, Object?> extra = const {},
]) => {
  'data': items,
  'meta': {
    'current_page': 1,
    'last_page': 1,
    'per_page': 20,
    'total': items.length,
    ...extra,
  },
};

extension MockPersonaContent on MockPersona {
  /// `GET /me/card`. Le contenu du QR code est factice : il ne vérifie
  /// aucune signature (mocks seulement ; l'application ne fabrique jamais
  /// de QR code à partir de l'API).
  Map<String, Object?> cardJson(DateTime now) => {
    'member_number': meJson['member_number'],
    'full_name': '${meJson['first_names']} ${meJson['last_name']}',
    'photo_url': null,
    'status': meJson['status'],
    'engagement': meJson['engagement'],
    'category': meJson['category'],
    'joined_at': meJson['joined_at'],
    'qr_payload': 'AEENCI1.donnees-factices-$name.signature-factice',
    'qr_expires_at': _iso(now.add(const Duration(days: 30))),
  };

  /// `GET /me/contributions` : l'année en cours puis la précédente.
  Map<String, Object?> contributionsJson(DateTime now) {
    final current = academicYearOf(now);
    final previous = academicYearOf(DateTime(now.year - 1, now.month));
    return {
      'data': [
        if (this == MockPersona.bureau)
          {
            'year': current,
            'due_amount': 10000,
            'paid_amount': 10000,
            'state': 'paid',
          }
        else
          {
            'year': current,
            'due_amount': 6000,
            'paid_amount': 2000,
            'state': 'partial',
          },
        {
          'year': previous,
          'due_amount': 6000,
          'paid_amount': 6000,
          'state': 'paid',
        },
      ],
    };
  }

  /// `GET /me/payments` : acompte de l'année en cours, année précédente,
  /// droit d'adhésion. Du plus récent au plus ancien.
  List<Map<String, Object?>> paymentsJson(DateTime now) {
    final current = academicYearOf(now);
    final previous = academicYearOf(DateTime(now.year - 1, now.month));
    final bureau = this == MockPersona.bureau;
    return [
      {
        'id': memberId * 10 + 3,
        'receipt_number': 'REC-${now.year}-${memberId}03',
        'paid_on': _day(now.subtract(const Duration(days: 12))),
        'purpose': 'contribution',
        'contribution_year': current,
        'amount': bureau ? 10000 : 2000,
        'method': 'wave',
      },
      {
        'id': memberId * 10 + 2,
        'receipt_number': 'REC-${now.year - 1}-${memberId}02',
        'paid_on': _day(now.subtract(const Duration(days: 300))),
        'purpose': 'contribution',
        'contribution_year': previous,
        'amount': 6000,
        'method': 'orange_money',
      },
      {
        'id': memberId * 10 + 1,
        'receipt_number': 'REC-${now.year - 1}-${memberId}01',
        'paid_on': meJson['joined_at'],
        'purpose': 'admission',
        'contribution_year': null,
        'amount': 2000,
        'method': 'cash',
      },
    ];
  }

  /// `GET /me/registrations` : une inscription à venir, une passée.
  Map<String, Object?> registrationsJson(DateTime now) => {
    'data': [
      {
        'id': 6,
        'event': {
          'slug': 'evenement-test-a-venir',
          'type': 'joe',
          'title': 'JOE de test',
          'starts_at': _iso(now.add(const Duration(days: 12, hours: 2))),
          'location': 'Lieu de test',
        },
        'created_at': _iso(now.subtract(const Duration(days: 3))),
        'can_cancel': true,
      },
      {
        'id': 5,
        'event': {
          'slug': 'evenement-test-passe',
          'type': 'other',
          'title': 'Événement passé de test',
          'starts_at': _iso(now.subtract(const Duration(days: 40))),
          'location': null,
        },
        'created_at': _iso(now.subtract(const Duration(days: 60))),
        'can_cancel': false,
      },
    ],
  };

  /// `GET /me/opportunities` (première page).
  Map<String, Object?> opportunitiesPageJson(DateTime now) => _page(
    [
      {
        'id': 40,
        'type': 'job',
        'title': 'Offre d\'emploi de test',
        'organization': 'Organisation Test',
        'location': 'Abidjan',
        'deadline': _day(now.add(const Duration(days: 20))),
        'received_at': _iso(now.subtract(const Duration(days: 1))),
        'seen': false,
        'interested': false,
      },
      {
        'id': 39,
        'type': 'internship',
        'title': 'Stage de test',
        'organization': 'Entreprise Test',
        'location': null,
        'deadline': null,
        'received_at': _iso(now.subtract(const Duration(days: 4))),
        'seen': false,
        'interested': false,
      },
    ],
    {'unseen_count': 2},
  );

  /// `GET /me/profile` : le membre n'a pas encore de CV (rappel affiché),
  /// le membre du bureau a un profil complet.
  Map<String, Object?> get professionalProfileJson => this == MockPersona.bureau
      ? {
          'headline': 'Titre de test',
          'domain': 'Informatique',
          'city': 'Abidjan',
          'summary': null,
          'skills': ['Compétence A', 'Compétence B'],
          'languages': <Object?>[],
          'experiences': <Object?>[],
          'portfolio': <Object?>[],
          'cv_url': 'https://api.aeenci.com/api/v1/me/profile/cv',
          'linkedin_url': null,
          'is_public': false,
          'showcase_status': 'private',
          'consented_at': null,
        }
      : {
          'headline': null,
          'domain': null,
          'city': null,
          'summary': null,
          'skills': <Object?>[],
          'languages': <Object?>[],
          'experiences': <Object?>[],
          'portfolio': <Object?>[],
          'cv_url': null,
          'linkedin_url': null,
          'is_public': false,
          'showcase_status': 'private',
          'consented_at': null,
        };

  /// `GET /me/notifications` (première page) : deux non lues.
  Map<String, Object?> notificationsPageJson(DateTime now) => _page(
    [
      {
        'id': 3,
        'category': 'events',
        'title': 'Notification de test',
        'body': 'Texte de test.',
        'route': '/evenements/evenement-test-a-venir',
        'read_at': null,
        'created_at': _iso(now.subtract(const Duration(hours: 2))),
      },
      {
        'id': 2,
        'category': 'opportunities',
        'title': 'Notification de test',
        'body': 'Texte de test.',
        'route': '/opportunites/40',
        'read_at': null,
        'created_at': _iso(now.subtract(const Duration(days: 1))),
      },
      {
        'id': 1,
        'category': 'account',
        'title': 'Notification de test lue',
        'body': 'Texte de test.',
        'route': null,
        'read_at': _iso(now.subtract(const Duration(days: 2))),
        'created_at': _iso(now.subtract(const Duration(days: 3))),
      },
    ],
    {'unread_count': 2},
  );
}

/// `GET /meetings/next` : le samedi suivant.
Map<String, Object?> mockNextMeetingJson(DateTime now) {
  final daysToSaturday = (DateTime.saturday - now.weekday) % 7;
  final date = DateTime(
    now.year,
    now.month,
    now.day + (daysToSaturday == 0 ? 7 : daysToSaturday),
  );
  return {
    'data': {'date': _day(date), 'location': 'Lieu de l\'assemblée (test)'},
  };
}

/// `GET /news` (première page).
Map<String, Object?> mockNewsPageJson(DateTime now) => _page([
  for (var i = 1; i <= 3; i++)
    {
      'id': i,
      'slug': 'actualite-test-$i',
      'title': 'Actualité de test n° $i',
      'excerpt': 'Chapeau de test.',
      'body': 'Texte **de test**.',
      'image_url': null,
      'published_at': _iso(now.subtract(Duration(days: i * 3))),
    },
]);

/// `GET /events?upcoming=1` : un événement de chaque type, dont un aux
/// inscriptions fermées. Le premier correspond à l'inscription factice.
List<Map<String, Object?>> mockUpcomingEventsJson(DateTime now) => [
  {
    'id': 10,
    'slug': 'evenement-test-a-venir',
    'type': 'joe',
    'title': 'JOE de test',
    'summary': 'Résumé de test de la journée.',
    'description': 'Description de test de la journée d\'orientation.',
    'edition': now.year,
    'starts_at': _iso(now.add(const Duration(days: 12, hours: 2))),
    'ends_at': _iso(now.add(const Duration(days: 12, hours: 8))),
    'location': 'Lieu de test',
    'audience': 'Ouvert à tous',
    'image_url': null,
    'registration_open': true,
    'attendees_count': null,
  },
  {
    'id': 11,
    'slug': 'journee-emploi-test',
    'type': 'employment_day',
    'title': 'Journée de l\'emploi de test',
    'summary': 'Résumé de test.',
    'description': 'Description de test de la journée de l\'emploi.',
    'edition': now.year,
    'starts_at': _iso(now.add(const Duration(days: 20, hours: 1))),
    'ends_at': null,
    'location': 'Autre lieu de test',
    'audience': 'Membres et partenaires',
    'image_url': null,
    'registration_open': true,
    'attendees_count': null,
  },
  {
    'id': 12,
    'slug': 'impact-test',
    'type': 'impact',
    'title': 'Programme Impact de test',
    'summary': 'Résumé de test.',
    'description': 'Description de test du programme.',
    'edition': null,
    'starts_at': _iso(now.add(const Duration(days: 30))),
    'ends_at': null,
    'location': null,
    'audience': null,
    'image_url': null,
    'registration_open': true,
    'attendees_count': null,
  },
  {
    'id': 13,
    'slug': 'evenement-ferme-test',
    'type': 'other',
    'title': 'Événement de test complet',
    'summary': 'Résumé de test.',
    'description': 'Les inscriptions de cet événement de test sont fermées.',
    'edition': null,
    'starts_at': _iso(now.add(const Duration(days: 8))),
    'ends_at': null,
    'location': 'Lieu de test',
    'audience': null,
    'image_url': null,
    'registration_open': false,
    'attendees_count': null,
  },
];

/// `GET /me/attendances?months=12` : une assemblée par mois, sauf un mois
/// sans assemblée (case neutre). Du plus ancien au plus récent.
List<Map<String, Object?>> mockAttendancesJson(DateTime now) {
  const pattern = [
    'present',
    'absent',
    'present',
    'excused',
    'present',
    'absent',
    null,
    'present',
    'absent',
    'absent',
    'present',
    'absent',
  ];
  return [
    for (var i = 0; i < 12; i++)
      if (pattern[i] case final String state)
        {
          'date': _day(
            DateTime(
              now.year,
              now.month - 11 + i,
              1,
            ).add(const Duration(days: 14)),
          ),
          'state': state,
        },
  ];
}
