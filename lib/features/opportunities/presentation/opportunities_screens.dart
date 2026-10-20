import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_badge.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/device_services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/opportunity.dart';
import 'interest_sheet.dart';
import 'opportunities_providers.dart';

/// `female` ou `other`, pour les accords (« intéressée »).
String genderKey(WidgetRef ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SessionMember && session.member.gender == Gender.female
      ? 'female'
      : 'other';
}

AppBadgeTone _tone(OpportunityType type) => switch (type) {
  OpportunityType.internship || OpportunityType.training => AppBadgeTone.green,
  OpportunityType.scholarship => AppBadgeTone.red,
  _ => AppBadgeTone.blue,
};

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

/// Opportunités reçues (maquette `app-opportunites`, liste).
class OpportunitiesScreen extends ConsumerWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenOpportunities)),
      body: AsyncView<OpportunitiesState>(
        value: ref.watch(opportunitiesProvider),
        onRetry: () => ref.invalidate(opportunitiesProvider),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => ref.refresh(opportunitiesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              Text(l10n.opportunitiesIntro, style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.space4),
              if (state.items.isEmpty)
                EmptyState(
                  icon: LucideIcons.briefcase,
                  title: l10n.opportunitiesEmpty,
                  message: l10n.opportunitiesEmptyHint,
                ),
              for (final o in state.items) ...[
                _OpportunityCard(opportunity: o),
                const SizedBox(height: AppSpacing.space3),
              ],
              if (state.loadMoreError != null)
                Text(
                  errorMessage(l10n, state.loadMoreError!),
                  style: context.textTheme.bodySmall?.copyWith(color: c.danger),
                ),
              if (state.hasMore)
                AppButton.text(
                  label: l10n.opportunitiesMore,
                  loading: state.loadingMore,
                  onPressed: () =>
                      ref.read(opportunitiesProvider.notifier).loadMore(),
                ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.opportunitiesFooter,
                style: context.textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton.text(
                  label: l10n.opportunitiesFooterLink,
                  compact: true,
                  onPressed: () => context.go(AppRoutes.profile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityCard extends ConsumerWidget {
  const _OpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final o = opportunity;
    final isNew = !o.seen && !o.interested;
    final (state, stateColor) = o.interested
        ? (l10n.opportunityInterestedBadge(genderKey(ref)), c.green)
        : isNew
        ? (l10n.opportunityNew, c.red)
        : (l10n.opportunitySeen, c.inkMuted);
    final place = [o.organization, ?o.location].join(' · ');
    return Semantics(
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isNew ? c.blue : c.line,
            width: isNew ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => context.push(AppRoutes.opportunityDetail(o.id)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppBadge(o.type.label(l10n), tone: _tone(o.type)),
                      Text(
                        state,
                        style: AppTypography.label.toTextStyle(
                          color: stateColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(o.title, style: context.textTheme.titleMedium),
                  Text(place, style: context.textTheme.bodySmall),
                  if (o.deadline != null)
                    Text(
                      '${l10n.opportunityDeadline} : '
                      '${l10n.dateShort(o.deadline!)}',
                      style: context.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Pourquoi tu la reçois », à partir des seuls critères de `matched_on`.
String whyText(AppLocalizations l10n, MatchedOn m) {
  String list(List<String> v) => v.join(', ');
  final categories = [
    for (final c in m.categories)
      if (c != MemberCategory.unknown) c.label(l10n),
  ];
  final parts = [
    if (m.domains.isNotEmpty) l10n.whyDomains(list(m.domains)),
    if (m.skills.isNotEmpty) l10n.whySkills(list(m.skills)),
    if (m.cities.isNotEmpty) l10n.whyCities(list(m.cities)),
    if (categories.isNotEmpty) l10n.whyCategories(list(categories)),
    if (m.educationLevels.isNotEmpty) l10n.whyLevels(list(m.educationLevels)),
  ];
  if (parts.isEmpty) return l10n.whyGeneric;
  final joined = parts.length == 1
      ? parts.single
      : '${parts.sublist(0, parts.length - 1).join(', ')}'
            '${l10n.listAnd}${parts.last}';
  final sentence = l10n.whySentence(parts.length, joined);
  return sentence[0].toUpperCase() + sentence.substring(1);
}

/// Détail d'une offre : informations, pourquoi, postuler, intérêt.
class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(opportunityDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenOpportunityDetail)),
      body: value.error is NotFoundException
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: LucideIcons.briefcase,
                  title: l10n.opportunityNotFound,
                ),
              ),
            )
          : AsyncView<OpportunityDetail>(
              value: value,
              onRetry: () => ref.invalidate(opportunityDetailProvider(id)),
              builder: (context, o) => _Detail(opportunity: o),
            ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.opportunity});

  final OpportunityDetail opportunity;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) {
        _snack(context, errorMessage(AppLocalizations.of(context), error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openJobDescription() => _run(() async {
    final opened = await ref
        .read(opportunityActionsProvider)
        .openJobDescription(widget.opportunity);
    if (!opened && mounted) {
      _snack(context, AppLocalizations.of(context).fileNoViewer);
    }
  });

  Future<void> _withdraw() => _run(() async {
    await ref
        .read(opportunityActionsProvider)
        .withdrawInterest(widget.opportunity.id);
    if (mounted) {
      _snack(context, AppLocalizations.of(context).interestWithdrawn);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final o = widget.opportunity;
    final gender = genderKey(ref);
    final devices = ref.read(deviceServicesProvider);

    Widget kv(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.bodySmall),
            Text(value, style: context.textTheme.bodyLarge),
          ],
        ),
      ),
    );

    final apply = switch (o.applyMethod) {
      ApplyMethod.url when o.applyUrl != null => AppButton(
        label: l10n.applyDirect,
        icon: LucideIcons.externalLink,
        expand: true,
        onPressed: () => devices.openUrl(o.applyUrl!),
      ),
      ApplyMethod.email when o.applyEmail != null => AppButton(
        label: l10n.applyByEmail,
        icon: LucideIcons.mail,
        expand: true,
        onPressed: () => devices.openUrl(
          Uri(
            scheme: 'mailto',
            path: o.applyEmail,
            queryParameters: {'subject': o.title},
          ).toString(),
        ),
      ),
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppBadge(o.type.label(l10n), tone: _tone(o.type)),
            Text(l10n.opportunityVerified, style: context.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Semantics(
          header: true,
          child: Text(o.title, style: context.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.space4),
        kv(l10n.opportunityOrganization, o.organization),
        if (o.location != null) kv(l10n.opportunityLocation, o.location!),
        if (o.deadline != null)
          kv(l10n.opportunityDeadline, l10n.dateShort(o.deadline!)),
        kv(l10n.opportunityReceived, l10n.dateShort(o.receivedAt.toLocal())),
        const SizedBox(height: AppSpacing.space2),
        kv(l10n.opportunityDescription, o.description),
        const SizedBox(height: AppSpacing.space2),
        AppCard(
          color: c.blueSoft,
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.opportunityWhy, style: context.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  whyText(l10n, o.matchedOn),
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        if (o.jobDescriptionUrl != null) ...[
          const SizedBox(height: AppSpacing.space3),
          AppButton.secondary(
            label: l10n.jobDescriptionOpen,
            icon: LucideIcons.fileText,
            expand: true,
            loading: _busy,
            onPressed: _openJobDescription,
          ),
        ],
        if (o.applyMethod == ApplyMethod.viaBureau) ...[
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.applyViaBureauTitle,
                    style: context.textTheme.titleSmall,
                  ),
                  Text(
                    o.applyNote ?? l10n.applyViaBureauDefault,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space6),
        ?apply,
        if (apply != null) const SizedBox(height: AppSpacing.space2),
        if (o.interested)
          AppCard(
            color: c.greenSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.interestDone(gender),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: c.green,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  o.cvShared ? l10n.interestCvShared : l10n.interestCvNotShared,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space2),
                AppButton.text(
                  label: l10n.interestWithdraw,
                  compact: true,
                  loading: _busy,
                  onPressed: _withdraw,
                ),
              ],
            ),
          )
        else
          AppButton.secondary(
            label: l10n.interestButton(gender),
            icon: LucideIcons.handHeart,
            expand: true,
            onPressed: () => showInterestSheet(context, o),
          ),
      ],
    );
  }
}
