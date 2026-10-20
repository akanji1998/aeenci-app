import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../domain/contact_info.dart';

part 'contact_repository.g.dart';

/// Coordonnées de l'association (`GET /site/contact`, public).
abstract interface class ContactRepository {
  Future<ContactInfo> fetchContact();
}

class ApiContactRepository implements ContactRepository {
  const ApiContactRepository(this._api);

  final ApiClient _api;

  @override
  Future<ContactInfo> fetchContact() =>
      _api.getData('/site/contact', ContactInfo.fromJson);
}

class MockContactRepository implements ContactRepository {
  const MockContactRepository(this._runtime);

  final MockRuntime _runtime;

  @override
  Future<ContactInfo> fetchContact() async {
    await _runtime.simulate();
    return ContactInfo.fromJson(mockContactJson);
  }
}

@Riverpod(keepAlive: true)
ContactRepository contactRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockContactRepository(ref.watch(mockRuntimeProvider))
    : ApiContactRepository(ref.watch(apiClientProvider));
