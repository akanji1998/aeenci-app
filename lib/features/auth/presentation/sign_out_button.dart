import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/components/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// « Se déconnecter » : jeton révoqué, jeton et cache effacés.
class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({super.key});

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      label: AppLocalizations.of(context).signOut,
      icon: LucideIcons.logOut,
      loading: _busy,
      expand: true,
      onPressed: () async {
        setState(() => _busy = true);
        await ref.read(sessionControllerProvider.notifier).signOut();
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}
