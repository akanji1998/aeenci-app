import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/app_switch_tile.dart';
import '../../../core/design/components/member_avatar.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';
import '../../../core/utils/device_services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../card/presentation/card_status_label.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../notifications/presentation/push_controller.dart';
import '../domain/professional_profile.dart';
import '../domain/profile_rules.dart';
import 'profile_providers.dart';
import 'widgets/profile_widgets.dart';

/// Profil et réglages (maquette `app-profil`).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final session = ref.watch(sessionControllerProvider);
    final member = session is SessionMember ? session.member : null;
    final profile = ref.watch(professionalProfileProvider).value?.data;
    final educations = ref.watch(educationsProvider).value?.data;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(professionalProfileProvider)
              ..invalidate(educationsProvider)
              ..invalidate(notificationPreferencesProvider);
            await ref.read(sessionControllerProvider.notifier).refreshMember();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              if (member != null)
                MergeSemantics(
                  child: Row(
                    children: [
                      MemberAvatar(
                        name: '${member.firstNames} ${member.lastName}',
                        photoUrl: member.photoUrl,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                '${member.firstNames} ${member.lastName}',
                                style: context.textTheme.headlineSmall,
                              ),
                            ),
                            Text(
                              l10n.profileHeaderLine(
                                member.memberNumber ?? '',
                                cardStatusLabel(
                                  l10n,
                                  status: member.status ?? MemberStatus.member,
                                  engagement: member.engagement,
                                  gender: member.gender,
                                ),
                              ),
                              style: context.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.space6),
              if (profile != null) _ShowcaseCard(profile: profile),
              const SizedBox(height: AppSpacing.space6),
              Eyebrow(l10n.myInfoTitle),
              SettingsGroup(
                children: [
                  NavRow(
                    title: l10n.sheetTitle,
                    subtitle: l10n.profileSheetSubtitle,
                    onTap: () => context.go(AppRoutes.profileSheet),
                  ),
                  NavRow(
                    title: l10n.educationTitle,
                    subtitle: educations == null
                        ? null
                        : l10n.educationCount(educations.length),
                    onTap: () => context.go(AppRoutes.profileEducation),
                  ),
                  NavRow(
                    title: l10n.proTitle,
                    trailing: profile == null
                        ? null
                        : l10n.completionPercent(profileCompletion(profile)),
                    onTap: () => context.go(AppRoutes.profilePro),
                  ),
                  NavRow(
                    title: l10n.cvAndWorks,
                    subtitle: profile == null
                        ? null
                        : profile.cvUrl == null
                        ? l10n.cvToAdd
                        : l10n.cvAdded,
                    onTap: () => context.go(AppRoutes.profilePro),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),
              Eyebrow(l10n.notificationsTitle),
              const PushPermissionBanner(),
              const _NotificationPreferences(),
              const SizedBox(height: AppSpacing.space6),
              Eyebrow(l10n.accountTitle),
              SettingsGroup(
                children: [
                  NavRow(
                    title: l10n.changePassword,
                    onTap: () => context.go(AppRoutes.profilePassword),
                  ),
                  NavRow(
                    title: l10n.signOut,
                    onTap: () =>
                        ref.read(sessionControllerProvider.notifier).signOut(),
                  ),
                  NavRow(
                    title: l10n.deleteAccount,
                    danger: true,
                    onTap: () => context.go(AppRoutes.profileDeleteAccount),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.deleteAccountNote,
                style: context.textTheme.bodySmall?.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseCard extends ConsumerStatefulWidget {
  const _ShowcaseCard({required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<_ShowcaseCard> createState() => _ShowcaseCardState();
}

class _ShowcaseCardState extends ConsumerState<_ShowcaseCard> {
  bool _busy = false;

  Future<void> _toggle(bool enable) async {
    final l10n = AppLocalizations.of(context);
    // Consentement explicite pour activer ; aucun pour désactiver.
    if (enable && !await showShowcaseConsent(context)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(professionalProfileProvider.notifier)
          .setShowcase(isPublic: enable);
      if (mounted) {
        showSnack(
          context,
          enable ? l10n.showcaseEnabledDone : l10n.showcaseDisabledDone,
        );
      }
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final profile = widget.profile;
    final on = profile.isPublic;
    final badge = switch (profile.showcaseStatus) {
      ShowcaseStatus.pending => l10n.showcasePendingBadge,
      ShowcaseStatus.published => l10n.showcasePublishedBadge,
      _ => null,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: on ? c.blue : c.line, width: on ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.showcaseTitle,
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        on ? l10n.showcaseOnText : l10n.showcaseOffText,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: l10n.showcaseSwitchLabel,
                  child: Switch(value: on, onChanged: _busy ? null : _toggle),
                ),
              ],
            ),
            if (on && badge != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.blueSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1,
                    ),
                    child: Text(
                      badge,
                      style: AppTypography.label.toTextStyle(color: c.blue),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fenêtre de consentement de la vitrine : case non cochée, « Activer »
/// grisé tant qu'elle ne l'est pas. `true` si la personne consent.
Future<bool> showShowcaseConsent(BuildContext context) async {
  final consented = await showDialog<bool>(
    context: context,
    builder: (_) => const _ShowcaseConsentDialog(),
  );
  return consented ?? false;
}

class _ShowcaseConsentDialog extends StatefulWidget {
  const _ShowcaseConsentDialog();

  @override
  State<_ShowcaseConsentDialog> createState() => _ShowcaseConsentDialogState();
}

class _ShowcaseConsentDialogState extends State<_ShowcaseConsentDialog> {
  // Jamais pré-cochée (règle du projet).
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.showcaseConsentTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.showcaseConsentText),
            const SizedBox(height: AppSpacing.space3),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              title: Text(
                l10n.showcaseConsentCheckbox,
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.showcaseConsentCancel),
        ),
        FilledButton(
          onPressed: _accepted ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.showcaseConsentConfirm),
        ),
      ],
    );
  }
}

class _NotificationPreferences extends ConsumerWidget {
  const _NotificationPreferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(notificationPreferencesProvider);
    final list = prefs.value?.data;
    if (list == null) {
      return AppCard(
        child: prefs.hasError
            ? Text(saveErrorMessage(l10n, prefs.error! as ApiException))
            : const SizedBox(height: 120),
      );
    }
    return SettingsGroup(
      children: [
        for (final pref in list.where((p) => !p.locked))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Semantics(
              label: l10n.notificationSwitchLabel(pref.category.label(l10n)),
              child: AppSwitchTile(
                title: pref.category.label(l10n),
                value: pref.enabled,
                onChanged: (enabled) async {
                  try {
                    await ref
                        .read(notificationPreferencesProvider.notifier)
                        .toggle(pref.category, enabled: enabled);
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      showSnack(context, saveErrorMessage(l10n, error));
                    }
                  }
                },
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            l10n.notificationsLockedNote,
            style: context.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Notifications coupées sur ce téléphone (refusées, ou « Plus tard ») :
/// un bouton pour les autoriser, et sinon le chemin des réglages.
class PushPermissionBanner extends ConsumerStatefulWidget {
  const PushPermissionBanner({super.key});

  @override
  ConsumerState<PushPermissionBanner> createState() =>
      _PushPermissionBannerState();
}

class _PushPermissionBannerState extends ConsumerState<PushPermissionBanner> {
  bool _busy = false;

  Future<void> _allow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final permission = await ref.read(pushServiceProvider).requestPermission();
    if (permission == PushPermission.granted) {
      await ref.read(pushControllerProvider.notifier).registerIfAllowed();
    } else if (Platform.isIOS) {
      // Refus déjà donné : iOS ne redemande plus, on ouvre les réglages.
      await ref.read(deviceServicesProvider).openUrl('app-settings:');
    } else if (mounted) {
      showSnack(context, l10n.pushDisabledSettings);
    }
    ref.invalidate(pushPermissionProvider);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final permission = ref.watch(pushPermissionProvider).value;
    if (permission == null || permission == PushPermission.granted) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: AppCard(
        color: c.redSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pushDisabledText, style: context.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            AppButton.secondary(
              label: l10n.pushDisabledEnable,
              icon: LucideIcons.bell,
              compact: true,
              loading: _busy,
              onPressed: _allow,
            ),
          ],
        ),
      ),
    );
  }
}
