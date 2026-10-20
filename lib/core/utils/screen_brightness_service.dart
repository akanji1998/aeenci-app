import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Luminosité de l'écran pendant l'affichage de la carte.
abstract interface class ScreenBrightnessService {
  /// Luminosité maximale pour l'application (lecture du QR code).
  Future<void> maximize();

  /// Retour à la luminosité choisie par la personne.
  Future<void> restore();
}

class PluginScreenBrightnessService implements ScreenBrightnessService {
  const PluginScreenBrightnessService();

  @override
  Future<void> maximize() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1);
    } on Object {
      // Plateforme sans réglage de luminosité : la carte reste lisible.
    }
  }

  @override
  Future<void> restore() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } on Object {
      // Idem.
    }
  }
}

final screenBrightnessProvider = Provider<ScreenBrightnessService>(
  (ref) => const PluginScreenBrightnessService(),
);
