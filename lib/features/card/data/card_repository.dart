import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_card_signer.dart';
import '../../../core/mock/mock_content.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/member_card.dart';

part 'card_repository.g.dart';

/// Carte de membre (`GET /me/card`, membre admis seulement).
abstract interface class CardRepository {
  Future<MemberCard> fetchCard();
}

class ApiCardRepository implements CardRepository {
  const ApiCardRepository(this._api);

  final ApiClient _api;

  @override
  Future<MemberCard> fetchCard() =>
      _api.getData('/me/card', MemberCard.fromJson);
}

class MockCardRepository implements CardRepository {
  const MockCardRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<MemberCard> fetchCard() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final now = DateTime.now();
    final json = persona.cardJson(now);
    // Carte signée avec la clé de test : le scan du bureau la vérifie.
    json['qr_payload'] = await signMockCard(
      memberId: persona.meJson['id']! as int,
      memberNumber: (persona.meJson['member_number'] as String?) ?? '',
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );
    return MemberCard.fromJson(json);
  }
}

@Riverpod(keepAlive: true)
CardRepository cardRepository(Ref ref) => ref.watch(envConfigProvider).useMocks
    ? MockCardRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiCardRepository(ref.watch(apiClientProvider));
