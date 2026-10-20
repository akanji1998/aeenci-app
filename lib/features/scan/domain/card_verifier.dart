import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Résultat de la vérification locale d'une carte, avant l'envoi.
sealed class CardCheck {
  const CardCheck();
}

/// Signature juste et carte en cours de validité.
final class CardValid extends CardCheck {
  const CardValid({
    required this.memberId,
    required this.memberNumber,
    required this.expiresAt,
  });

  final int memberId;
  final String memberNumber;
  final DateTime expiresAt;
}

/// Signature juste, mais carte expirée : le membre doit rouvrir sa carte.
final class CardExpired extends CardCheck {
  const CardExpired({required this.memberNumber});

  final String memberNumber;
}

/// Pas une carte AEENCI : format inconnu ou signature fausse.
final class CardInvalid extends CardCheck {
  const CardInvalid();
}

/// Décode le base64 et le base64url, avec ou sans remplissage `=`.
@visibleForTesting
List<int> decodeBase64Any(String value) {
  final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  return base64.decode(base64.normalize(normalized));
}

/// Vérifie une carte sans réseau (contrat : « Format de `qr_payload` »).
///
/// `AEENCI1.<données>.<signature>` : `<données>` est le JSON
/// `{"mid", "num", "iat", "exp"}` en base64url, `<signature>` la signature
/// Ed25519 de la chaîne `AEENCI1.<données>`, en base64url. [publicKey] est
/// `card_public_key` de `/app/config`, en base64. Le backend revérifie
/// toujours à la réception : ceci ne sert qu'au retour immédiat.
class CardVerifier {
  CardVerifier(String publicKey) : _publicKey = _decodeKey(publicKey);

  static const prefix = 'AEENCI1';
  static final _algorithm = Ed25519();

  final SimplePublicKey? _publicKey;

  static SimplePublicKey? _decodeKey(String key) {
    try {
      final bytes = decodeBase64Any(key);
      if (bytes.length != 32) return null;
      return SimplePublicKey(bytes, type: KeyPairType.ed25519);
    } on FormatException {
      return null;
    }
  }

  /// `false` si la clé de `/app/config` est illisible : aucune carte ne
  /// peut alors être vérifiée sur le téléphone.
  bool get hasKey => _publicKey != null;

  Future<CardCheck> verify(String payload, {required DateTime now}) async {
    final key = _publicKey;
    final parts = payload.trim().split('.');
    if (key == null || parts.length != 3 || parts[0] != prefix) {
      return const CardInvalid();
    }
    try {
      final signature = decodeBase64Any(parts[2]);
      if (signature.length != 64) return const CardInvalid();
      final valid = await _algorithm.verify(
        utf8.encode('${parts[0]}.${parts[1]}'),
        signature: Signature(signature, publicKey: key),
      );
      if (!valid) return const CardInvalid();

      final data = jsonDecode(utf8.decode(decodeBase64Any(parts[1])));
      if (data is! Map<String, Object?>) return const CardInvalid();
      final (mid, num, exp) = (data['mid'], data['num'], data['exp']);
      if (mid is! int || num is! String || exp is! int) {
        return const CardInvalid();
      }
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
        isUtc: true,
      );
      if (!now.toUtc().isBefore(expiresAt)) {
        return CardExpired(memberNumber: num);
      }
      return CardValid(memberId: mid, memberNumber: num, expiresAt: expiresAt);
    } on FormatException {
      return const CardInvalid();
    }
  }
}
