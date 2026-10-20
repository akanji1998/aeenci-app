import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';

part 'account_repository.g.dart';

/// Compte de connexion : mot de passe et suppression.
abstract interface class AccountRepository {
  /// `PUT /me/password` : 422 sous `current_password` si l'ancien est faux.
  /// Les autres jetons et sessions du compte sont révoqués.
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  /// `DELETE /me/account` : 422 sous `password` si le mot de passe est faux.
  /// La fiche de membre reste conservée par l'association.
  Future<void> deleteAccount({required String password});
}

class ApiAccountRepository implements AccountRepository {
  const ApiAccountRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) => _api.send(
    'PUT',
    '/me/password',
    data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    },
  );

  @override
  Future<void> deleteAccount({required String password}) =>
      _api.send('DELETE', '/me/account', data: {'password': password});
}

/// Le mot de passe des comptes factices reste [mockPassword] : un
/// changement est accepté mais pas retenu.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository(this._runtime);

  final MockRuntime _runtime;

  static Never _invalid(String field, String message) =>
      throw ValidationException(
        message: message,
        errors: {
          field: [message],
        },
      );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _runtime.simulate();
    if (currentPassword != mockPassword) {
      _invalid('current_password', 'Le mot de passe actuel est incorrect.');
    }
    if (password.length < 8) {
      _invalid(
        'password',
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
    }
    if (password != passwordConfirmation) {
      _invalid('password', 'La confirmation ne correspond pas.');
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await _runtime.simulate();
    if (password != mockPassword) {
      _invalid('password', 'Le mot de passe est incorrect.');
    }
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockAccountRepository(ref.watch(mockRuntimeProvider))
    : ApiAccountRepository(ref.watch(apiClientProvider));
