library yandex_map;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mapkit/src/entities.dart';
import 'package:yandex_mapkit/src/yandex_search.dart';

import 'yandex_mapkit.dart';

export 'src/placemark.dart';
export 'src/entities.dart';
export 'src/events.dart';
export 'src/yandex_map.dart';
export 'src/yandex_search.dart';
export 'src/yandex_map_controller.dart';

class YandexMapkit {
  static MethodChannel _channel = MethodChannel('yandex_mapkit');

  static Future<void> setup(String apiKey) async {
    await _channel.invokeMethod('setApiKey', apiKey);

    YandexSearchManager.init(_channel);
  }
}
