import 'app_notification.dart';

/// Groupes du centre de notifications, du plus récent au plus ancien.
enum NotificationGroup { today, yesterday, thisWeek, earlier }

/// Groupe d'une notification reçue à [createdAt] (heure locale), vu à [now].
/// « Cette semaine » : les sept derniers jours.
NotificationGroup groupOf(DateTime createdAt, DateTime now) {
  final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final today = DateTime(now.year, now.month, now.day);
  // Différence en jours de calendrier (indépendante des changements d'heure).
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (days <= 0) return NotificationGroup.today;
  if (days == 1) return NotificationGroup.yesterday;
  if (days < 7) return NotificationGroup.thisWeek;
  return NotificationGroup.earlier;
}

/// Notifications rangées par groupe, dans l'ordre reçu (le plus récent
/// d'abord), sans groupe vide.
List<(NotificationGroup, List<AppNotification>)> groupNotifications(
  List<AppNotification> items,
  DateTime now,
) {
  final groups = <NotificationGroup, List<AppNotification>>{};
  for (final item in items) {
    groups
        .putIfAbsent(groupOf(item.createdAt.toLocal(), now), () => [])
        .add(item);
  }
  return [
    for (final group in NotificationGroup.values)
      if (groups[group] case final list?) (group, list),
  ];
}
