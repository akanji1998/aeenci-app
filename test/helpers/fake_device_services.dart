import 'package:aeenci_app/core/utils/device_services.dart';

/// Services du téléphone factices : enregistrent les appels.
class FakeDeviceServices implements DeviceServices {
  FakeDeviceServices({this.canOpenFiles = true});

  final bool canOpenFiles;
  final calendar =
      <({String title, DateTime start, DateTime end, String? location})>[];
  final maps = <String>[];
  final urls = <String>[];
  final openedFiles = <String>[];
  final sharedFiles = <String>[];
  final copied = <String>[];

  @override
  Future<bool> addToCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    calendar.add((title: title, start: start, end: end, location: location));
    return true;
  }

  @override
  Future<bool> openMap(String location) async {
    maps.add(location);
    return true;
  }

  @override
  Future<bool> openUrl(String url) async {
    urls.add(url);
    return true;
  }

  @override
  Future<bool> openFile(String path) async {
    openedFiles.add(path);
    return canOpenFiles;
  }

  @override
  Future<void> shareFile(String path, {String? text}) async =>
      sharedFiles.add(path);

  @override
  Future<void> copyText(String text) async => copied.add(text);
}
