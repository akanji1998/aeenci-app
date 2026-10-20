import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/config/env_config.dart';
import '../../../app/theme_mode_controller.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_badge.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/design/components/offline_banner.dart';
import '../../../core/design/components/skeleton.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../app_config/presentation/app_gate_controller.dart';
import '../../notifications/presentation/notifications_providers.dart';

/// Page de démonstration du design system (lot 0), dans les deux thèmes.
class DesignDemoScreen extends ConsumerWidget {
  const DesignDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(envConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.demoTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            _FlavorBanner(config: config),
            _Section(
              title: l10n.demoSectionTheme,
              child: const _ThemeSelector(),
            ),
            _Section(title: l10n.demoSectionLogo, child: const _Logos()),
            _Section(
              title: l10n.demoSectionTypography,
              child: const _Typography(),
            ),
            _Section(title: l10n.demoSectionColors, child: const _Swatches()),
            _Section(title: l10n.demoSectionButtons, child: const _Buttons()),
            _Section(
              title: l10n.demoSectionBadges,
              child: Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  AppBadge(l10n.demoBadgeGreen),
                  AppBadge(l10n.demoBadgeBlue, tone: AppBadgeTone.blue),
                  AppBadge(l10n.demoBadgeRed, tone: AppBadgeTone.red),
                ],
              ),
            ),
            _Section(title: l10n.demoSectionCard, child: const _DemoCard()),
            _Section(title: l10n.demoSectionFields, child: const _Fields()),
            _Section(title: l10n.demoSectionIcons, child: const _Icons()),
            _Section(title: l10n.demoSectionStates, child: const _States()),
            if (config.useMocks)
              _Section(title: l10n.demoSectionMocks, child: const _Mocks()),
            if (ref.watch(pushServiceProvider) is ManualPushService)
              _Section(title: l10n.devPushTitle, child: const _PushDemo()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.textTheme.headlineMedium),
          ),
          const SizedBox(height: AppSpacing.space4),
          child,
        ],
      ),
    );
  }
}

class _FlavorBanner extends StatelessWidget {
  const _FlavorBanner({required this.config});

  final EnvConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final flavor = config.flavor.name;
    final text = config.useMocks
        ? l10n.demoFlavorMocks(flavor)
        : l10n.demoFlavorApi(flavor, config.apiBaseUrl);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.blueSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(LucideIcons.flaskConical, color: c.blue),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                text,
                style: context.textTheme.bodyMedium?.copyWith(color: c.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeControllerProvider);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ThemeMode.light,
            icon: const Icon(LucideIcons.sun),
            label: Text(l10n.themeLight),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: const Icon(LucideIcons.moon),
            label: Text(l10n.themeDark),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: const Icon(LucideIcons.sunMoon),
            label: Text(l10n.themeSystem),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => ref
            .read(themeModeControllerProvider.notifier)
            .select(selection.single),
      ),
    );
  }
}

class _Logos extends StatelessWidget {
  const _Logos();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo complet sur fond clair ; version blanche sur aplat vert.
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? c.green : c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Center(
              child: SvgPicture.asset(
                isDark
                    ? 'assets/logos/aeenci-logo-blanc.svg'
                    : 'assets/logos/aeenci-logo.svg',
                height: 160,
                semanticsLabel: l10n.logoLabel,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            SvgPicture.asset(
              'assets/logos/aeenci-symbole.svg',
              width: 48,
              height: 48,
              semanticsLabel: l10n.symbolLabel,
            ),
            const SizedBox(width: AppSpacing.space3),
            Flexible(
              child: Text(
                l10n.appTitle,
                style: AppTypography.h2
                    .toTextStyle(color: c.green)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Typography extends StatelessWidget {
  const _Typography();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final samples = <(String, AppTextToken, String, Color)>[
      ('display-xl', AppTypography.displayXl, l10n.appTitle, c.green),
      ('display', AppTypography.display, l10n.motto, c.blue),
      ('h1', AppTypography.h1, l10n.demoSampleHeading, c.ink),
      ('h2', AppTypography.h2, l10n.demoSampleHeading, c.ink),
      ('h3', AppTypography.h3, l10n.demoSampleHeading, c.ink),
      ('body-lg', AppTypography.bodyLg, l10n.demoSampleBody, c.ink),
      ('body', AppTypography.body, l10n.demoSampleBody, c.ink),
      ('small', AppTypography.small, l10n.demoSampleSmall, c.inkMuted),
      ('label', AppTypography.label, l10n.demoSampleLabel, c.ink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (token, style, text, color) in samples) ...[
          // Nom technique du token, non traduit.
          Text(token, style: context.textTheme.bodySmall),
          Text(text, style: style.toTextStyle(color: color)),
          const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Noms techniques des tokens, non traduits.
    final swatches = <(String, Color)>[
      ('surface', c.surface),
      ('surface-raised', c.surfaceRaised),
      ('line', c.line),
      ('ink', c.ink),
      ('ink-muted', c.inkMuted),
      ('green', c.green),
      ('green-soft', c.greenSoft),
      ('on-green', c.onGreen),
      ('blue', c.blue),
      ('blue-soft', c.blueSoft),
      ('on-blue', c.onBlue),
      ('red', c.red),
      ('red-soft', c.redSoft),
    ];
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: [
        for (final (name, color) in swatches)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: c.line),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(name, style: context.textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(onPressed: () {}, child: Text(l10n.demoButtonPrimary)),
        const SizedBox(height: AppSpacing.space3),
        OutlinedButton(onPressed: () {}, child: Text(l10n.demoButtonSecondary)),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(onPressed: () {}, child: Text(l10n.demoButtonText)),
            FilledButton(onPressed: null, child: Text(l10n.demoButtonDisabled)),
          ],
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.demoCardTitle, style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.space2),
            Text(l10n.demoCardBody),
            const SizedBox(height: AppSpacing.space3),
            AppBadge(l10n.demoBadgeGreen),
          ],
        ),
      ),
    );
  }
}

class _Fields extends StatefulWidget {
  const _Fields();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  bool _notifications = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: l10n.demoFieldEmail,
            hintText: l10n.demoFieldEmailHint,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.demoFieldEmail,
            errorText: l10n.demoFieldError,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.demoSwitch),
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
      ],
    );
  }
}

class _Icons extends StatelessWidget {
  const _Icons();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final icons = <(IconData, String)>[
      (LucideIcons.house, l10n.iconHome),
      (LucideIcons.idCard, l10n.iconCard),
      (LucideIcons.calendar, l10n.iconEvents),
      (LucideIcons.wallet, l10n.iconContributions),
      (LucideIcons.user, l10n.iconProfile),
    ];
    return Wrap(
      spacing: AppSpacing.space4,
      runSpacing: AppSpacing.space3,
      children: [
        for (final (icon, label) in icons)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, color: c.ink)),
              const SizedBox(height: AppSpacing.space1),
              Text(label, style: context.textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.demoLoadingButton,
          loading: true,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.space4),
        OfflineBanner(updatedAt: DateTime.now()),
        const SizedBox(height: AppSpacing.space4),
        EmptyState(
          icon: LucideIcons.inbox,
          title: l10n.demoEmptyTitle,
          message: l10n.demoEmptyMessage,
          actionLabel: l10n.demoEmptyAction,
          onAction: () {},
        ),
        ErrorState(error: const NetworkException(), onRetry: () {}),
        const SkeletonList(count: 1),
      ],
    );
  }
}

class _Mocks extends ConsumerWidget {
  const _Mocks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final behavior = ref.watch(mockBehaviorControllerProvider);
    final controller = ref.read(mockBehaviorControllerProvider.notifier);
    final latencies = <Duration>[
      Duration.zero,
      const Duration(milliseconds: 400),
      const Duration(seconds: 2),
    ];
    final failures = <(MockFailure, String)>[
      (MockFailure.none, l10n.demoMockFailureNone),
      (MockFailure.network, l10n.demoMockFailureNetwork),
      (MockFailure.unauthorized, l10n.demoMockFailureUnauthorized),
      (MockFailure.validation, l10n.demoMockFailureValidation),
      (MockFailure.server, l10n.demoMockFailureServer),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demoMockLatency, style: context.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final latency in latencies)
              ChoiceChip(
                // Durée technique, non traduite.
                label: Text('${latency.inMilliseconds} ms'),
                selected: behavior.latency == latency,
                onSelected: (_) =>
                    controller.set(behavior.copyWith(latency: latency)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(l10n.demoMockConfig, style: context.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            FilterChip(
              label: Text(l10n.demoMockUpdateRequired),
              selected: behavior.updateRequired,
              onSelected: (value) =>
                  controller.set(behavior.copyWith(updateRequired: value)),
            ),
            FilterChip(
              label: Text(l10n.demoMockMaintenance),
              selected: behavior.maintenance,
              onSelected: (value) =>
                  controller.set(behavior.copyWith(maintenance: value)),
            ),
          ],
        ),
        AppButton.text(
          label: l10n.demoMockRecheck,
          onPressed: () => ref.read(appGateControllerProvider.notifier).check(),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(l10n.demoMockFailure, style: context.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final (failure, label) in failures)
              ChoiceChip(
                label: Text(label),
                selected: behavior.failure == failure,
                onSelected: (_) =>
                    controller.set(behavior.copyWith(failure: failure)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Notifications simulées (mocks) : ouverture d'un écran par sa route,
/// réception au premier plan, retour de l'écran d'explication.
class _PushDemo extends ConsumerWidget {
  const _PushDemo();

  static const _routes = [
    '/evenements/evenement-test-a-venir',
    '/cotisations',
    '/opportunites/40',
    '/actualites/actualite-test-1',
    '/profil/vitrine',
    '/carte',
    '/notifications',
    '/route-inconnue',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final push = ref.watch(pushServiceProvider) as ManualPushService;
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: [
        for (final route in _routes)
          AppButton.secondary(
            label: l10n.devPushOpen(route),
            compact: true,
            onPressed: () => push.open(PushMessage(route: route)),
          ),
        AppButton.secondary(
          label: l10n.devPushReceive,
          compact: true,
          onPressed: () => push.receive(
            const PushMessage(title: 'Notification de test', route: '/carte'),
          ),
        ),
        AppButton.text(
          label: l10n.devPushReset,
          compact: true,
          onPressed: () async {
            push.currentPermission = PushPermission.notDetermined;
            await ref.read(cacheStoreProvider).remove(pushPromptDismissedKey);
            ref
              ..invalidate(pushPromptProvider)
              ..invalidate(pushPermissionProvider);
          },
        ),
      ],
    );
  }
}
