import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/utils/external_links.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/app_config.dart';
import 'app_gate_controller.dart';

/// Écran bloquant : la version installée est trop ancienne.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gate = ref.watch(appGateControllerProvider);
    final config = gate is GateUpdateRequired ? gate.config : null;
    final storeUrl = config == null
        ? null
        : defaultTargetPlatform == TargetPlatform.iOS
        ? config.storeUrls.ios
        : config.storeUrls.android;
    return _GateLayout(
      icon: LucideIcons.download,
      title: l10n.updateRequiredTitle,
      message: l10n.updateRequiredMessage,
      supportEmail: config?.supportEmail,
      action: AppButton(
        label: l10n.updateRequiredAction,
        expand: true,
        onPressed: storeUrl == null ? null : () => openExternal(storeUrl),
      ),
    );
  }
}

/// Écran bloquant : maintenance annoncée par `/app/config`.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gate = ref.watch(appGateControllerProvider);
    final AppConfig? config = gate is GateMaintenance ? gate.config : null;
    return _GateLayout(
      icon: LucideIcons.wrench,
      title: l10n.maintenanceTitle,
      message: config?.maintenanceMessage ?? l10n.maintenanceDefaultMessage,
      supportEmail: config?.supportEmail,
      action: AppButton.secondary(
        label: l10n.retry,
        expand: true,
        onPressed: () => ref.read(appGateControllerProvider.notifier).check(),
      ),
    );
  }
}

class _GateLayout extends StatelessWidget {
  const _GateLayout({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.supportEmail,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;
  final String? supportEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space12,
          ),
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/logos/aeenci-symbole.svg',
                width: 72,
                height: 72,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Center(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.greenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Icon(icon, size: 32, color: c.green),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.space8),
            action,
            if (supportEmail != null) ...[
              const SizedBox(height: AppSpacing.space6),
              Text(
                l10n.contactSupport(supportEmail!),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
