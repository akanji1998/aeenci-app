import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/utils/device_services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/news.dart';
import 'news_providers.dart';
import 'widgets/news_card.dart';

/// Actualités publiées, de la plus récente à la plus ancienne.
class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenNews)),
      body: AsyncView<NewsListState>(
        value: ref.watch(newsListProvider),
        onRetry: () => ref.invalidate(newsListProvider),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => ref.refresh(newsListProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              if (state.items.isEmpty)
                EmptyState(icon: LucideIcons.newspaper, title: l10n.newsEmpty),
              for (final news in state.items) ...[
                NewsCard(news: news),
                const SizedBox(height: AppSpacing.space3),
              ],
              if (state.loadMoreError != null)
                Text(
                  errorMessage(l10n, state.loadMoreError!),
                  style: context.textTheme.bodySmall?.copyWith(color: c.danger),
                ),
              if (state.hasMore)
                AppButton.text(
                  label: l10n.newsMore,
                  loading: state.loadingMore,
                  onPressed: () =>
                      ref.read(newsListProvider.notifier).loadMore(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un article : image, date, corps en Markdown (sans HTML interprété).
class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(newsDetailProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenNewsDetail)),
      body: value.error is NotFoundException
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: LucideIcons.newspaper,
                  title: l10n.newsNotFound,
                ),
              ),
            )
          : AsyncView<News>(
              value: value,
              onRetry: () => ref.invalidate(newsDetailProvider(slug)),
              builder: (context, news) => _Article(news: news),
            ),
    );
  }
}

class _Article extends ConsumerWidget {
  const _Article({required this.news});

  final News news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = context.colors;
    final image = news.imageUrl;
    final width = MediaQuery.sizeOf(context).width;
    final pixels = (width * MediaQuery.devicePixelRatioOf(context)).round();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      children: [
        if (image != null)
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                memCacheWidth: pixels,
                placeholder: (_, _) => ColoredBox(color: c.greenSoft),
                errorWidget: (_, _, _) => ColoredBox(color: c.greenSoft),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  news.title,
                  style: context.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                l10n.newsPublished(news.publishedAt.toLocal()),
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space4),
              MarkdownBody(
                data: news.body,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: context.textTheme.bodyLarge,
                  a: context.textTheme.bodyLarge?.copyWith(
                    color: c.link,
                    decoration: TextDecoration.underline,
                  ),
                  h2: context.textTheme.titleLarge,
                  h3: context.textTheme.titleMedium,
                  listBullet: context.textTheme.bodyLarge,
                ),
                onTapLink: (text, href, title) {
                  if (href != null && href.startsWith('https://')) {
                    ref.read(deviceServicesProvider).openUrl(href);
                  }
                },
                // Images de l'API seulement, mises en cache et réduites.
                imageBuilder: (uri, title, alt) => uri.scheme == 'https'
                    ? CachedNetworkImage(
                        imageUrl: uri.toString(),
                        memCacheWidth: pixels,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
