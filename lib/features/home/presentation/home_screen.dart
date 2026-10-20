import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/config/env_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/offline_banner.dart';
import '../../../core/design/components/skeleton.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../contributions/domain/contribution.dart';
import '../../events/domain/event.dart';
import '../../news/domain/news.dart';
import '../../news/presentation/widgets/news_card.dart';
import 'home_providers.dart';

/// Accueil (maquette `app-accueil`).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    for (final provider in homeBlockProviders) {
      ref.invalidate(provider);
    }
    // On attend la fin du rechargement, erreurs comprises.
    await Future.wait([
      for (final provider in [
        homeContributionProvider,
        homeNextRegistrationProvider,
        homeNextMeetingProvider,
        homeOpportunitiesProvider,
        homeProfileReminderProvider,
        homeNewsProvider,
      ])
        ref.read(provider.future).then<void>((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final member = session is SessionMember ? session.member : null;
    final firstName = member?.firstNames.split(RegExp(r'\s+')).first ?? '';
    final gender = member?.gender == Gender.female ? 'female' : 'other';
    final devTools = ref.watch(envConfigProvider).isDev;

    final blocks = <AsyncValue<Cached<Object?>>>[
      ref.watch(homeContributionProvider),
      ref.watch(homeNextRegistrationProvider),
      ref.watch(homeNextMeetingProvider),
      ref.watch(homeOpportunitiesProvider),
      ref.watch(homeProfileReminderProvider),
      ref.watch(homeNewsProvider),
    ];
    // Un seul bandeau : la plus ancienne mise à jour des blocs en cache.
    final offlineSince = blocks
        .map((block) => block.value?.offlineSince)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (oldest, date) =>
              oldest == null || date.isBefore(oldest) ? date : oldest,
        );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              _Header(firstName: firstName),
              if (member != null && member.can(Abilities.attendanceScan)) ...[
                const SizedBox(height: AppSpacing.space4),
                const _ScanCard(),
              ],
              if (offlineSince != null) ...[
                const SizedBox(height: AppSpacing.space3),
                OfflineBanner(updatedAt: offlineSince),
              ],
              const SizedBox(height: AppSpacing.space4),
              _Block(
                value: ref.watch(homeContributionProvider),
                onRetry: () => ref.invalidate(homeContributionProvider),
                builder: (contribution) => contribution == null
                    ? null
                    : _ContributionCard(contribution: contribution),
              ),
              _Upcoming(gender: gender),
              _Block(
                value: ref.watch(homeOpportunitiesProvider),
                onRetry: () => ref.invalidate(homeOpportunitiesProvider),
                // Gardée même sans nouvelle offre : c'est l'accès à la liste.
                builder: (data) =>
                    data.latest == null ? null : _OpportunitiesCard(data: data),
              ),
              _Block(
                value: ref.watch(homeProfileReminderProvider),
                onRetry: () => ref.invalidate(homeProfileReminderProvider),
                builder: (needed) => needed ? const _ProfileReminder() : null,
              ),
              _Block(
                value: ref.watch(homeNewsProvider),
                onRetry: () => ref.invalidate(homeNewsProvider),
                builder: (news) => news.isEmpty ? null : _NewsList(news: news),
              ),
              if (devTools)
                Center(
                  child: AppButton.text(
                    label: l10n.homeDevComponents,
                    onPressed: () => context.push(AppRoutes.devComponents),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un bloc : squelette, erreur compacte avec « Réessayer », ou contenu
/// (rien si [builder] renvoie `null`). Espacement sous le bloc inclus.
class _Block<T> extends StatelessWidget {
  const _Block({
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<Cached<T>> value;
  final VoidCallback onRetry;
  final Widget? Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final child = switch (value) {
      AsyncValue(:final value?) => builder(value.data),
      AsyncError() => _BlockError(onRetry: onRetry),
      _ => const SkeletonBox(height: 96, radius: AppRadius.md),
    };
    if (child == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: child,
    );
  }
}

class _BlockError extends StatelessWidget {
  const _BlockError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.circleAlert,
                  color: context.colors.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  l10n.homeBlockError,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          AppButton.text(label: l10n.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final today = l10n.homeDate(ref.watch(clockProvider)());
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today.isEmpty
                    ? today
                    : today[0].toUpperCase() + today.substring(1),
                style: context.textTheme.bodySmall,
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.homeGreeting(firstName),
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: l10n.homeNotifications(unread),
          excludeSemantics: true,
          child: IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: c.red,
              smallSize: 10,
              child: const Icon(LucideIcons.bell),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.contribution});

  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const brand = AppColors.light;
    final c = context.colors;
    final due = contribution.dueAmount;
    final progress = due <= 0
        ? 1.0
        : (contribution.paidAmount / due).clamp(0.0, 1.0);
    final settled =
        contribution.state == ContributionState.paid ||
        contribution.state == ContributionState.exempt;
    final message = switch (contribution.state) {
      ContributionState.paid => l10n.homeContributionUpToDate,
      ContributionState.exempt => l10n.homeContributionExempt,
      _ => l10n.homeContributionRemaining(contribution.remainingAmount),
    };
    final onGreen = c.onGreen;

    return Material(
      color: c.green,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.contributions),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4 + AppSpacing.space1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wrap : le badge passe à la ligne si le texte est agrandi.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  Text(
                    l10n.homeContributionTitle(contribution.year),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: onGreen,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: brand.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space1,
                      ),
                      child: Text(
                        contribution.state.label(l10n),
                        style: AppTypography.label.toTextStyle(
                          color: settled ? brand.green : brand.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Semantics(
                label: l10n.homeContributionProgress(
                  contribution.paidAmount,
                  due,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: onGreen,
                    backgroundColor: onGreen.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: onGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Upcoming extends ConsumerWidget {
  const _Upcoming({required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final registration = ref.watch(homeNextRegistrationProvider);
    final meeting = ref.watch(homeNextMeetingProvider);
    final hasEvent = registration.value?.data != null;
    final hasMeeting = meeting.value?.data != null;
    final loading = registration.isLoading || meeting.isLoading;
    if (!hasEvent &&
        !hasMeeting &&
        !loading &&
        !registration.hasError &&
        !meeting.hasError) {
      return const SizedBox.shrink();
    }

    // Pas de marge sous la section : chaque bloc a déjà la sienne.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(l10n.homeUpcoming),
        const SizedBox(height: AppSpacing.space2),
        _Block<Registration?>(
          value: registration,
          onRetry: () => ref.invalidate(homeNextRegistrationProvider),
          builder: (next) => next == null
              ? null
              : _DateTile(
                  date: next.event.startsAt.toLocal(),
                  background: c.green,
                  foreground: c.onGreen,
                  title: next.event.title,
                  subtitle: [
                    if (next.event.location != null) next.event.location!,
                    l10n.homeRegistered(gender),
                  ].join(' · '),
                  onTap: () =>
                      context.go(AppRoutes.eventDetail(next.event.slug)),
                ),
        ),
        _Block<NextMeeting?>(
          value: meeting,
          onRetry: () => ref.invalidate(homeNextMeetingProvider),
          builder: (next) => next == null
              ? null
              : _DateTile(
                  date: next.date,
                  background: c.blueSoft,
                  foreground: c.blue,
                  title: l10n.homeMeetingTitle,
                  subtitle: [
                    if (next.location != null) next.location!,
                    l10n.homeMeetingHint,
                  ].join(' · '),
                ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text.toUpperCase(),
      style: AppTypography.label.toTextStyle(color: context.colors.inkMuted),
    ),
  );
}

/// Pastille de date (jour et mois) suivie d'un titre et d'un sous-titre.
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final DateTime date;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    // « 25 oct. » : jour et mois abrégé, sans l'année.
    final month = localizations
        .formatShortMonthDay(date)
        .replaceAll(RegExp(r'\d'), '')
        .trim();
    return MergeSemantics(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            Semantics(
              label: localizations.formatFullDate(date),
              excludeSemantics: true,
              child: Container(
                width: 54,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '${date.day}',
                      style: AppTypography.h3.toTextStyle(color: foreground),
                    ),
                    Text(
                      month,
                      style: AppTypography.label.toTextStyle(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.titleMedium),
                  Text(subtitle, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunitiesCard extends StatelessWidget {
  const _OpportunitiesCard({required this.data});

  final HomeOpportunities data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final latest = data.latest!;
    final details = [
      latest.type.label(l10n),
      latest.organization,
      if (latest.deadline != null)
        l10n.homeOpportunityDeadline(latest.deadline!),
    ].join(' · ');
    return MergeSemantics(
      child: AppCard(
        onTap: () => context.push(AppRoutes.opportunities),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                Text(
                  l10n.homeOpportunitiesTitle,
                  style: context.textTheme.titleSmall?.copyWith(color: c.blue),
                ),
                if (data.unseenCount > 0)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.redSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space1,
                      ),
                      child: Text(
                        l10n.homeOpportunitiesNew(data.unseenCount),
                        style: AppTypography.label.toTextStyle(color: c.red),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(latest.title, style: context.textTheme.titleLarge),
            Text(details, style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ProfileReminder extends StatelessWidget {
  const _ProfileReminder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeProfileTitle, style: context.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space1),
          Text(l10n.homeProfileText, style: context.textTheme.bodySmall),
          AppButton.text(
            label: l10n.homeProfileAction,
            onPressed: () => context.go(AppRoutes.profilePro),
          ),
        ],
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  const _NewsList({required this.news});

  final List<News> news;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(l10n.homeNews),
        const SizedBox(height: AppSpacing.space2),
        for (final item in news) ...[
          NewsCard(news: item),
          if (item != news.last) const SizedBox(height: AppSpacing.space3),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton.text(
            label: l10n.homeNewsAll,
            compact: true,
            onPressed: () => context.push(AppRoutes.news),
          ),
        ),
      ],
    );
  }
}

/// Bureau seulement (`attendance.scan`) : accès au scan des présences.
class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return MergeSemantics(
      child: AppCard(
        color: c.blueSoft,
        onTap: () => context.push(AppRoutes.scan),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(LucideIcons.scanLine, color: c.blue, size: 32),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.scanHomeTitle,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: c.blue,
                    ),
                  ),
                  Text(l10n.scanHomeText, style: context.textTheme.bodySmall),
                ],
              ),
            ),
            ExcludeSemantics(
              child: Icon(LucideIcons.chevronRight, color: c.blue),
            ),
          ],
        ),
      ),
    );
  }
}
