import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Émet `true` quand une connexion réseau (re)devient disponible, `false`
/// quand elle disparaît. Ce n'est qu'un indice : seule une requête dit si
/// l'API répond.
final connectivityProvider = StreamProvider<bool>(
  (ref) => Connectivity().onConnectivityChanged.map(
    (results) => results.any((result) => result != ConnectivityResult.none),
  ),
);
