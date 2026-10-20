import 'package:url_launcher/url_launcher.dart';

/// Adresses du site public.
abstract final class SiteLinks {
  static const membership = 'https://aeenci.com/adhesion';
}

/// Ouvre une adresse dans le navigateur ou l'application concernée
/// (store, messagerie). Renvoie `false` si rien ne peut l'ouvrir.
Future<bool> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
