import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/features/events/domain/event.dart';
import 'package:aeenci_app/features/events/domain/events_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Attendance attendance(int year, int month, AttendanceState state) =>
    Attendance(date: DateTime(year, month, 25), state: state);

Registration registration(int id, String slug, DateTime startsAt) =>
    Registration(
      id: id,
      event: EventSummary(
        slug: slug,
        type: EventType.joe,
        title: slug,
        startsAt: startsAt,
      ),
      createdAt: DateTime.utc(2026),
      canCancel: true,
    );

void main() {
  group('grille des présences', () {
    final now = DateTime(2026, 10, 20);

    test('12 mois, du plus ancien au mois courant', () {
      final grid = attendanceGrid(const [], now);
      expect(grid, hasLength(12));
      expect(grid.first.month, DateTime(2025, 11));
      expect(grid.last.month, DateTime(2026, 10));
    });

    test('chaque mois prend l\'état de son assemblée, sinon reste neutre', () {
      final grid = attendanceGrid([
        attendance(2025, 11, AttendanceState.present),
        attendance(2026, 1, AttendanceState.excused),
        attendance(2026, 10, AttendanceState.absent),
      ], now);
      expect(grid[0].state, AttendanceState.present);
      expect(grid[1].state, isNull); // décembre : pas d'assemblée
      expect(grid[2].state, AttendanceState.excused);
      expect(grid[11].state, AttendanceState.absent);
    });

    test('changement d\'année', () {
      final grid = attendanceGrid(const [], DateTime(2026, 1, 5));
      expect(grid.first.month, DateTime(2025, 2));
      expect(grid.last.month, DateTime(2026));
    });
  });

  test('présences comptées', () {
    expect(
      presentCount([
        attendance(2026, 1, AttendanceState.present),
        attendance(2026, 2, AttendanceState.excused),
        attendance(2026, 3, AttendanceState.present),
        attendance(2026, 4, AttendanceState.absent),
      ]),
      2,
    );
  });

  group('inscriptions', () {
    final now = DateTime.utc(2026, 10, 20, 12);
    final all = [
      registration(1, 'passe', now.subtract(const Duration(days: 3))),
      registration(2, 'loin', now.add(const Duration(days: 30))),
      registration(3, 'proche', now.add(const Duration(days: 2))),
    ];

    test('inscription à un événement donné', () {
      expect(registrationFor(all, 'loin')!.id, 2);
      expect(registrationFor(all, 'absent'), isNull);
    });

    test('inscriptions à venir, de la plus proche à la plus lointaine', () {
      expect(upcomingRegistrations(all, now).map((r) => r.id), [3, 2]);
    });
  });
}
