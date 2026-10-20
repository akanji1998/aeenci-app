import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/event.dart';
import 'event_actions.dart';

/// « mar. 1 nov. · 09:00 · Lieu ».
String eventMeta(AppLocalizations l10n, Event event) {
  final start = event.startsAt.toLocal();
  return [
    l10n.eventDateTime(start, start),
    if (event.location != null) event.location!,
  ].join(' · ');
}

/// Bandeau de couleur (ou photo) avec l'étiquette du type.
class EventBand extends StatelessWidget {
  const EventBand({super.key, required this.event, this.height = 64});

  final Event event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = eventTypeColors(context.colors, event.type);
    final image = event.imageUrl;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image == null)
            ColoredBox(color: colors.band)
          else
            CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              placeholder: (_, _) => ColoredBox(color: colors.band),
              errorWidget: (_, _, _) => ColoredBox(color: colors.band),
            ),
          Positioned(
            left: AppSpacing.space4,
            bottom: AppSpacing.space3,
            child: EventTagBadge(type: event.type),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un événement à venir (maquette `app-evenements`).
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.registration});

  final Event event;
  final Registration? registration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.go(AppRoutes.eventDetail(event.slug)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(child: EventBand(event: event)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space3,
                    AppSpacing.space4,
                    0,
                  ),
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: context.textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          eventMeta(l10n, event),
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                RegisterButton(event: event, registration: registration),
                if (registration != null) AddToCalendarButton(event: event),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
