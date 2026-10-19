import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// `GET /app/config` : versions exigées, maintenance, clé des cartes.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    /// En dessous, mise à jour obligatoire.
    required String minVersion,
    required String latestVersion,
    required StoreUrls storeUrls,
    required bool maintenance,
    String? maintenanceMessage,

    /// Clé publique Ed25519 des cartes, en base64.
    required String cardPublicKey,
    String? supportEmail,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}

@freezed
abstract class StoreUrls with _$StoreUrls {
  const factory StoreUrls({required String android, required String ios}) =
      _StoreUrls;

  factory StoreUrls.fromJson(Map<String, dynamic> json) =>
      _$StoreUrlsFromJson(json);
}
