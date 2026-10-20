import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Fichier choisi sur le téléphone.
@immutable
class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;

  /// En octets.
  final int size;
}

enum PhotoSource { gallery, camera }

/// Choix de photos et de fichiers, remplaçable dans les tests.
abstract interface class FilePickerService {
  /// Photo réduite à 1080 px de large ; `null` si la personne annule.
  Future<PickedFile?> pickPhoto(PhotoSource source);

  /// PDF (CV) ; `null` si la personne annule.
  Future<PickedFile?> pickPdf();

  /// Fichier d'une réalisation (PDF ou image) ; `null` si annulé.
  Future<PickedFile?> pickDocument();
}

class PlatformFilePickerService implements FilePickerService {
  const PlatformFilePickerService();

  @override
  Future<PickedFile?> pickPhoto(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedFile(
      path: file.path,
      name: file.name,
      size: await file.length(),
    );
  }

  Future<PickedFile?> _pick(List<String> extensions) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    final file = files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    return PickedFile(
      path: path,
      name: file.name,
      size: await file.length() ?? 0,
    );
  }

  @override
  Future<PickedFile?> pickPdf() => _pick(['pdf']);

  @override
  Future<PickedFile?> pickDocument() => _pick(['pdf', 'jpg', 'jpeg', 'png']);
}

final filePickerServiceProvider = Provider<FilePickerService>(
  (ref) => const PlatformFilePickerService(),
);

/// Taille maximale des fichiers envoyés (contrat : 5 Mo).
const maxUploadBytes = 5 * 1024 * 1024;
