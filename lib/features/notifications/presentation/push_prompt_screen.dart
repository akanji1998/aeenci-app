import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'notifications_providers.dart';
import 'push_controller.dart';

/// Explication avant la demande du système, après la première connexion.
class PushPromptScreen extends ConsumerStatefulWidget {
  const PushPromptScreen({super.key});

  @override
  ConsumerState<PushPromptScreen> createState() => _PushPromptScreenState();
}

class _PushPromptScreenState extends ConsumerState<PushPromptScreen> {
  bool _busy = false;

  Future<void> _answer({required bool enable}) async {
    setState(() => _busy = true);
    // Une seule fois par compte, quelle que soit la réponse.
    await ref.read(cacheStoreProvider).write(pushPromptDismissedKey, true);
    if (enable) {
      final permission = await ref
          .read(pushServiceProvider)
          .requestPermission();
      if (permission == PushPermission.granted) {
        await ref.read(pushControllerProvider.notifier).registerIfAllowed();
      }
    }
    ref
      ..invalidate(pushPromptProvider)
      ..invalidate(pushPermissionProvider);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.space6 * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: c.greenSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.bellRing,
                          size: 40,
                          color: c.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.pushPromptTitle,
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.pushPromptText,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    l10n.pushPromptSettings,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: c.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AppButton(
                    label: l10n.pushPromptEnable,
                    icon: LucideIcons.bell,
                    expand: true,
                    loading: _busy,
                    onPressed: () => _answer(enable: true),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  AppButton.text(
                    label: l10n.pushPromptLater,
                    expand: true,
                    onPressed: _busy ? null : () => _answer(enable: false),
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

/// Dans les onglets : ouvre l'écran d'explication une fois, si besoin.
class PushPromptLauncher extends ConsumerStatefulWidget {
  const PushPromptLauncher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushPromptLauncher> createState() => _PushPromptLauncherState();
}

class _PushPromptLauncherState extends ConsumerState<PushPromptLauncher> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(pushPromptProvider, (_, next) {
      if (_shown || next.value != true || !mounted) return;
      _shown = true;
      context.push(AppRoutes.pushPrompt);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
