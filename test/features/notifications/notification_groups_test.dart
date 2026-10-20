import 'package:aeenci_app/core/push/push_providers.dart';
import 'package:aeenci_app/features/notifications/domain/notification_groups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 20, 9, 30);

  test('groupes par jour de calendrier', () {
    expect(groupOf(DateTime(2026, 10, 20, 0, 5), now), NotificationGroup.today);
    expect(
      groupOf(DateTime(2026, 10, 19, 23, 59), now),
      NotificationGroup.yesterday,
    );
    expect(groupOf(DateTime(2026, 10, 18, 8), now), NotificationGroup.thisWeek);
    expect(groupOf(DateTime(2026, 10, 14, 8), now), NotificationGroup.thisWeek);
    expect(groupOf(DateTime(2026, 10, 13, 8), now), NotificationGroup.earlier);
    // Reçue « dans le futur » (horloge du téléphone en retard).
    expect(groupOf(DateTime(2026, 10, 20, 11), now), NotificationGroup.today);
  });

  test('changement d\'heure : hier reste hier', () {
    // Passage à l'heure d'hiver en Europe la nuit du 25 octobre.
    expect(
      groupOf(DateTime(2026, 10, 25, 1), DateTime(2026, 10, 26, 0, 30)),
      NotificationGroup.yesterday,
    );
  });

  test('routes des notifications : la table du contrat, sinon le centre', () {
    for (final route in [
      '/evenements/joe-2026',
      '/cotisations',
      '/opportunites/12',
      '/actualites/une-actualite',
      '/adhesion/suivi',
      '/profil/vitrine',
      '/carte',
      '/notifications',
    ]) {
      expect(safePushRoute(route), route);
    }
    for (final route in [
      null,
      '',
      'https://exemple.com',
      '//exemple.com/carte',
      '/opportunites/abc',
      '/profil/supprimer-mon-compte',
      '/dev/composants',
      '/carte?x=1',
    ]) {
      expect(safePushRoute(route), '/notifications');
    }
  });
}
