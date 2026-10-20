import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_content.dart';
import 'mock_data.dart';

/// État modifiable des mocks du profil (lot 6), gardé en mémoire jusqu'au
/// redémarrage de l'application : fiche, parcours, profil pro, réglages.
class MockProfileStore {
  final _me = <MockPersona, Map<String, Object?>>{};
  final _educations = <MockPersona, List<Map<String, Object?>>>{};
  final _profile = <MockPersona, Map<String, Object?>>{};
  final _preferences = <MockPersona, Map<String, bool>>{};
  final _notifications = <MockPersona, List<Map<String, Object?>>>{};
  var _nextId = 500;

  static T _copy<T>(T json) => jsonDecode(jsonEncode(json)) as T;

  int nextId() => _nextId++;

  /// Centre de notifications : l'état « lu » change quand on le marque.
  List<Map<String, Object?>> notifications(MockPersona persona) =>
      _notifications.putIfAbsent(
        persona,
        () => persona.notificationsJson(DateTime.now()),
      );

  Map<String, Object?> me(MockPersona persona) =>
      _me.putIfAbsent(persona, () => _copy(persona.meJson));

  List<Map<String, Object?>> educations(MockPersona persona) =>
      _educations.putIfAbsent(
        persona,
        () => [
          {
            'id': nextId(),
            'level': 'licence',
            'school': 'Université de test',
            'field_of_study': 'Filière de test',
            'diploma': null,
            'start_year': 2023,
            'end_year': null,
          },
          {
            'id': nextId(),
            'level': 'terminale',
            'school': 'Lycée de test',
            'field_of_study': 'Série de test',
            'diploma': 'Baccalauréat',
            'start_year': 2020,
            'end_year': 2023,
          },
        ],
      );

  Map<String, Object?> profile(MockPersona persona) => _profile.putIfAbsent(
    persona,
    () => _copy(persona.professionalProfileJson),
  );

  Map<String, bool> preferences(MockPersona persona) =>
      _preferences.putIfAbsent(
        persona,
        () => {
          for (final category in [
            'events',
            'meetings',
            'contributions',
            'news',
            'opportunities',
            'announcements',
          ])
            category: true,
        },
      );
}

/// `GET /education-levels` (liste tenue par le bureau ; valeurs factices).
const mockEducationLevelsJson = <Map<String, Object?>>[
  {'value': 'terminale', 'label': 'Terminale'},
  {'value': 'bts', 'label': 'BTS / formation professionnelle'},
  {'value': 'licence', 'label': 'Licence'},
  {'value': 'master', 'label': 'Master'},
  {'value': 'doctorat', 'label': 'Doctorat'},
  {'value': 'autre', 'label': 'Autre'},
];

final mockProfileStoreProvider = Provider<MockProfileStore>(
  (ref) => MockProfileStore(),
);
