import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../../core/mock/mock_pdf.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/contribution.dart';

part 'contributions_repository.g.dart';

/// Cotisations, paiements et reçus du membre. L'application n'encaisse
/// rien : elle affiche ce que le trésorier a enregistré.
abstract interface class ContributionsRepository {
  /// `GET /me/contributions` : situation par année.
  Future<List<Contribution>> fetchContributions();

  /// `GET /me/payments?page=` : paiements non annulés, du plus récent.
  Future<Paginated<Payment>> fetchPayments({int page = 1});

  /// `GET /me/payments/{id}/receipt` : reçu PDF (404 si le paiement
  /// n'appartient pas au membre).
  Future<List<int>> downloadReceipt(int paymentId);
}

class ApiContributionsRepository implements ContributionsRepository {
  const ApiContributionsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Contribution>> fetchContributions() =>
      _api.getList('/me/contributions', Contribution.fromJson);

  @override
  Future<Paginated<Payment>> fetchPayments({int page = 1}) =>
      _api.getPage('/me/payments', Payment.fromJson, page: page);

  @override
  Future<List<int>> downloadReceipt(int paymentId) =>
      _api.download('/me/payments/$paymentId/receipt');
}

class MockContributionsRepository implements ContributionsRepository {
  const MockContributionsRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<List<Contribution>> fetchContributions() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final data =
        persona.contributionsJson(DateTime.now())['data']! as List<Object?>;
    return [
      for (final item in data)
        Contribution.fromJson(item! as Map<String, dynamic>),
    ];
  }

  /// Petites pages pour montrer le chargement des pages suivantes.
  static const _perPage = 2;

  @override
  Future<Paginated<Payment>> fetchPayments({int page = 1}) async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final all = persona.paymentsJson(DateTime.now());
    final lastPage = (all.length / _perPage).ceil();
    return Paginated.fromJson({
      'data': all.skip((page - 1) * _perPage).take(_perPage).toList(),
      'meta': {
        'current_page': page,
        'last_page': lastPage,
        'per_page': _perPage,
        'total': all.length,
      },
    }, Payment.fromJson);
  }

  @override
  Future<List<int>> downloadReceipt(int paymentId) async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final payment = persona
        .paymentsJson(DateTime.now())
        .where((p) => p['id'] == paymentId)
        .firstOrNull;
    if (payment == null) throw const NotFoundException();
    return mockPdf('Recu de test ${payment['receipt_number']} - AEENCI');
  }
}

@Riverpod(keepAlive: true)
ContributionsRepository contributionsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockContributionsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiContributionsRepository(ref.watch(apiClientProvider));
