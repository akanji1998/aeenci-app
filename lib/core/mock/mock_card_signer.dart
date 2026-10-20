import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Clé Ed25519 **de test**, publique et documentée : elle signe les cartes
/// des mocks et les vecteurs de `test/fixtures/card_vectors.json`. Elle ne
/// sert jamais en production (le backend a sa propre clé privée).
/// Graine : les octets 0, 1, 2, …, 31.
final mockCardSeed = List<int>.generate(32, (i) => i);

/// `card_public_key` des mocks, dérivée de [mockCardSeed] (base64).
const mockCardPublicKey = 'A6EHv/POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg=';

String _b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Fabrique un `qr_payload` signé, comme le backend. Mocks et tests
/// seulement : l'application ne fabrique jamais le QR code qu'elle affiche.
Future<String> signMockCard({
  required int memberId,
  required String memberNumber,
  required DateTime issuedAt,
  required DateTime expiresAt,
  List<int>? seed,
}) async {
  final keyPair = await Ed25519().newKeyPairFromSeed(seed ?? mockCardSeed);
  final data = _b64url(
    utf8.encode(
      jsonEncode({
        'mid': memberId,
        'num': memberNumber,
        'iat': issuedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
        'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000,
      }),
    ),
  );
  final message = 'AEENCI1.$data';
  final signature = await Ed25519().sign(
    utf8.encode(message),
    keyPair: keyPair,
  );
  return '$message.${_b64url(signature.bytes)}';
}
