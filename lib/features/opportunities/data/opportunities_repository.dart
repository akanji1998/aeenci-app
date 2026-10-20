import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_pdf.dart';
import '../../../core/mock/mock_profile_store.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/opportunity.dart';

part 'opportunities_repository.g.dart';

/// Opportunités reçues (offres relayées par le bureau, jamais publiques).
abstract interface class OpportunitiesRepository {
  /// `GET /me/opportunities?page=` ; `meta.unseen_count` : non vues.
  Future<Paginated<Opportunity>> fetchPage({int page = 1});

  /// `GET /me/opportunities/{id}` : marque l'offre comme vue ; 404 si elle
  /// n'a pas été reçue.
  Future<OpportunityDetail> fetchDetail(int id);

  /// `POST /me/opportunities/{id}/interest` : 204. `shareCv` exige un CV
  /// (sinon 422 sous `share_cv`) ; offre clôturée : 422 sous `opportunity`.
  Future<void> expressInterest(int id, {required bool shareCv});

  /// `DELETE /me/opportunities/{id}/interest` : retire l'intérêt et
  /// l'accord CV ; 204.
  Future<void> withdrawInterest(int id);

  /// Fiche de poste jointe (`job_description_url`, route authentifiée).
  Future<List<int>> downloadJobDescription(OpportunityDetail opportunity);
}

class ApiOpportunitiesRepository implements OpportunitiesRepository {
  const ApiOpportunitiesRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<Opportunity>> fetchPage({int page = 1}) =>
      _api.getPage('/me/opportunities', Opportunity.fromJson, page: page);

  @override
  Future<OpportunityDetail> fetchDetail(int id) =>
      _api.getData('/me/opportunities/$id', OpportunityDetail.fromJson);

  @override
  Future<void> expressInterest(int id, {required bool shareCv}) => _api.send(
    'POST',
    '/me/opportunities/$id/interest',
    data: {'share_cv': shareCv},
  );

  @override
  Future<void> withdrawInterest(int id) =>
      _api.send('DELETE', '/me/opportunities/$id/interest');

  @override
  Future<List<int>> downloadJobDescription(OpportunityDetail opportunity) =>
      _api.download(opportunity.jobDescriptionUrl!);
}

class MockOpportunitiesRepository implements OpportunitiesRepository {
  const MockOpportunitiesRepository(this._runtime, this._tokens, this._store);

  final MockRuntime _runtime;
  final TokenStore _tokens;
  final MockProfileStore _store;

  /// Petites pages pour montrer le chargement des pages suivantes.
  static const _perPage = 3;

  static const _listFields = {
    'id',
    'type',
    'title',
    'organization',
    'location',
    'deadline',
    'received_at',
    'seen',
    'interested',
  };

  Future<List<Map<String, Object?>>> _all() async =>
      _store.opportunities(await currentMockPersona(_tokens));

  Future<Map<String, Object?>> _find(int id) async {
    final offer = (await _all()).where((o) => o['id'] == id).firstOrNull;
    if (offer == null) throw const NotFoundException();
    return offer;
  }

  @override
  Future<Paginated<Opportunity>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    final all = await _all();
    return Paginated.fromJson({
      'data': [
        for (final o in all.skip((page - 1) * _perPage).take(_perPage))
          {
            for (final e in o.entries)
              if (_listFields.contains(e.key)) e.key: e.value,
          },
      ],
      'meta': {
        'current_page': page,
        'last_page': (all.length / _perPage).ceil(),
        'per_page': _perPage,
        'total': all.length,
        'unseen_count': all.where((o) => o['seen'] != true).length,
      },
    }, Opportunity.fromJson);
  }

  @override
  Future<OpportunityDetail> fetchDetail(int id) async {
    await _runtime.simulate();
    final offer = await _find(id);
    offer['seen'] = true;
    return OpportunityDetail.fromJson(offer);
  }

  @override
  Future<void> expressInterest(int id, {required bool shareCv}) async {
    await _runtime.simulate();
    final offer = await _find(id);
    final persona = await currentMockPersona(_tokens);
    if (shareCv && _store.profile(persona)['cv_url'] == null) {
      const message = 'Ajoute un CV à ton profil pour le transmettre.';
      throw const ValidationException(
        message: message,
        errors: {
          'share_cv': [message],
        },
      );
    }
    offer
      ..['interested'] = true
      ..['cv_shared'] = shareCv;
  }

  @override
  Future<void> withdrawInterest(int id) async {
    await _runtime.simulate();
    (await _find(id))
      ..['interested'] = false
      ..['cv_shared'] = false;
  }

  @override
  Future<List<int>> downloadJobDescription(
    OpportunityDetail opportunity,
  ) async {
    await _runtime.simulate();
    return mockPdf('Fiche de poste de test - ${opportunity.title}');
  }
}

@Riverpod(keepAlive: true)
OpportunitiesRepository opportunitiesRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockOpportunitiesRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
        ref.watch(mockProfileStoreProvider),
      )
    : ApiOpportunitiesRepository(ref.watch(apiClientProvider));
