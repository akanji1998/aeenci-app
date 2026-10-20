import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/mock/mock_profile_store.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/education.dart';
import '../domain/member.dart';
import '../domain/professional_profile.dart';
import '../domain/profile_inputs.dart';

part 'profile_repository.g.dart';

/// Fiche, parcours scolaire et profil professionnel du membre connecté.
abstract interface class ProfileRepository {
  /// `GET /me`.
  Future<Member> fetchMe();

  /// `PATCH /me` : contacts.
  Future<Member> updateContacts(ContactUpdate update);

  /// `POST /me` avec `_method=PATCH` : nouvelle photo (multipart).
  Future<Member> updatePhoto(String filePath);

  /// `GET /me/educations`.
  Future<List<Education>> fetchEducations();

  Future<Education> createEducation(EducationInput input);

  Future<Education> updateEducation(int id, EducationInput input);

  Future<void> deleteEducation(int id);

  /// `GET /education-levels` (public).
  Future<List<EducationLevel>> fetchEducationLevels();

  /// `GET /me/profile`.
  Future<ProfessionalProfile> fetchProfessionalProfile();

  /// `PATCH /me/profile` : seulement les champs fournis ([fields], noms de
  /// l'API). `skills` et `languages` remplacent les listes existantes.
  Future<ProfessionalProfile> updateProfessionalProfile(
    Map<String, Object?> fields,
  );

  /// `POST /me/profile` avec `_method=PATCH` : nouveau CV (PDF).
  Future<ProfessionalProfile> uploadCv(String filePath);

  /// `PATCH /me/profile/visibility`.
  Future<ProfessionalProfile> setShowcase({required bool isPublic});

  Future<Experience> createExperience(ExperienceInput input);

  Future<Experience> updateExperience(int id, ExperienceInput input);

  Future<void> deleteExperience(int id);

  Future<PortfolioItem> createPortfolioItem(PortfolioInput input);

  Future<PortfolioItem> updatePortfolioItem(int id, PortfolioInput input);

  Future<void> deletePortfolioItem(int id);
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._api);

  final ApiClient _api;

  /// Envoi avec fichier : `POST` + `_method=PATCH`, booléens en 1/0.
  Future<FormData> _form(
    Map<String, Object?> fields, {
    String? fileField,
    String? filePath,
    bool patch = false,
  }) async => FormData.fromMap({
    if (patch) '_method': 'PATCH',
    for (final MapEntry(:key, :value) in fields.entries)
      if (value != null) key: value is bool ? (value ? '1' : '0') : value,
    if (fileField != null && filePath != null)
      fileField: await MultipartFile.fromFile(filePath),
  });

  @override
  Future<Member> fetchMe() => _api.getData('/me', Member.fromJson);

  @override
  Future<Member> updateContacts(ContactUpdate update) =>
      _api.sendData('PATCH', '/me', Member.fromJson, data: update.toJson());

  @override
  Future<Member> updatePhoto(String filePath) async => _api.sendData(
    'POST',
    '/me',
    Member.fromJson,
    data: await _form(
      const {},
      fileField: 'photo',
      filePath: filePath,
      patch: true,
    ),
  );

  @override
  Future<List<Education>> fetchEducations() =>
      _api.getList('/me/educations', Education.fromJson);

  @override
  Future<Education> createEducation(EducationInput input) => _api.sendData(
    'POST',
    '/me/educations',
    Education.fromJson,
    data: input.toJson(),
  );

  @override
  Future<Education> updateEducation(int id, EducationInput input) =>
      _api.sendData(
        'PATCH',
        '/me/educations/$id',
        Education.fromJson,
        data: input.toJson(),
      );

  @override
  Future<void> deleteEducation(int id) =>
      _api.send('DELETE', '/me/educations/$id');

  @override
  Future<List<EducationLevel>> fetchEducationLevels() =>
      _api.getList('/education-levels', EducationLevel.fromJson);

  @override
  Future<ProfessionalProfile> fetchProfessionalProfile() =>
      _api.getData('/me/profile', ProfessionalProfile.fromJson);

  @override
  Future<ProfessionalProfile> updateProfessionalProfile(
    Map<String, Object?> fields,
  ) => _api.sendData(
    'PATCH',
    '/me/profile',
    ProfessionalProfile.fromJson,
    data: fields,
  );

  @override
  Future<ProfessionalProfile> uploadCv(String filePath) async => _api.sendData(
    'POST',
    '/me/profile',
    ProfessionalProfile.fromJson,
    data: await _form(
      const {},
      fileField: 'cv',
      filePath: filePath,
      patch: true,
    ),
  );

  @override
  Future<ProfessionalProfile> setShowcase({required bool isPublic}) =>
      _api.sendData(
        'PATCH',
        '/me/profile/visibility',
        ProfessionalProfile.fromJson,
        data: {'is_public': isPublic},
      );

  @override
  Future<Experience> createExperience(ExperienceInput input) => _api.sendData(
    'POST',
    '/me/experiences',
    Experience.fromJson,
    data: input.toJson(),
  );

  @override
  Future<Experience> updateExperience(int id, ExperienceInput input) =>
      _api.sendData(
        'PATCH',
        '/me/experiences/$id',
        Experience.fromJson,
        data: input.toJson(),
      );

  @override
  Future<void> deleteExperience(int id) =>
      _api.send('DELETE', '/me/experiences/$id');

  @override
  Future<PortfolioItem> createPortfolioItem(PortfolioInput input) async =>
      _api.sendData(
        'POST',
        '/me/portfolio-items',
        PortfolioItem.fromJson,
        data: input.filePath == null
            ? input.toJson()
            : await _form(
                input.toJson(),
                fileField: 'file',
                filePath: input.filePath,
              ),
      );

  @override
  Future<PortfolioItem> updatePortfolioItem(
    int id,
    PortfolioInput input,
  ) async => input.filePath == null
      ? _api.sendData(
          'PATCH',
          '/me/portfolio-items/$id',
          PortfolioItem.fromJson,
          data: input.toJson(),
        )
      : _api.sendData(
          'POST',
          '/me/portfolio-items/$id',
          PortfolioItem.fromJson,
          data: await _form(
            input.toJson(),
            fileField: 'file',
            filePath: input.filePath,
            patch: true,
          ),
        );

  @override
  Future<void> deletePortfolioItem(int id) =>
      _api.send('DELETE', '/me/portfolio-items/$id');
}

/// Mock avec un état en mémoire ([MockProfileStore]) et des erreurs 422
/// réalistes.
class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository(this._runtime, this._tokens, this._store);

  final MockRuntime _runtime;
  final TokenStore _tokens;
  final MockProfileStore _store;

  Future<MockPersona> _persona() async {
    await _runtime.simulate();
    return currentMockPersona(_tokens);
  }

  static Never _invalid(String field, String message) =>
      throw ValidationException(
        message: message,
        errors: {
          field: [message],
        },
      );

  static void _required(Map<String, Object?> json, Map<String, String> fields) {
    for (final MapEntry(key: field, value: label) in fields.entries) {
      final value = json[field];
      if (value == null || (value is String && value.trim().isEmpty)) {
        _invalid(field, 'Le champ $label est obligatoire.');
      }
    }
  }

  List<Map<String, Object?>> _list(Map<String, Object?> profile, String key) =>
      (profile[key]! as List<Object?>).cast<Map<String, Object?>>();

  @override
  Future<Member> fetchMe() async =>
      Member.fromJson(_store.me(await _persona()));

  @override
  Future<Member> updateContacts(ContactUpdate update) async {
    final me = _store.me(await _persona());
    final json = update.toJson();
    _required(json, {'phone': 'téléphone', 'email': 'e-mail', 'city': 'ville'});
    if (!(json['email']! as String).contains('@')) {
      _invalid('email', 'Saisis une adresse e-mail valide.');
    }
    me.addAll(json);
    return Member.fromJson(me);
  }

  @override
  Future<Member> updatePhoto(String filePath) async {
    final me = _store.me(await _persona());
    // Fichier local : il n'y a pas de serveur pour héberger la photo.
    me['photo_url'] = Uri.file(filePath).toString();
    return Member.fromJson(me);
  }

  @override
  Future<List<Education>> fetchEducations() async =>
      _store.educations(await _persona()).map(Education.fromJson).toList();

  Map<String, Object?> _validEducation(EducationInput input) {
    final json = input.toJson();
    _required(json, {
      'level': 'niveau',
      'school': 'établissement',
      'field_of_study': 'filière',
    });
    final start = input.startYear;
    final end = input.endYear;
    if (start != null && end != null && end < start) {
      _invalid('end_year', 'L\'année de fin doit suivre l\'année de début.');
    }
    return json;
  }

  @override
  Future<Education> createEducation(EducationInput input) async {
    final list = _store.educations(await _persona());
    final json = {'id': _store.nextId(), ..._validEducation(input)};
    list.insert(0, json);
    return Education.fromJson(json);
  }

  @override
  Future<Education> updateEducation(int id, EducationInput input) async {
    final list = _store.educations(await _persona());
    final item = list.where((e) => e['id'] == id).firstOrNull;
    if (item == null) throw const NotFoundException();
    item.addAll(_validEducation(input));
    return Education.fromJson(item);
  }

  @override
  Future<void> deleteEducation(int id) async {
    final list = _store.educations(await _persona());
    if (!list.any((e) => e['id'] == id)) throw const NotFoundException();
    list.removeWhere((e) => e['id'] == id);
  }

  @override
  Future<List<EducationLevel>> fetchEducationLevels() async {
    await _runtime.simulate();
    return mockEducationLevelsJson.map(EducationLevel.fromJson).toList();
  }

  @override
  Future<ProfessionalProfile> fetchProfessionalProfile() async =>
      ProfessionalProfile.fromJson(_store.profile(await _persona()));

  @override
  Future<ProfessionalProfile> updateProfessionalProfile(
    Map<String, Object?> fields,
  ) async {
    final profile = _store.profile(await _persona());
    final linkedin = fields['linkedin_url'];
    if (linkedin is String &&
        linkedin.isNotEmpty &&
        !linkedin.startsWith('https://')) {
      _invalid('linkedin_url', 'Saisis une adresse qui commence par https://.');
    }
    profile.addAll(fields);
    return ProfessionalProfile.fromJson(profile);
  }

  @override
  Future<ProfessionalProfile> uploadCv(String filePath) async {
    final profile = _store.profile(await _persona());
    profile['cv_url'] = Uri.file(filePath).toString();
    return ProfessionalProfile.fromJson(profile);
  }

  @override
  Future<ProfessionalProfile> setShowcase({required bool isPublic}) async {
    final profile = _store.profile(await _persona());
    profile
      ..['is_public'] = isPublic
      ..['showcase_status'] = isPublic ? 'pending' : 'private'
      ..['consented_at'] = isPublic
          ? DateTime.now().toUtc().toIso8601String()
          : profile['consented_at'];
    return ProfessionalProfile.fromJson(profile);
  }

  Map<String, Object?> _validExperience(ExperienceInput input) {
    final json = input.toJson();
    _required(json, {'title': 'poste', 'organization': 'organisation'});
    final end = input.endedOn;
    if (end != null && end.isBefore(input.startedOn)) {
      _invalid('ended_on', 'La date de fin doit suivre la date de début.');
    }
    return json;
  }

  @override
  Future<Experience> createExperience(ExperienceInput input) async {
    final list = _list(_store.profile(await _persona()), 'experiences');
    final json = {'id': _store.nextId(), ..._validExperience(input)};
    list.insert(0, json);
    return Experience.fromJson(json);
  }

  @override
  Future<Experience> updateExperience(int id, ExperienceInput input) async {
    final list = _list(_store.profile(await _persona()), 'experiences');
    final item = list.where((e) => e['id'] == id).firstOrNull;
    if (item == null) throw const NotFoundException();
    item.addAll(_validExperience(input));
    return Experience.fromJson(item);
  }

  @override
  Future<void> deleteExperience(int id) async {
    _list(
      _store.profile(await _persona()),
      'experiences',
    ).removeWhere((e) => e['id'] == id);
  }

  Map<String, Object?> _validPortfolio(PortfolioInput input) {
    final json = input.toJson();
    _required(json, {'title': 'titre'});
    if (input.filePath != null) {
      json['file_url'] = Uri.file(input.filePath!).toString();
    }
    return json;
  }

  @override
  Future<PortfolioItem> createPortfolioItem(PortfolioInput input) async {
    final list = _list(_store.profile(await _persona()), 'portfolio');
    final json = {
      'id': _store.nextId(),
      'file_url': null,
      ..._validPortfolio(input),
    };
    list.add(json);
    return PortfolioItem.fromJson(json);
  }

  @override
  Future<PortfolioItem> updatePortfolioItem(
    int id,
    PortfolioInput input,
  ) async {
    final list = _list(_store.profile(await _persona()), 'portfolio');
    final item = list.where((e) => e['id'] == id).firstOrNull;
    if (item == null) throw const NotFoundException();
    item.addAll(_validPortfolio(input));
    return PortfolioItem.fromJson(item);
  }

  @override
  Future<void> deletePortfolioItem(int id) async {
    _list(
      _store.profile(await _persona()),
      'portfolio',
    ).removeWhere((e) => e['id'] == id);
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockProfileRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
        ref.watch(mockProfileStoreProvider),
      )
    : ApiProfileRepository(ref.watch(apiClientProvider));
