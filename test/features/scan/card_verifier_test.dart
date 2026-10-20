import 'dart:convert';
import 'dart:io';

import 'package:aeenci_app/core/mock/mock_card_signer.dart';
import 'package:aeenci_app/features/scan/domain/card_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vectors =
      jsonDecode(File('test/fixtures/card_vectors.json').readAsStringSync())
          as Map<String, Object?>;
  final verifier = CardVerifier(vectors['public_key']! as String);
  final now = DateTime.parse(vectors['now']! as String);

  test('la clé de test se lit', () => expect(verifier.hasKey, isTrue));

  for (final raw in vectors['cases']! as List<Object?>) {
    final c = raw! as Map<String, Object?>;
    test('vecteur « ${c['name']} » : ${c['expected']}', () async {
      final result = await verifier.verify(
        c['qr_payload']! as String,
        now: now,
      );
      switch (c['expected']) {
        case 'valid':
          expect(result, isA<CardValid>());
          final valid = result as CardValid;
          expect(valid.memberId, c['member_id']);
          expect(valid.memberNumber, c['member_number']);
        case 'expired':
          expect(result, isA<CardExpired>());
          expect((result as CardExpired).memberNumber, c['member_number']);
        default:
          expect(result, isA<CardInvalid>());
      }
    });
  }

  test('expire à la seconde près', () async {
    final exp = DateTime.utc(2026, 10, 20, 12);
    final card = await signMockCard(
      memberId: 1,
      memberNumber: 'TEST-0001',
      issuedAt: exp.subtract(const Duration(days: 30)),
      expiresAt: exp,
    );
    expect(
      await verifier.verify(
        card,
        now: exp.subtract(const Duration(seconds: 1)),
      ),
      isA<CardValid>(),
    );
    expect(await verifier.verify(card, now: exp), isA<CardExpired>());
  });

  test('clé illisible : aucune carte n\'est acceptée', () async {
    final broken = CardVerifier('clé-de-test-non-valide');
    expect(broken.hasKey, isFalse);
    final card = (vectors['cases']! as List<Object?>).first! as Map;
    expect(
      await broken.verify(card['qr_payload']! as String, now: now),
      isA<CardInvalid>(),
    );
  });

  test('base64 et base64url, avec ou sans remplissage', () {
    expect(decodeBase64Any('-_8'), [251, 255]);
    expect(decodeBase64Any('+/8='), [251, 255]);
  });
}
