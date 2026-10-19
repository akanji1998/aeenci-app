import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// `GET /me/notifications`.
@freezed
abstract class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required int id,
    @JsonKey(unknownEnumValue: NotificationCategory.unknown)
    required NotificationCategory category,
    required String title,
    required String body,

    /// Écran à ouvrir (`/evenements/{slug}`, `/cotisations`…).
    String? route,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  bool get isRead => readAt != null;
}

/// `GET /me/notification-preferences`.
@freezed
abstract class NotificationPreference with _$NotificationPreference {
  const factory NotificationPreference({
    @JsonKey(unknownEnumValue: NotificationCategory.unknown)
    required NotificationCategory category,
    required bool enabled,

    /// `account` est toujours activée et verrouillée.
    required bool locked,
  }) = _NotificationPreference;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);
}

/// Corps de `POST /me/devices`.
@freezed
abstract class DeviceRegistration with _$DeviceRegistration {
  const factory DeviceRegistration({
    required String token,
    required DevicePlatform platform,
    required String appVersion,
    @Default('fr') String locale,
  }) = _DeviceRegistration;

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistrationFromJson(json);
}
