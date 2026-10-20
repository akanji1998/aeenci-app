import '../../../core/domain/enums.dart';
import 'event.dart';

/// Une case de la grille des présences : un mois et, s'il y a eu une
/// assemblée enregistrée, son état (`null` : case neutre).
typedef AttendanceMonth = ({DateTime month, AttendanceState? state});

/// Les 12 derniers mois, du plus ancien au mois courant. Un mois sans
/// assemblée enregistrée reste neutre : il ne compte pas comme absence.
List<AttendanceMonth> attendanceGrid(
  List<Attendance> attendances,
  DateTime now, {
  int months = 12,
}) {
  return [
    for (var i = months - 1; i >= 0; i--)
      () {
        final month = DateTime(now.year, now.month - i);
        final match = attendances
            .where(
              (a) => a.date.year == month.year && a.date.month == month.month,
            )
            .firstOrNull;
        return (month: month, state: match?.state);
      }(),
  ];
}

/// Nombre de présences de la période.
int presentCount(List<Attendance> attendances) =>
    attendances.where((a) => a.state == AttendanceState.present).length;

/// Seuil d'activité du cahier des charges : au moins 3 présences sur les
/// 12 derniers mois.
const activeThreshold = 3;

/// Inscription du membre à l'événement [slug], s'il y en a une.
Registration? registrationFor(List<Registration> all, String slug) =>
    all.where((r) => r.event.slug == slug).firstOrNull;

/// Inscriptions à venir, de la plus proche à la plus lointaine.
List<Registration> upcomingRegistrations(
  List<Registration> all,
  DateTime now,
) => [
  for (final r in all)
    if (r.event.startsAt.isAfter(now)) r,
]..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));
