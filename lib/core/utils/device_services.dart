import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'external_links.dart';

/// Services du téléphone (calendrier, cartes, liens), remplaçables dans
/// les tests.
abstract interface class DeviceServices {
  /// Ouvre l'application de calendrier avec l'événement prérempli.
  Future<bool> addToCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  });

  /// Ouvre [location] dans l'application de cartes.
  Future<bool> openMap(String location);

  /// Ouvre une adresse (site, store, e-mail).
  Future<bool> openUrl(String url);

  /// Ouvre un fichier (reçu PDF) avec le lecteur du téléphone.
  Future<bool> openFile(String path);

  /// Propose de partager un fichier (messagerie, e-mail…).
  Future<void> shareFile(String path, {String? text});

  /// Copie [text] dans le presse-papiers.
  Future<void> copyText(String text);
}

class PlatformDeviceServices implements DeviceServices {
  const PlatformDeviceServices();

  @override
  Future<bool> addToCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    try {
      return await calendar.Add2Calendar.addEvent2Cal(
        calendar.Event(
          title: title,
          description: description,
          location: location,
          startDate: start.toLocal(),
          endDate: end.toLocal(),
        ),
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openMap(String location) {
    final query = Uri.encodeComponent(location);
    return openExternal(
      defaultTargetPlatform == TargetPlatform.iOS
          ? 'https://maps.apple.com/?q=$query'
          : 'geo:0,0?q=$query',
    );
  }

  @override
  Future<bool> openUrl(String url) => openExternal(url);

  @override
  Future<bool> openFile(String path) async {
    try {
      final result = await OpenFilex.open(path, type: 'application/pdf');
      return result.type == ResultType.done;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> shareFile(String path, {String? text}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: text,
        ),
      );

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

final deviceServicesProvider = Provider<DeviceServices>(
  (ref) => const PlatformDeviceServices(),
);
