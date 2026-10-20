import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/design/components/offline_banner.dart';
import '../../../core/design/components/skeleton.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/device_services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_rules.dart';
import '../domain/contact_info.dart';
import '../domain/contribution.dart';
import '../domain/contributions_rules.dart';
import 'contributions_providers.dart';
import 'receipt_sheet.dart';

/// Cotisations et reçus (maquette `app-cotisations`).
class ContributionsScreen extends ConsumerWidget {
  const ContributionsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(contributionsProvider)
      ..invalidate(contactProvider)
      ..invalidate(paymentsProvider);
    await Future.wait([
      ref
          .read(contributionsProvider.future)
          .then<void>((_) {}, onError: (Object _) {}),
      ref
          .read(contactProvider.future)
          .then<void>((_) {}, onError: (Object _) {}),
      ref
          .read(paymentsProvider.future)
          .then<void>((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contributions = ref.watch(contributionsProvider);
    final contact = ref.watch(contactProvider);
    final payments = ref.watch(paymentsProvider);

    final offlineSince =
        <DateTime?>[
          contributions.value?.offlineSince,
          contact.value?.offlineSince,
          payments.value?.offlineSince,
        ].whereType<DateTime>().fold<DateTime?>(
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
              Semantics(
                header: true,
                child: Text(
                  l10n.contributionsTitle,
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (offlineSince != null) ...[
                const SizedBox(height: AppSpacing.space3),
                OfflineBanner(updatedAt: offlineSince),
              ],
              const SizedBox(height: AppSpacing.space4),
              _Section<List<Contribution>>(
                value: contributions,
                onRetry: () => ref.invalidate(contributionsProvider),
                builder: (all) {
                  final current = currentContribution(
                    all,
                    ref.watch(clockProvider)(),
                  );
                  return current == null
                      ? AppCard(child: Text(l10n.contributionsNone))
                      : _CurrentYearCard(contribution: current);
                },
              ),
              _Section<ContactInfo>(
                value: contact,
                onRetry: () => ref.invalidate(contactProvider),
                builder: (info) => _HowToPay(accounts: info.mobileMoney),
              ),
              _Section<List<Contribution>>(
                value: contributions,
                onRetry: () => ref.invalidate(contributionsProvider),
                // L'année en cours est déjà en tête de l'écran.
                builder: (all) => _MyYears(
                  contributions: contributionYears(all)
                      .where(
                        (c) =>
                            c.year !=
                            currentContribution(
                              all,
                              ref.watch(clockProvider)(),
                            )?.year,
                      )
                      .toList(),
                  admission: admissionPayment(
                    payments.value?.data.items ?? const [],
                  ),
                ),
              ),
              _Section<PaymentsState>(
                value: payments,
                onRetry: () => ref.invalidate(paymentsProvider),
                builder: (state) => _Payments(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une section : squelette, erreur avec « Réessayer », ou contenu.
class _Section<T> extends StatelessWidget {
  const _Section({
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<Cached<T>> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: switch (value) {
        AsyncValue(:final value?) => builder(value.data),
        AsyncError(:final error) => AppCard(
          child: ErrorState(error: error, onRetry: onRetry),
        ),
        _ => const SkeletonBox(height: 120, radius: AppRadius.md),
      },
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.toTextStyle(color: context.colors.inkMuted),
      ),
    ),
  );
}

/// Badge d'état d'une cotisation : vert si réglée, rouge sinon.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, this.onGreen = false});

  final ContributionState state;

  /// Posé sur l'aplat vert de l'année en cours.
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final settled =
        state == ContributionState.paid || state == ContributionState.exempt;
    final (background, foreground) = onGreen
        ? (
            AppColors.light.surfaceRaised,
            settled ? AppColors.light.green : AppColors.light.red,
          )
        : (settled ? c.greenSoft : c.redSoft, settled ? c.green : c.red);
    return _Pill(
      text: state.label(l10n),
      background: background,
      foreground: foreground,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      child: Text(
        text,
        style: AppTypography.label.toTextStyle(color: foreground),
      ),
    ),
  );
}

class _CurrentYearCard extends StatelessWidget {
  const _CurrentYearCard({required this.contribution});

  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final due = contribution.dueAmount;
    final progress = due <= 0
        ? 1.0
        : (contribution.paidAmount / due).clamp(0.0, 1.0);
    final text = context.textTheme.bodyMedium!.copyWith(color: c.onGreen);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.green,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4 + AppSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                Text(
                  l10n.contributionsYear(contribution.year),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: c.onGreen,
                  ),
                ),
                _StateBadge(state: contribution.state, onGreen: true),
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
                  color: c.onGreen,
                  backgroundColor: c.onGreen.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _AmountRow(
              label: l10n.contributionsPaid,
              value: l10n.contributionsPaidOf(contribution.paidAmount, due),
              style: text,
            ),
            const SizedBox(height: AppSpacing.space1),
            _AmountRow(
              label: l10n.contributionsRemaining,
              value: l10n.amountFcfa(contribution.remainingAmount),
              style: text,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.space3,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _HowToPay extends StatelessWidget {
  const _HowToPay({required this.accounts});

  final List<MobileMoneyAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Semantics(
      container: true,
      label: l10n.howToPayTitle,
      child: AppCard(
        color: c.blueSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.howToPayTitle,
              style: context.textTheme.titleLarge?.copyWith(color: c.blue),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              l10n.howToPayText,
              style: context.textTheme.bodySmall?.copyWith(color: c.ink),
            ),
            for (final account in accounts) ...[
              const SizedBox(height: AppSpacing.space3),
              _MobileMoneyRow(account: account),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileMoneyRow extends ConsumerStatefulWidget {
  const _MobileMoneyRow({required this.account});

  final MobileMoneyAccount account;

  @override
  ConsumerState<_MobileMoneyRow> createState() => _MobileMoneyRowState();
}

class _MobileMoneyRowState extends ConsumerState<_MobileMoneyRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final account = widget.account;
    final operator = account.operator.label(l10n);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(operator, style: context.textTheme.bodySmall),
                  Text(
                    account.number,
                    style: context.textTheme.titleMedium?.copyWith(
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    l10n.howToPayAccount(account.accountName),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: _copied ? l10n.copied : l10n.copyNumber(operator),
              excludeSemantics: true,
              child: AppButton.secondary(
                label: _copied ? l10n.copied : l10n.copy,
                icon: _copied ? LucideIcons.check : LucideIcons.copy,
                compact: true,
                onPressed: () async {
                  await ref
                      .read(deviceServicesProvider)
                      .copyText(account.number);
                  if (mounted) setState(() => _copied = true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyYears extends StatelessWidget {
  const _MyYears({required this.contributions, required this.admission});

  final List<Contribution> contributions;
  final Payment? admission;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final admission = this.admission;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.myYearsTitle),
        // Seulement si le paiement du droit d'adhésion figure dans
        // l'historique : aucun montant dû n'est inventé.
        if (admission != null)
          _YearRow(
            title: l10n.admissionFee,
            subtitle: l10n.amountFcfa(admission.amount),
            badge: _Pill(
              text: l10n.admissionFeePaid,
              background: c.greenSoft,
              foreground: c.green,
            ),
          ),
        for (final contribution in contributions)
          _YearRow(
            title: l10n.contributionsYear(contribution.year),
            subtitle: l10n.amountFcfa(contribution.dueAmount),
            badge: _StateBadge(state: contribution.state),
          ),
      ],
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final Widget badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
    child: MergeSemantics(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.textTheme.titleMedium),
                Text(subtitle, style: context.textTheme.bodySmall),
              ],
            ),
            badge,
          ],
        ),
      ),
    ),
  );
}

/// Intitulé d'un paiement : « Cotisation 2026-2027 » ou « Droit d'adhésion ».
String paymentLabel(AppLocalizations l10n, Payment payment) =>
    switch (payment.purpose) {
      PaymentPurpose.admission => l10n.admissionFee,
      _ when payment.contributionYear != null => l10n.paymentContribution(
        payment.contributionYear!,
      ),
      _ => payment.purpose.label(l10n),
    };

class _Payments extends ConsumerWidget {
  const _Payments({required this.state});

  final PaymentsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.paymentsTitle),
        if (state.items.isEmpty)
          Text(l10n.paymentsNone, style: context.textTheme.bodySmall),
        for (final payment in state.items) _PaymentRow(payment: payment),
        if (state.loadMoreError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Text(
              errorMessage(l10n, state.loadMoreError!),
              style: context.textTheme.bodySmall?.copyWith(color: c.danger),
            ),
          ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space3),
            child: AppButton.text(
              label: l10n.paymentsMore,
              loading: state.loadingMore,
              onPressed: () => ref.read(paymentsProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final label = paymentLabel(l10n, payment);
    return Semantics(
      button: true,
      label: l10n.paymentReceiptLabel(label, payment.amount),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => showReceiptSheet(context, payment: payment, label: label),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space3,
            horizontal: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: c.greenSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(LucideIcons.receipt, color: c.green, size: 20),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.textTheme.titleMedium),
                    Text(
                      '${l10n.dateShort(payment.paidOn)} · ${payment.method.label(l10n)}',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                l10n.amountShort(payment.amount),
                style: context.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explication d'un échec de téléchargement du reçu.
String receiptErrorMessage(AppLocalizations l10n, ApiException error) =>
    switch (error) {
      NetworkException() => l10n.receiptOffline,
      NotFoundException() => l10n.receiptNotFound,
      _ => errorMessage(l10n, error),
    };
