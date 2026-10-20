import 'package:aeenci_app/core/mock/mock_content.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/card/domain/card_rules.dart';
import 'package:aeenci_app/features/card/domain/member_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 20, 12);

  MemberCard cardExpiringIn(Duration delay) => MemberCard.fromJson({
    ...MockPersona.member.cardJson(now),
    'qr_expires_at': now.add(delay).toIso8601String(),
  });

  group('renouvellement', () {
    test('plus de 7 jours avant l\'expiration : pas de renouvellement', () {
      expect(
        shouldRenewCard(cardExpiringIn(const Duration(days: 30)), now),
        isFalse,
      );
      expect(
        shouldRenewCard(
          cardExpiringIn(const Duration(days: 7, minutes: 1)),
          now,
        ),
        isFalse,
      );
    });

    test('moins de 7 jours : renouvellement', () {
      expect(
        shouldRenewCard(
          cardExpiringIn(const Duration(days: 6, hours: 23)),
          now,
        ),
        isTrue,
      );
      expect(
        shouldRenewCard(cardExpiringIn(const Duration(hours: 1)), now),
        isTrue,
      );
    });

    test('carte expirée : renouvellement', () {
      expect(
        shouldRenewCard(cardExpiringIn(-const Duration(days: 2)), now),
        isTrue,
      );
    });
  });

  test('expiration', () {
    expect(
      isCardExpired(cardExpiringIn(const Duration(seconds: 1)), now),
      isFalse,
    );
    expect(isCardExpired(cardExpiringIn(Duration.zero), now), isTrue);
    expect(
      isCardExpired(cardExpiringIn(-const Duration(days: 1)), now),
      isTrue,
    );
  });
}
