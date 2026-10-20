import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/external_links.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../contributions/data/contact_repository.dart';
import '../data/membership_repository.dart';
import '../domain/membership_application.dart';
import 'session_controller.dart';

/// Ce qu'affiche le suivi : la demande, et si possible le droit
/// d'adhésion et l'e-mail de l'association.
@immutable
class MembershipStatus {
  const MembershipStatus({
    required this.application,
    this.feeAmount,
    this.contactEmail,
  });

  final MembershipApplication application;
  final int? feeAmount;
  final String? contactEmail;
}

final membershipStatusProvider =
    FutureProvider.autoDispose<Cached<MembershipStatus>>((ref) async {
      final session = ref.watch(sessionControllerProvider);
      final category = switch (session) {
        SessionCandidate(:final member) => member.category,
        _ => MemberCategory.unknown,
      };

      // Montant et e-mail : utiles mais non bloquants.
      Future<T?> optional<T>(Future<T> Function() fetch) async {
        try {
          return await fetch();
        } on ApiException {
          return null;
        }
      }

      final fees = optional(ref.read(membershipRepositoryProvider).fetchFees);
      final contact = optional(
        ref.read(contactRepositoryProvider).fetchContact,
      );
      final application = await fetchWithCache<MembershipApplication>(
        cache: ref.read(cacheStoreProvider),
        key: 'membership_application',
        fetch: ref.read(membershipRepositoryProvider).fetchApplication,
        toJson: (application) => application.toJson(),
        fromJson: (json) =>
            MembershipApplication.fromJson(json! as Map<String, dynamic>),
      );

      final fee = (await fees)
          ?.where((fee) => fee.category == category)
          .firstOrNull;
      return Cached(
        MembershipStatus(
          application: application.data,
          feeAmount: fee?.amount,
          contactEmail: (await contact)?.email,
        ),
        offlineSince: application.offlineSince,
      );
    });

/// Suivi de l'adhésion du candidat (maquette `app-suivi`).
class MembershipStatusScreen extends ConsumerWidget {
  const MembershipStatusScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    // Si la demande a été validée, la session devient « membre » et la
    // garde ouvre les onglets.
    await ref.read(sessionControllerProvider.notifier).refreshMember();
    ref.invalidate(membershipStatusProvider);
    try {
      await ref.read(membershipStatusProvider.future);
    } on Object {
      // L'erreur s'affiche dans l'écran, avec « Réessayer ».
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space6,
                AppSpacing.space2,
                AppSpacing.space3,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: AppTypography.h2
                          .toTextStyle(color: c.green)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const _SignOutLink(),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<MembershipStatus>(
                value: ref.watch(membershipStatusProvider),
                onRetry: () => ref.invalidate(membershipStatusProvider),
                builder: (context, status) => RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: ListView(
                    // Tirer pour actualiser, même quand tout tient à l'écran.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.space6),
                    children: [
                      if (status.application.state == AdmissionState.rejected)
                        _Rejected(application: status.application)
                      else
                        _Pending(status: status),
                      if (status.contactEmail != null) ...[
                        const SizedBox(height: AppSpacing.space8),
                        _Question(email: status.contactEmail!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutLink extends ConsumerWidget {
  const _SignOutLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton.text(
      label: AppLocalizations.of(context).signOut,
      onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: context.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Pending extends StatelessWidget {
  const _Pending({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submitted = status.application.submittedAt.toLocal();
    final fee = status.feeAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(l10n.statusPendingTitle),
        const SizedBox(height: AppSpacing.space2),
        Text(
          l10n.statusPendingIntro(submitted),
          style: context.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.space8),
        _Step(
          number: 1,
          state: _StepState.done,
          title: l10n.statusStepSent,
          detail: AppLocalizations.of(context).dateShort(submitted),
        ),
        _Step(
          number: 2,
          state: _StepState.current,
          title: l10n.statusStepReview,
          detail: l10n.statusStepReviewInProgress,
        ),
        _Step(
          number: 3,
          state: _StepState.upcoming,
          title: l10n.statusStepFee,
          detail: fee == null
              ? l10n.statusStepFeeUnknown
              : l10n.statusStepFeeAmount(fee),
        ),
        _Step(
          number: 4,
          state: _StepState.upcoming,
          title: l10n.statusStepCard,
          detail: l10n.statusStepCardHint,
          last: true,
        ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.state,
    required this.title,
    required this.detail,
    this.last = false,
  });

  final int number;
  final _StepState state;
  final String title;
  final String detail;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final (background, foreground) = switch (state) {
      _StepState.done => (c.green, c.onGreen),
      _StepState.current => (c.blueSoft, c.blue),
      _StepState.upcoming => (c.line, c.inkMuted),
    };
    final stateLabel = switch (state) {
      _StepState.done => l10n.statusStepDone,
      _StepState.current => l10n.statusStepCurrent,
      _StepState.upcoming => l10n.statusStepNumber(number),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.space4),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: stateLabel,
              child: ExcludeSemantics(
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: state == _StepState.done
                      ? Icon(LucideIcons.check, size: 18, color: foreground)
                      : Text(
                          '$number',
                          style: AppTypography.small
                              .toTextStyle(color: foreground)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.titleMedium),
                  Text(detail, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rejected extends StatelessWidget {
  const _Rejected({required this.application});

  final MembershipApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final reviewed = (application.reviewedAt ?? application.submittedAt)
        .toLocal();
    final reason = application.decisionReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(l10n.statusRejectedTitle),
        const SizedBox(height: AppSpacing.space2),
        Text(
          l10n.statusRejectedIntro(reviewed),
          style: context.textTheme.bodySmall,
        ),
        if (reason != null && reason.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          MergeSemantics(
            child: AppCard(
              color: c.redSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statusRejectedReason,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: c.red,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(reason, style: context.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space6),
        Text(l10n.statusRejectedHint, style: context.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.space4),
        AppButton(
          label: l10n.statusRejectedAction,
          icon: LucideIcons.externalLink,
          expand: true,
          onPressed: () => openExternal(SiteLinks.membership),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return AppCard(
      color: c.blueSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statusQuestionTitle,
            style: context.textTheme.titleMedium?.copyWith(color: c.blue),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(l10n.statusQuestionText, style: context.textTheme.bodySmall),
          AppButton.text(
            label: email,
            icon: LucideIcons.mail,
            onPressed: () => openExternal('mailto:$email'),
          ),
        ],
      ),
    );
  }
}
