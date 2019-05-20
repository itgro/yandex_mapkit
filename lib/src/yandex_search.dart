import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../yandex_mapkit.dart';

typedef YandexSearchSuccessCallback = void Function(SearchResult result);
typedef YandexSearchFailureCallback = void Function(String error);

class YandexSearchManager {
  static YandexSearchManager sharedInstance;

  MethodChannel _methodChannel;

  YandexSearchManager(MethodChannel methodChannel)
      : _methodChannel = methodChannel;

  static init(MethodChannel methodChannel) {
    sharedInstance = YandexSearchManager(methodChannel);
  }

  Future<YandexSearchSession> submitWithPoint({
    @required Point point,
    double zoom,
    SearchOptions searchOptions,
    @required YandexSearchSuccessCallback onSuccess,
    @required YandexSearchFailureCallback onError,
  }) async {
    String uuid = await _methodChannel.invokeMethod<String>(
      'search#withPoint',
      json.encode(
        SubmitWithPointParameters(
          point: point,
          zoom: zoom,
          searchOptions: searchOptions,
        ).toMap(),
      ),
    );

    return YandexSearchSession(
      uuid: uuid,
      methodChannel: _methodChannel,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}

class YandexSearchSession {
  String _uuid;
  MethodChannel _methodChannel;

  YandexSearchSuccessCallback _onSuccess;
  YandexSearchFailureCallback _onError;

  YandexSearchSession({
    @required String uuid,
    @required MethodChannel methodChannel,
    @required YandexSearchSuccessCallback onSuccess,
    @required YandexSearchFailureCallback onError,
  })  : _uuid = uuid,
        _methodChannel = MethodChannel('yandex_mapkit_search_$uuid'),
        _onSuccess = onSuccess,
        _onError = onError {
    _methodChannel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case 'success':
          if (_onSuccess != null) {
            _onSuccess(SearchResult.fromString(call.arguments as String));
          }
          break;
        case 'success':
          if (_onError != null) {
            _onError(call.arguments as String);
          }
          break;
      }
    });
  }

  Future<void> cancel() {
    return _methodChannel.invokeMethod("cancel");
  }

  dispose() {
    return _methodChannel.invokeMethod("dispose");
  }
}
