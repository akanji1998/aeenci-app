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
    MockPersona.bureau => 'bureau.test@exemple.com',
  };

  /// Jeton factice : les dépôts mock en déduisent le compte connecté.
  String get token => 'mock-$name-token';

  int get memberId => switch (this) {
    MockPersona.member => 101,
    MockPersona.candidate => 102,
    MockPersona.bureau => 103,
  };

  List<String> get abilities =>
      this == MockPersona.bureau ? const ['attendance.scan'] : const [];

  Map<String, Object?> get userJson => {
    'id': memberId + 900,
    'email': email,
    'roles': switch (this) {
      MockPersona.member => ['member'],
      MockPersona.candidate => ['candidate'],
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

  /// `GET /membership-application` (candidat seulement).
  Map<String, Object?> get membershipApplicationJson => {
    'id': 1,
    'state': this == MockPersona.candidate ? 'pending' : 'approved',
    'submitted_at': '2026-10-01T09:00:00+00:00',
    'reviewed_at': this == MockPersona.candidate
        ? null
        : '2026-10-04T09:00:00+00:00',
    'decision_reason': null,
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
