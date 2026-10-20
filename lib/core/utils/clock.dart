import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Heure courante, remplaçable dans les tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
