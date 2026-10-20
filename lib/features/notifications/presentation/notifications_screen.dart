import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/app_notification.dart';
import '../domain/notification_groups.dart';
import 'notifications_providers.dart';

/// Centre de notifications (maquette `app-notifications`).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(notificationsProvider);
    final unread = value.value?.data.unreadCount ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenNotifications),
        actions: [
          if (unread > 0)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => _markAll(context, ref),
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: AsyncView<NotificationsState>(
        value: value,
        onRetry: () => ref.invalidate(notificationsProvider),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      icon: LucideIcons.bell,
                      title: l10n.notificationsEmpty,
                      message: l10n.notificationsEmptyHint,
                    ),
                  ],
                )
              : _NotificationsList(state: state),
        ),
      ),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final groups = groupNotifications(state.items, now);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        for (final (group, items) in groups) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space3,
              bottom: AppSpacing.space2,
            ),
            child: Semantics(
              header: true,
              child: Text(
                _groupLabel(l10n, group).toUpperCase(),
                style: AppTypography.label.toTextStyle(color: c.inkMuted),
              ),
            ),
          ),
          for (final item in items) ...[
            _NotificationTile(notification: item, now: now),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
        if (state.loadMoreError != null)
          Text(
            errorMessage(l10n, state.loadMoreError!),
            style: context.textTheme.bodySmall?.copyWith(color: c.danger),
          ),
        if (state.hasMore)
          AppButton.text(
            label: l10n.notificationsMore,
            loading: state.loadingMore,
            onPressed: () =>
                ref.read(notificationsProvider.notifier).loadMore(),
          ),
      ],
    );
  }

  static String _groupLabel(AppLocalizations l10n, NotificationGroup group) =>
      switch (group) {
        NotificationGroup.today => l10n.groupToday,
        NotificationGroup.yesterday => l10n.groupYesterday,
        NotificationGroup.thisWeek => l10n.groupThisWeek,
        NotificationGroup.earlier => l10n.groupEarlier,
      };
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification, required this.now});

  final AppNotification notification;
  final DateTime now;

  /// « Il y a 2 h » aujourd'hui, l'heure hier, le jour cette semaine,
  /// la date plus tôt.
  String _when(AppLocalizations l10n) {
    final created = notification.createdAt.toLocal();
    final ago = now.difference(created);
    return switch (groupOf(created, now)) {
      NotificationGroup.today =>
        ago.inMinutes < 60
            ? l10n.minutesAgo(ago.inMinutes.clamp(0, 59))
            : l10n.hoursAgo(ago.inHours),
      NotificationGroup.yesterday => l10n.timeAt(created),
      NotificationGroup.thisWeek => l10n.weekdayShort(created),
      NotificationGroup.earlier => l10n.dayMonth(created),
    };
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final n = notification;
    if (!n.isRead) {
      // Échec silencieux : la notification reste non lue, l'écran s'ouvre.
      try {
        await ref.read(notificationsProvider.notifier).markRead(n.id);
      } on ApiException {
        // Rien : pas de quoi bloquer l'ouverture.
      }
    }
    if (n.route != null && context.mounted) {
      await context.push(safePushRoute(n.route));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final n = notification;
    final unread = !n.isRead;
    final (icon, fg, bg) = switch (n.category) {
      NotificationCategory.account => (
        LucideIcons.badgeCheck,
        c.green,
        c.greenSoft,
      ),
      NotificationCategory.events => (LucideIcons.calendar, c.blue, c.blueSoft),
      NotificationCategory.meetings => (LucideIcons.users, c.blue, c.blueSoft),
      NotificationCategory.contributions => (
        LucideIcons.creditCard,
        c.green,
        c.greenSoft,
      ),
      NotificationCategory.news => (LucideIcons.newspaper, c.red, c.redSoft),
      NotificationCategory.opportunities => (
        LucideIcons.briefcase,
        c.blue,
        c.blueSoft,
      ),
      NotificationCategory.announcements => (
        LucideIcons.megaphone,
        c.red,
        c.redSoft,
      ),
      NotificationCategory.unknown => (LucideIcons.bell, c.inkMuted, c.line),
    };
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: n.route != null || unread,
      label: [
        if (unread) l10n.notificationUnread,
        n.category.label(l10n),
        n.title,
        n.body,
        _when(l10n),
      ].join('. '),
      excludeSemantics: true,
      child: Material(
        color: unread ? c.surfaceRaised : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: unread ? c.line : Colors.transparent),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _open(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: fg),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                      Text(n.body, style: context.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.space1),
                      Text(_when(l10n), style: context.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.space2,
                      top: AppSpacing.space1,
                    ),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
