import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/enum_labels.dart';
import '../../../../core/utils/clock.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../../card/presentation/card_status_label.dart';
import '../../domain/event.dart';
import '../../domain/events_rules.dart';

/// Présences aux assemblées sur 12 mois (maquette `app-evenements`).
class AttendanceCard extends ConsumerWidget {
  const AttendanceCard({super.key, required this.attendances});

  final List<Attendance> attendances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final member = session is SessionMember ? session.member : null;
    final gender = member?.gender ?? Gender.unknown;
    final grid = attendanceGrid(attendances, ref.watch(clockProvider)());
    final count = presentCount(attendances);
    final engagement = member?.engagement;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              Text(l10n.attendanceTitle, style: context.textTheme.titleLarge),
              if (member?.status != null)
                _Badge(
                  text: cardStatusLabel(
                    l10n,
                    status: member!.status!,
                    engagement: engagement,
                    gender: gender,
                  ),
                  active: engagement == Engagement.active,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            l10n.attendanceSummary(
              count,
              activeThreshold,
              gender == Gender.female ? 'female' : 'other',
            ),
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space4),
          Semantics(
            label: l10n.attendanceGridLabel,
            container: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const columns = 6;
                const gap = AppSpacing.space2;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final cell in grid)
                      _MonthCell(
                        width: width,
                        month: cell.month,
                        state: cell.state,
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.space4,
              runSpacing: AppSpacing.space2,
              children: [
                for (final state in [
                  AttendanceState.present,
                  AttendanceState.excused,
                  AttendanceState.absent,
                  null,
                ])
                  _Legend(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground, Color? border}) _cellColors(
  AppColors c,
  AttendanceState? state,
) => switch (state) {
  AttendanceState.present => (
    background: c.green,
    foreground: c.onGreen,
    border: null,
  ),
  AttendanceState.excused => (
    background: c.blueSoft,
    foreground: c.blue,
    border: null,
  ),
  AttendanceState.absent || AttendanceState.unknown => (
    background: c.line,
    foreground: c.ink,
    border: null,
  ),
  // Mois sans assemblée : case neutre, bordée.
  null => (background: c.surface, foreground: c.inkMuted, border: c.line),
};

String _stateLabel(AppLocalizations l10n, AttendanceState? state) =>
    state == null ? l10n.attendanceNone : state.label(l10n);

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.width,
    required this.month,
    required this.state,
  });

  final double width;
  final DateTime month;
  final AttendanceState? state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _cellColors(context.colors, state);
    // Initiale du mois (« N », « D »…), d'après la langue de l'application.
    final initial = DateFormat('MMMMM', l10n.localeName).format(month);
    return Semantics(
      label: l10n.attendanceCell(month, _stateLabel(l10n, state)),
      excludeSemantics: true,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: colors.border == null
              ? null
              : Border.all(color: colors.border!),
        ),
        child: Text(
          initial,
          style: AppTypography.label.toTextStyle(color: colors.foreground),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.state});

  final AttendanceState? state;

  @override
  Widget build(BuildContext context) {
    final colors = _cellColors(context.colors, state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(3),
            border: colors.border == null
                ? null
                : Border.all(color: colors.border!),
          ),
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(
          _stateLabel(AppLocalizations.of(context), state),
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? c.greenSoft : c.line,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        child: Text(
          text,
          style: AppTypography.label.toTextStyle(
            color: active ? c.green : c.ink,
          ),
        ),
      ),
    );
  }
}
