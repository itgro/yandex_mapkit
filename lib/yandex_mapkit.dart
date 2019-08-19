library yandex_map;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:yandex_geometry/yandex_geometry.dart';

import 'src/entities.dart';

export 'src/entities.dart';
export 'src/events.dart';
export 'src/placemark.dart';
export 'src/yandex_map.dart';
export 'src/yandex_map_controller.dart';

typedef SuggestResultHandler = void Function(List<SuggestItem>);
typedef SuggestErrorHandler = void Function(String error);

class YandexMapkit {
  static MethodChannel _channel = const MethodChannel('yandex_mapkit');

  static Future<void> setup(String apiKey) async {
    await _channel.invokeMethod('setApiKey', apiKey);
  }
}

class YandexSuggestController {
  static YandexSuggestController _sharedInstance;

  static const EventChannel _resultChannel = EventChannel(
    'yandex_mapkit_suggest_result',
  );

  Stream<SuggestResult> _onSuggestResult;

  Stream<SuggestResult> get onSuggestResult {
    if (_onSuggestResult == null) {
      _onSuggestResult = _resultChannel
          .receiveBroadcastStream()
          .map<SuggestResult>(
              (dynamic event) => SuggestResult.fromString(event.toString()));
    }

    return _onSuggestResult;
  }

  YandexSuggestController._internal();

  void cancelSuggest() {
    YandexMapkit._channel.invokeMethod("cancelSuggest", null);
  }

  void suggest({
    @required String text,
    @required BoundingBox window,
    SearchType type = SearchType.Geo,
  }) {
    assert(text != null);
    assert(window != null);

    String stringType = "unknown";

    switch (type) {
      case SearchType.Geo:
        stringType = "geo";
        break;
      case SearchType.Biz:
        stringType = "Biz";
        break;
    }

    YandexMapkit._channel.invokeMethod(
        "suggest",
        json.encode({
          "text": text,
          "window": window.toMap(),
          "type": stringType,
        }));
  }

  static YandexSuggestController get sharedInstance {
    if (_sharedInstance == null) {
      _sharedInstance = YandexSuggestController._internal();
    }

    return _sharedInstance;
  }
}
