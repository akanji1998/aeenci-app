import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/member.dart';
import '../data/auth_repository.dart';

part 'session_controller.g.dart';

/// Pourquoi la personne a été déconnectée (message sur l'écran de connexion).
enum SignedOutReason {
  /// Déconnexion volontaire, ou jamais connecté.
  none,

  /// 401 : jeton expiré ou révoqué.
  expired,

  /// Compte de connexion sans fiche de membre.
  noMemberProfile,
}

/// État de la session, lu par la garde du routeur.
@immutable
sealed class SessionState {
  const SessionState();
}

/// Démarrage : lecture du jeton et de la fiche.
final class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Fiche impossible à charger (pas de réseau ni de cache, erreur serveur).
final class SessionUnavailable extends SessionState {
  const SessionUnavailable(this.error);

  final ApiException error;
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut([this.reason = SignedOutReason.none]);

  final SignedOutReason reason;
}

/// Adhésion en attente ou refusée : seulement le suivi de la demande.
final class SessionCandidate extends SessionState {
  const SessionCandidate(this.member);

  final Member member;
}

/// Membre admis : accès aux cinq onglets.
final class SessionMember extends SessionState {
  const SessionMember(this.member, {this.offlineSince});

  final Member member;

  /// Fiche lue dans le cache faute de réseau.
  final DateTime? offlineSince;

  bool can(String ability) => member.can(ability);
}

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  static const _meCacheKey = 'me';

  @override
  SessionState build() {
    final subscription = ref
        .watch(apiClientProvider)
        .unauthorized
        .listen((_) => unawaited(_expire()));
    ref.onDispose(subscription.cancel);
    Future.microtask(restore);
    return const SessionLoading();
  }

  /// Au démarrage, ou « Réessayer » sur l'écran d'indisponibilité.
  Future<void> restore() async {
    state = const SessionLoading();
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null || token.isEmpty) {
      state = const SessionSignedOut();
      return;
    }
    await _loadMember();
  }

  /// Connexion. Les erreurs (422 sous `email`, réseau…) remontent à l'écran.
  Future<void> signIn({required String email, required String password}) async {
    final auth = ref.read(authRepositoryProvider);
    final tokens = ref.read(tokenStoreProvider);
    final session = await auth.login(
      email: email.trim(),
      password: password,
      deviceName: deviceName,
    );

    if (session.user.memberId == null) {
      // Pas d'espace membre : on révoque aussitôt le jeton obtenu.
      await tokens.write(session.token);
      await _logoutQuietly();
      await tokens.clear();
      state = const SessionSignedOut(SignedOutReason.noMemberProfile);
      return;
    }

    // Données d'un éventuel compte précédent sur ce téléphone.
    await ref.read(cacheStoreProvider).clear();
    await tokens.write(session.token);
    await _loadMember();
  }

  /// Déconnexion : jeton révoqué si possible, puis effacé avec le cache.
  Future<void> signOut() async {
    await _logoutQuietly();
    await ref.read(tokenStoreProvider).clear();
    await ref.read(cacheStoreProvider).clear();
    state = const SessionSignedOut();
  }

  Future<void> _loadMember() async {
    final cache = ref.read(cacheStoreProvider);
    try {
      final result = await fetchWithCache<Member>(
        cache: cache,
        key: _meCacheKey,
        fetch: ref.read(profileRepositoryProvider).fetchMe,
        toJson: (member) => member.toJson(),
        fromJson: (json) => Member.fromJson(json! as Map<String, dynamic>),
      );
      state = _stateFor(result);
    } on UnauthorizedException {
      await _expire();
    } on ApiException catch (error) {
      state = SessionUnavailable(error);
    }
  }

  SessionState _stateFor(Cached<Member> result) => result.data.isAdmitted
      ? SessionMember(result.data, offlineSince: result.offlineSince)
      : SessionCandidate(result.data);

  Future<void> _expire() async {
    if (state case SessionSignedOut()) return;
    await ref.read(tokenStoreProvider).clear();
    await ref.read(cacheStoreProvider).clear();
    state = const SessionSignedOut(SignedOutReason.expired);
  }

  Future<void> _logoutQuietly() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // Hors connexion ou jeton déjà invalide : on déconnecte localement.
    }
  }
}

/// `device_name` envoyé à la connexion, visible du membre dans ses sessions.
String get deviceName => 'Application AEENCI (${Platform.operatingSystem})';
