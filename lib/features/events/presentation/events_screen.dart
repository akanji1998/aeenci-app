import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/event.dart';
import '../domain/events_rules.dart';
import 'events_providers.dart';
import 'widgets/attendance_card.dart';
import 'widgets/event_actions.dart';
import 'widgets/event_card.dart';

enum _EventsView { upcoming, mine, attendance }

/// Événements (maquette `app-evenements`) : à venir, mes inscriptions,
/// présences aux assemblées.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  _EventsView _view = _EventsView.upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.eventsTitle,
                      style: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  SegmentedButton<_EventsView>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _EventsView.upcoming,
                        label: Text(l10n.eventsViewUpcoming),
                      ),
                      ButtonSegment(
                        value: _EventsView.mine,
                        label: Text(l10n.eventsViewMine),
                      ),
                      ButtonSegment(
                        value: _EventsView.attendance,
                        label: Text(l10n.eventsViewAttendance),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (selection) =>
                        setState(() => _view = selection.single),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_view) {
                _EventsView.upcoming => const _UpcomingView(),
                _EventsView.mine => const _MineView(),
                _EventsView.attendance => const _AttendanceView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingView extends ConsumerWidget {
  const _UpcomingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = ref.watch(eventTypeFilterProvider);
    final events = ref.watch(upcomingEventsProvider(type));
    final registrations =
        ref.watch(myRegistrationsProvider).value?.data ?? const [];
    final filters = <(EventType?, String)>[
      (null, l10n.eventsFilterAll),
      (EventType.joe, l10n.eventTypeJoe),
      (EventType.employmentDay, l10n.eventTypeEmploymentDay),
      (EventType.impact, l10n.eventTypeImpact),
      (EventType.other, l10n.eventTypeOther),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            children: [
              for (final (value, label) in filters)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space2),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: type == value,
                    shape: const StadiumBorder(),
                    onSelected: (_) => ref
                        .read(eventTypeFilterProvider.notifier)
                        .select(value),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Event>>(
            value: events,
            onRetry: () => ref.invalidate(upcomingEventsProvider(type)),
            builder: (context, list) => RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(upcomingEventsProvider(type))
                  ..invalidate(myRegistrationsProvider);
                await ref
                    .read(upcomingEventsProvider(type).future)
                    .then<void>((_) {}, onError: (Object _) {});
              },
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                          icon: LucideIcons.calendarX,
                          title: l10n.eventsEmptyTitle,
                          message: type == null
                              ? l10n.eventsEmptyMessage
                              : l10n.eventsEmptyFiltered,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space4,
                        AppSpacing.space1,
                        AppSpacing.space4,
                        AppSpacing.space8,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.space4),
                      itemBuilder: (context, index) => EventCard(
                        event: list[index],
                        registration: registrationFor(
                          registrations,
                          list[index].slug,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MineView extends ConsumerWidget {
  const _MineView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    return AsyncView<List<Registration>>(
      value: ref.watch(myRegistrationsProvider),
      onRetry: () => ref.invalidate(myRegistrationsProvider),
      builder: (context, all) {
        final upcoming = upcomingRegistrations(all, now);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myRegistrationsProvider);
            await ref
                .read(myRegistrationsProvider.future)
                .then<void>((_) {}, onError: (Object _) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space1,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              if (upcoming.isEmpty)
                EmptyState(
                  icon: LucideIcons.calendarCheck,
                  title: l10n.mineEmptyTitle,
                  message: l10n.mineEmptyMessage,
                )
              else
                for (final registration in upcoming) ...[
                  _RegistrationTile(registration: registration),
                  const SizedBox(height: AppSpacing.space3),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _RegistrationTile extends ConsumerWidget {
  const _RegistrationTile({required this.registration});

  final Registration registration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final event = registration.event;
    final start = event.startsAt.toLocal();
    final month = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(start).replaceAll(RegExp(r'\d'), '').trim();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      onTap: () => context.go(AppRoutes.eventDetail(event.slug)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.space3,
        runSpacing: AppSpacing.space2,
        children: [
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: MaterialLocalizations.of(
                    context,
                  ).formatFullDate(start),
                  excludeSemantics: true,
                  child: Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: c.green,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${start.day}',
                          style: AppTypography.h3.toTextStyle(color: c.onGreen),
                        ),
                        Text(
                          month,
                          style: AppTypography.label.toTextStyle(
                            color: c.onGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: context.textTheme.titleMedium),
                        if (event.location != null)
                          Text(
                            event.location!,
                            style: context.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (registration.canCancel)
            OutlinedButton(
              style:
                  OutlinedButton.styleFrom(
                    foregroundColor: c.ink,
                    minimumSize: const Size(48, 48),
                  ).copyWith(
                    side: WidgetStatePropertyAll(
                      BorderSide(color: c.line, width: 1.5),
                    ),
                  ),
              onPressed: () => cancelRegistration(context, ref, registration),
              child: Text(l10n.eventCancel),
            ),
        ],
      ),
    );
  }
}

class _AttendanceView extends ConsumerWidget {
  const _AttendanceView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<Attendance>>(
      value: ref.watch(attendancesProvider),
      onRetry: () => ref.invalidate(attendancesProvider),
      builder: (context, attendances) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendancesProvider);
          await ref
              .read(attendancesProvider.future)
              .then<void>((_) {}, onError: (Object _) {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space1,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [AttendanceCard(attendances: attendances)],
        ),
      ),
    );
  }
}
