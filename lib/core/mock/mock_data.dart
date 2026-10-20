// Jeu de données factices, conforme au contrat v3, pour USE_MOCKS=true.
//
// Les données sont manifestement fictives (TEST, exemple.com, numéros en 00).
// Elles restent en JSON pour que les mocks passent par les mêmes fromJson
// que l'API.

/// Les trois comptes de démonstration.
enum MockPersona {
  /// Membre admis, sans rôle au bureau.
  member,

  /// Candidat dont la demande est en attente.
  candidate,

  /// Candidat dont la demande a été refusée.
  rejectedCandidate,

  /// Membre du bureau : peut scanner les présences.
  bureau,
}

/// Mot de passe de tous les comptes factices.
const mockPassword = 'motdepasse';

/// Compte de connexion sans fiche de membre (ex. administration seule).
const mockNoMemberEmail = 'admin.test@exemple.com';

extension MockPersonaData on MockPersona {
  String get email => switch (this) {
    MockPersona.member => 'membre.test@exemple.com',
    MockPersona.candidate => 'candidat.test@exemple.com',
    MockPersona.rejectedCandidate => 'candidat.refuse@exemple.com',
    MockPersona.bureau => 'bureau.test@exemple.com',
  };

  /// Jeton factice : les dépôts mock en déduisent le compte connecté.
  String get token => 'mock-$name-token';

  int get memberId => switch (this) {
    MockPersona.member => 101,
    MockPersona.candidate => 102,
    MockPersona.rejectedCandidate => 104,
    MockPersona.bureau => 103,
  };

  List<String> get abilities =>
      this == MockPersona.bureau ? const ['attendance.scan'] : const [];

  Map<String, Object?> get userJson => {
    'id': memberId + 900,
    'email': email,
    'roles': switch (this) {
      MockPersona.member => ['member'],
      MockPersona.candidate || MockPersona.rejectedCandidate => ['candidate'],
      MockPersona.bureau => ['member', 'secretary_general'],
    },
    'abilities': abilities,
    'member_id': memberId,
  };

  /// `GET /me`.
  Map<String, Object?> get meJson => switch (this) {
    MockPersona.member => {
      'id': memberId,
      'member_number': 'TEST-0001',
      'last_name': 'TEST',
      'first_names': 'Membre',
      'gender': 'female',
      'birth_date': '2004-05-17',
      'birth_place': 'Ville Test',
      'nationality': 'nigériane',
      'photo_url': null,
      'phone': '+225 00 00 00 00 01',
      'whatsapp': null,
      'email': email,
      'address': null,
      'city': 'Abidjan',
      'admission_state': 'approved',
      'status': 'member',
      'engagement': 'active',
      'category': 'student',
      'joined_at': '2025-10-04',
      'abilities': abilities,
    },
    MockPersona.candidate => {
      'id': memberId,
      'member_number': null,
      'last_name': 'TEST',
      'first_names': 'Candidat',
      'gender': 'male',
      'birth_date': '2008-01-02',
      'birth_place': 'Ville Test',
      'nationality': 'nigériane',
      'photo_url': null,
      'phone': '+225 00 00 00 00 02',
      'whatsapp': null,
      'email': email,
      'address': null,
      'city': 'Bouaké',
      'admission_state': 'pending',
      'status': null,
      'engagement': null,
      'category': 'student',
      'joined_at': null,
      'abilities': abilities,
    },
    MockPersona.rejectedCandidate => {
      ...MockPersona.candidate.meJson,
      'id': memberId,
      'first_names': 'Candidate',
      'gender': 'female',
      'email': email,
      'phone': '+225 00 00 00 00 04',
      'admission_state': 'rejected',
      'category': 'young_professional',
    },
    MockPersona.bureau => {
      'id': memberId,
      'member_number': 'TEST-0003',
      'last_name': 'TEST',
      'first_names': 'Bureau',
      'gender': 'male',
      'birth_date': '1999-11-30',
      'birth_place': 'Ville Test',
      'nationality': 'nigériane',
      'photo_url': null,
      'phone': '+225 00 00 00 00 03',
      'whatsapp': '+225 00 00 00 00 03',
      'email': email,
      'address': 'Adresse de test',
      'city': 'Abidjan',
      'admission_state': 'approved',
      'status': 'former',
      'engagement': 'active',
      'category': 'young_professional',
      'joined_at': '2023-10-07',
      'abilities': abilities,
    },
  };

  /// `GET /membership-application`.
  Map<String, Object?> get membershipApplicationJson => switch (this) {
    MockPersona.candidate => {
      'id': 2,
      'state': 'pending',
      'submitted_at': '2026-10-12T09:00:00+00:00',
      'reviewed_at': null,
      'decision_reason': null,
    },
    MockPersona.rejectedCandidate => {
      'id': 4,
      'state': 'rejected',
      'submitted_at': '2026-09-01T09:00:00+00:00',
      'reviewed_at': '2026-09-10T15:30:00+00:00',
      'decision_reason':
          'Motif de test : la pièce justificative du niveau d\'études manque.',
    },
    _ => {
      'id': 1,
      'state': 'approved',
      'submitted_at': '2025-09-28T09:00:00+00:00',
      'reviewed_at': '2025-10-04T09:00:00+00:00',
      'decision_reason': null,
    },
  };
}

/// Retrouve le compte factice d'un jeton, ou `null`.
MockPersona? mockPersonaForToken(String? token) {
  for (final persona in MockPersona.values) {
    if (persona.token == token) return persona;
  }
  return null;
}

/// Retrouve le compte factice d'une adresse e-mail, ou `null`.
MockPersona? mockPersonaForEmail(String email) {
  final normalized = email.trim().toLowerCase();
  for (final persona in MockPersona.values) {
    if (persona.email == normalized) return persona;
  }
  return null;
}

/// Jetons d'invitation (`GET /invitations/{token}`).
abstract final class MockInvitations {
  /// Valide : son acceptation ouvre la session du membre factice.
  static const valid = 'invitation-test';

  /// Expirée ou déjà utilisée : 410.
  static const expired = 'invitation-expiree';

  /// Tout autre jeton : 404.
  static const Map<String, Object?> validJson = {
    'first_names': 'Membre',
    'expires_at': '2030-01-01T00:00:00+00:00',
  };
}

/// Jeton de réinitialisation accepté par les mocks (avec un e-mail factice).
const mockResetToken = 'reinitialisation-test';

/// `GET /membership-fees`.
const mockMembershipFeesJson = <Map<String, Object?>>[
  {'category': 'student', 'amount': 2000},
  {'category': 'young_professional', 'amount': 5000},
  {'category': 'professional', 'amount': 10000},
];

/// `GET /site/contact`.
const mockContactJson = <String, Object?>{
  'email': 'contact@exemple.com',
  'phone': '+225 00 00 00 00 90',
  'whatsapp': null,
  'address': null,
  'mobile_money': [
    {
      'operator': 'orange_money',
      'number': '+225 00 00 00 00 91',
      'account_name': 'AEENCI (compte de test)',
    },
    {
      'operator': 'wave',
      'number': '+225 00 00 00 00 92',
      'account_name': 'AEENCI (compte de test)',
    },
  ],
  'social_links': <Object?>[],
};

/// `GET /app/config`. La clé ne vérifie aucune vraie carte.
Map<String, Object?> mockAppConfigJson({
  String minVersion = '1.0.0',
  bool maintenance = false,
}) => {
  'min_version': minVersion,
  'latest_version': '1.0.0',
  'store_urls': {
    'android': 'https://play.google.com/store/apps/details?id=com.aeenci.app',
    'ios': 'https://apps.apple.com/app/aeenci',
  },
  'maintenance': maintenance,
  'maintenance_message': maintenance
      ? 'Maintenance de test : le service revient dans quelques minutes.'
      : null,
  'card_public_key': 'cl\u00e9-de-test-non-valide',
  'support_email': 'contact@exemple.com',
};
