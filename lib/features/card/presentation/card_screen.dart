import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/card_rules.dart';
import '../domain/member_card.dart';
import 'card_controller.dart';
import 'card_status_label.dart';
import 'max_brightness.dart';

/// Carte de membre (maquette `app-carte`).
class CardScreen extends ConsumerStatefulWidget {
  const CardScreen({super.key});

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(cardControllerProvider.notifier).renewIfNeeded());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final card = ref.watch(cardControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final member = session is SessionMember ? session.member : null;
    final canScan = member?.can(Abilities.attendanceScan) ?? false;
    final now = ref.watch(clockProvider)();

    return MaxBrightness(
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(cardControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space6,
              ),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.cardTitle,
                        style: context.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _OfflineBadge(label: l10n.cardOfflineBadge),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                switch (card) {
                  AsyncValue(:final value?) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isCardExpired(value.data, now)) ...[
                        _ExpiredNotice(text: l10n.cardExpired),
                        const SizedBox(height: AppSpacing.space4),
                      ],
                      _MemberCardView(
                        card: value.data,
                        gender: member?.gender ?? Gender.unknown,
                      ),
                    ],
                  ),
                  AsyncError(:final error) => ErrorState(
                    error: error,
                    onRetry: () =>
                        ref.read(cardControllerProvider.notifier).refresh(),
                  ),
                  _ => const _CardSkeleton(),
                },
                if (canScan) ...[
                  const SizedBox(height: AppSpacing.space4),
                  _BureauBox(c: c),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.greenSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(LucideIcons.check, size: 14, color: c.green),
            ),
            const SizedBox(width: AppSpacing.space1),
            Flexible(
              child: Text(
                label,
                style: AppTypography.label.toTextStyle(color: c.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiredNotice extends StatelessWidget {
  const _ExpiredNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: c.redSoft,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(LucideIcons.triangleAlert, color: c.red),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// La carte elle-même. Elle garde les couleurs de la marque (palette
/// claire) dans les deux thèmes, comme une carte physique : logo blanc sur
/// vert, QR code noir sur blanc pour une lecture fiable.
class _MemberCardView extends StatelessWidget {
  const _MemberCardView({required this.card, required this.gender});

  final MemberCard card;
  final Gender gender;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const brand = AppColors.light;
    final onCard = context.textTheme.bodyMedium!.copyWith(color: brand.onGreen);
    final joined = MaterialLocalizations.of(
      context,
    ).formatMediumDate(card.joinedAt);

    return Semantics(
      container: true,
      label: l10n.cardTitle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand.green,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6 - AppSpacing.space1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/logos/aeenci-logo-blanc.svg',
                    width: 96,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  const Spacer(),
                  Flexible(
                    flex: 4,
                    child: DecoratedBox(
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
                          cardStatusLabel(
                            l10n,
                            status: card.status,
                            engagement: card.engagement,
                            gender: gender,
                          ),
                          textAlign: TextAlign.center,
                          style: AppTypography.label.toTextStyle(
                            color: brand.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  _Avatar(card: card),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.fullName,
                          style: AppTypography.h3.toTextStyle(
                            color: brand.onGreen,
                          ),
                        ),
                        Text(
                          card.category.label(l10n),
                          style: AppTypography.small.toTextStyle(
                            color: brand.onGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              _Row(
                label: l10n.cardMemberNumber,
                value: card.memberNumber,
                style: onCard,
              ),
              const SizedBox(height: AppSpacing.space1),
              _Row(label: l10n.cardMemberSince, value: joined, style: onCard),
              const SizedBox(height: AppSpacing.space4),
              Center(
                child: Semantics(
                  image: true,
                  label: l10n.cardQrLabel,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: brand.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    // `qr_payload` affiché tel que reçu : l'application ne
                    // fabrique ni ne modifie jamais un QR code.
                    child: QrImageView(
                      data: card.qrPayload,
                      size: 196,
                      padding: EdgeInsets.zero,
                      backgroundColor: brand.surfaceRaised,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: brand.ink,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: brand.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                l10n.cardQrHint,
                textAlign: TextAlign.center,
                style: AppTypography.small.toTextStyle(color: brand.onGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.style});

  final String label;
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.space3,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.card});

  final MemberCard card;

  @override
  Widget build(BuildContext context) {
    const brand = AppColors.light;
    final initials = card.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final placeholder = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      color: brand.greenSoft,
      child: Text(
        initials,
        style: AppTypography.h3.toTextStyle(color: brand.green),
      ),
    );
    final photo = card.photoUrl;
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).cardPhotoLabel(card.fullName),
      child: ClipOval(
        child: photo == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: photo,
                width: 64,
                height: 64,
                memCacheWidth: 192,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: context.colors.line,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

class _BureauBox extends StatelessWidget {
  const _BureauBox({required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.cardBureauLabel.toUpperCase(),
            style: AppTypography.label.toTextStyle(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.space3),
          // Bouton plein bleu de la maquette (secondaire plein du design
          // system : on-blue sur blue).
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.blue,
              foregroundColor: c.onBlue,
            ),
            onPressed: () => context.push(AppRoutes.scan),
            icon: const Icon(LucideIcons.scanLine),
            label: Text(l10n.cardScanAction),
          ),
        ],
      ),
    );
  }
}
