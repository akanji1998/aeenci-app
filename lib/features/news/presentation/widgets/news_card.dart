import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/news.dart';

/// Actualité dans une liste : vignette, titre, date. Ouvre l'article.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news});

  final News news;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final image = news.imageUrl;
    final placeholder = Container(
      width: 72,
      height: 72,
      color: c.greenSoft,
      child: Icon(LucideIcons.newspaper, color: c.green),
    );
    return MergeSemantics(
      child: AppCard(
        onTap: () => context.push(AppRoutes.newsDetail(news.slug)),
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: image == null
                    ? placeholder
                    : CachedNetworkImage(
                        imageUrl: image,
                        width: 72,
                        height: 72,
                        // Image réduite en mémoire : téléphones modestes.
                        memCacheWidth: 216,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => placeholder,
                        errorWidget: (_, _, _) => placeholder,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title, style: context.textTheme.titleMedium),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).dateShort(news.publishedAt.toLocal()),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
