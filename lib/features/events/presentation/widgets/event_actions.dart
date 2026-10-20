import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_button.dart';
import '../../../../core/design/components/error_state.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/utils/device_services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../domain/event.dart';
import '../events_providers.dart';

/// Genre de la fiche pour l'accord (`female` / `other`).
String sessionGender(WidgetRef ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SessionMember && session.member.gender == Gender.female
      ? 'female'
      : 'other';
}

/// Explication d'un échec d'inscription ou d'annulation.
String registrationErrorMessage(AppLocalizations l10n, ApiException error) {
  if (error is ValidationException) {
    // Message du backend s'il y en a un, sinon le nôtre.
    return error.errorFor('event_slug') ??
        error.errorFor('event') ??
        error.errorFor('registration') ??
        error.message ??
        l10n.errorUnknown;
  }
  return errorMessage(l10n, error);
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Demande confirmation avant d'annuler une inscription.
Future<bool> confirmCancel(BuildContext context, String title) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.eventCancelTitle),
      content: Text(l10n.eventCancelMessage(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.eventCancelKeep),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.eventCancelConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Annule [registration] après confirmation ; message de résultat.
Future<void> cancelRegistration(
  BuildContext context,
  WidgetRef ref,
  Registration registration,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await confirmCancel(context, registration.event.title)) return;
  try {
    await ref.read(registrationActionsProvider).cancel(registration);
    if (context.mounted) _snack(context, l10n.eventCancelledDone);
  } on ApiException catch (error) {
    if (context.mounted) _snack(context, registrationErrorMessage(l10n, error));
  }
}

/// « S'inscrire », « Inscrit ✓ » (toucher pour annuler) ou « Inscriptions
/// fermées ».
class RegisterButton extends ConsumerStatefulWidget {
  const RegisterButton({
    super.key,
    required this.event,
    required this.registration,
  });

  final Event event;

  /// Inscription du membre à cet événement, s'il y en a une.
  final Registration? registration;

  @override
  ConsumerState<RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends ConsumerState<RegisterButton> {
  bool _busy = false;

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(registrationActionsProvider).register(widget.event.slug);
      if (mounted) _snack(context, l10n.eventRegisteredDone);
    } on ApiException catch (error) {
      if (mounted) _snack(context, registrationErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Registration registration) async {
    setState(() => _busy = true);
    try {
      await cancelRegistration(context, ref, registration);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final registration = widget.registration;

    if (registration != null) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.greenSoft,
          foregroundColor: c.green,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          textStyle: AppTypography.small.toTextStyle().copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: _busy || !registration.canCancel
            ? null
            : () => _cancel(registration),
        icon: const Icon(LucideIcons.check, size: 18),
        label: Text(l10n.eventRegistered(sessionGender(ref))),
      );
    }
    if (!widget.event.registrationOpen) {
      return AppButton(
        label: l10n.eventRegistrationClosed,
        onPressed: null,
        compact: true,
      );
    }
    return AppButton(
      label: l10n.eventRegister,
      loading: _busy,
      compact: true,
      onPressed: _register,
    );
  }
}

/// « Ajouter au calendrier » : ouvre le calendrier du téléphone.
class AddToCalendarButton extends ConsumerWidget {
  const AddToCalendarButton({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppButton.secondary(
      label: l10n.eventAddToCalendar,
      icon: LucideIcons.calendarPlus,
      compact: true,
      onPressed: () async {
        final opened = await ref
            .read(deviceServicesProvider)
            .addToCalendar(
              title: event.title,
              description: event.summary,
              location: event.location,
              start: event.startsAt,
              end: event.endsAt ?? event.startsAt.add(const Duration(hours: 2)),
            );
        if (!opened && context.mounted) {
          _snack(context, l10n.eventCalendarFailed);
        }
      },
    );
  }
}

/// Couleurs du bandeau et de l'étiquette selon le type (maquette).
({Color band, Color tagBackground, Color tagForeground}) eventTypeColors(
  AppColors c,
  EventType type,
) => switch (type) {
  EventType.joe => (
    band: c.green,
    tagBackground: c.surfaceRaised,
    tagForeground: c.green,
  ),
  EventType.employmentDay => (
    band: c.blue,
    tagBackground: c.surfaceRaised,
    tagForeground: c.blue,
  ),
  EventType.impact => (
    band: c.greenSoft,
    tagBackground: c.green,
    tagForeground: c.onGreen,
  ),
  EventType.other || EventType.unknown => (
    band: c.blueSoft,
    tagBackground: c.blue,
    tagForeground: c.onBlue,
  ),
};

/// Étiquette courte des cartes : JOE, Emploi, Impact, Autre.
String eventTag(AppLocalizations l10n, EventType type) => switch (type) {
  EventType.joe => l10n.eventTagJoe,
  EventType.employmentDay => l10n.eventTagEmployment,
  EventType.impact => l10n.eventTagImpact,
  EventType.other || EventType.unknown => l10n.eventTagOther,
};

/// Étiquette en pilule.
class EventTagBadge extends StatelessWidget {
  const EventTagBadge({super.key, required this.type});

  final EventType type;

  @override
  Widget build(BuildContext context) {
    final colors = eventTypeColors(context.colors, type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tagBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        child: Text(
          eventTag(AppLocalizations.of(context), type),
          style: AppTypography.label.toTextStyle(color: colors.tagForeground),
        ),
      ),
    );
  }
}
