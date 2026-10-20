import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final deviceServicesProvider = Provider<DeviceServices>(
  (ref) => const PlatformDeviceServices(),
);
