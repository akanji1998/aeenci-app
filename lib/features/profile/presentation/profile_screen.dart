import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/router/placeholder_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/sign_out_button.dart';

/// Profil provisoire : liens vers les sous-écrans (lot 6 à venir).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.screenProfile,
      links: [
        PlaceholderLink(l10n.screenProfileSheet, AppRoutes.profileSheet),
        PlaceholderLink(l10n.screenEducation, AppRoutes.profileEducation),
        PlaceholderLink(l10n.screenProfessionalProfile, AppRoutes.profilePro),
        PlaceholderLink(l10n.screenShowcase, AppRoutes.profileShowcase),
        PlaceholderLink(l10n.screenSettings, AppRoutes.profileSettings),
      ],
      footer: const SignOutButton(),
    );
  }
}
