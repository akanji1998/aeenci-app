import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/device_services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/event.dart';
import '../domain/events_rules.dart';
import 'events_providers.dart';
import 'widgets/event_actions.dart';
import 'widgets/event_card.dart';

/// Détail d'un événement (`/evenements/:slug`).
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registrations =
        ref.watch(myRegistrationsProvider).value?.data ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenEventDetail)),
      body: AsyncView<Event>(
        value: ref.watch(eventDetailProvider(slug)),
        onRetry: () => ref.invalidate(eventDetailProvider(slug)),
        builder: (context, event) {
          final registration = registrationFor(registrations, event.slug);
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.space8),
            children: [
              ExcludeSemantics(child: EventBand(event: event, height: 140)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      event.type.label(l10n),
                      style: AppTypography.label.toTextStyle(
                        color: context.colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Semantics(
                      header: true,
                      child: Text(
                        event.title,
                        style: context.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _InfoRow(
                      icon: LucideIcons.calendar,
                      text: l10n.eventDateTime(
                        event.startsAt.toLocal(),
                        event.startsAt.toLocal(),
                      ),
                    ),
                    if (event.location != null)
                      _InfoRow(
                        icon: LucideIcons.mapPin,
                        text: event.location!,
                        actionLabel: l10n.eventOpenMap,
                        onTap: () async {
                          final opened = await ref
                              .read(deviceServicesProvider)
                              .openMap(event.location!);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.eventMapFailed)),
                            );
                          }
                        },
                      ),
                    if (event.audience != null)
                      _InfoRow(
                        icon: LucideIcons.users,
                        text: '${l10n.eventAudience} : ${event.audience!}',
                      ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      event.description,
                      style: context.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: [
                        RegisterButton(
                          event: event,
                          registration: registration,
                        ),
                        if (registration != null)
                          AddToCalendarButton(event: event),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: c.inkMuted)),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: onTap == null ? null : c.link,
                decoration: onTap == null ? null : TextDecoration.underline,
                decorationColor: c.link,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      hint: actionLabel,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: content,
        ),
      ),
    );
  }
}
