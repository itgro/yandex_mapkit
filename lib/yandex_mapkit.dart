library yandex_map;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'src/map_animation.dart';
export 'src/placemark.dart';
export 'src/entities.dart';
export 'src/events.dart';
export 'src/yandex_map.dart';
export 'src/yandex_map_controller.dart';

class YandexMapkit {
  static Future<void> setup({@required String apiKey}) async {
    await MethodChannel('yandex_mapkit').invokeMethod('setApiKey', apiKey);
  }
}

