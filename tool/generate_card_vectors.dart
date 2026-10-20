// Génère test/fixtures/card_vectors.json : cartes de membre signées avec la
// clé Ed25519 de TEST (graine 0, 1, …, 31, voir
// lib/core/mock/mock_card_signer.dart), pour les tests de la vérification
// locale du scan. Ed25519 est déterministe : libsodium (backend PHP) donne
// les mêmes signatures pour la même graine. À remplacer par les vecteurs du
// backend dès qu'il les fournit.
//
//   dart run tool/generate_card_vectors.dart

import 'dart:convert';
import 'dart:io';

import 'package:aeenci_app/core/mock/mock_card_signer.dart';

Future<void> main() async {
  final issued = DateTime.utc(2026, 10, 1);
  final valid = await signMockCard(
    memberId: 42,
    memberNumber: 'TEST-0042',
    issuedAt: issued,
    expiresAt: DateTime.utc(2099, 1, 1),
  );
  final expired = await signMockCard(
    memberId: 43,
    memberNumber: 'TEST-0043',
    issuedAt: DateTime.utc(2020, 1, 1),
    expiresAt: DateTime.utc(2020, 1, 31),
  );
  final otherKey = await signMockCard(
    memberId: 44,
    memberNumber: 'TEST-0044',
    issuedAt: issued,
    expiresAt: DateTime.utc(2099, 1, 1),
    seed: List<int>.filled(32, 7),
  );
  // Données modifiées après signature (matricule changé).
  final parts = valid.split('.');
  final forgedData = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'mid': 42,
            'num': 'TEST-9999',
            'iat': issued.millisecondsSinceEpoch ~/ 1000,
            'exp': DateTime.utc(2099).millisecondsSinceEpoch ~/ 1000,
          }),
        ),
      )
      .replaceAll('=', '');

  final vectors = {
    '_comment':
        'Vecteurs de TEST générés par tool/generate_card_vectors.dart avec '
        'la clé de test des mocks (jamais en production).',
    'public_key': mockCardPublicKey,
    'now': '2026-10-20T12:00:00Z',
    'cases': [
      {
        'name': 'valide',
        'qr_payload': valid,
        'expected': 'valid',
        'member_id': 42,
        'member_number': 'TEST-0042',
      },
      {
        'name': 'expiree',
        'qr_payload': expired,
        'expected': 'expired',
        'member_number': 'TEST-0043',
      },
      {'name': 'autre_cle', 'qr_payload': otherKey, 'expected': 'invalid'},
      {
        'name': 'donnees_modifiees',
        'qr_payload': '${parts[0]}.$forgedData.${parts[2]}',
        'expected': 'invalid',
      },
      {
        'name': 'signature_tronquee',
        'qr_payload': '${parts[0]}.${parts[1]}.${parts[2].substring(4)}',
        'expected': 'invalid',
      },
      {
        'name': 'mauvais_prefixe',
        'qr_payload': 'AEENCI2.${parts[1]}.${parts[2]}',
        'expected': 'invalid',
      },
      {
        'name': 'texte_quelconque',
        'qr_payload': 'https://exemple.com/carte',
        'expected': 'invalid',
      },
    ],
  };
  final file = File('test/fixtures/card_vectors.json');
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(vectors)}\n',
  );
  stdout.writeln('Écrit : ${file.path}');
}
