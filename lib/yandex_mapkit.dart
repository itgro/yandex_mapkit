library yandex_map;

import 'dart:async';

import 'package:flutter/services.dart';

export 'src/entities.dart';
export 'src/events.dart';
export 'src/placemark.dart';
export 'src/yandex_map.dart';
export 'src/yandex_map_controller.dart';

class YandexMapkit {
  static MethodChannel _channel = const MethodChannel('yandex_mapkit');

  static Future<void> setup(String apiKey) async {
    await _channel.invokeMethod('setApiKey', apiKey);
  }
}
