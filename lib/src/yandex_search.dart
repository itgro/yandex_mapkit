import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../yandex_mapkit.dart';

typedef YandexSearchSuccessCallback = void Function(SearchResult result);
typedef YandexSearchFailureCallback = void Function();

enum YandexSearchManagerType { Combined, Online, Offline, Default }

class YandexSearch {
  static MethodChannel _globalChannel = const MethodChannel('yandex_mapkit');

  String uuid;
  MethodChannel _privateChannel;

  Map<String, YandexSearchSession> _sessions = {};

  YandexSearch._internal(this.uuid) {
    _privateChannel = MethodChannel("yandex_mapkit/search_manager_$uuid");

    _privateChannel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case 'searchResponse':
          SearchResult result =
              SearchResult.fromString(call.arguments as String);

          if (_sessions.containsKey(result.sessionId)) {
            YandexSearchSession session = _sessions[result.sessionId];

            if (result.isSuccess) {
              if (session._onSuccess != null) {
                session._onSuccess(result);
              }
            } else {
              if (session._onError != null) {
                session._onError();
              }
            }
          }
          break;
      }
    });
  }

  static Future<YandexSearch> createSearchManager({
    YandexSearchManagerType type,
  }) async {
    String managerType;

    switch (type) {
      case YandexSearchManagerType.Combined:
        managerType = "combined";
        break;
      case YandexSearchManagerType.Online:
        managerType = "online";
        break;
      case YandexSearchManagerType.Offline:
        managerType = "offline";
        break;
      default:
        managerType = "default";
        break;
    }

    String uuid = await _globalChannel.invokeMethod<String>(
      "createSearchManager",
      {
        "type": managerType,
      },
    );

    return YandexSearch._internal(uuid);
  }

  dispose() {
    _globalChannel.invokeMethod("disposeSearchManager", uuid);
  }

  Future<YandexSearchSession> submitWithPoint({
    @required Point point,
    int zoom,
    SearchOptions searchOptions = const SearchOptions(),
    @required YandexSearchSuccessCallback onSuccess,
    @required YandexSearchFailureCallback onError,
  }) async {
    Map optionsMap = searchOptions.toMap();

    String uuid = await _privateChannel.invokeMethod<String>(
      'submitWithPoint',
      {
        "latitude": point.latitude,
        "longitude": point.longitude,
        "zoom": zoom,
        "types": optionsMap["searchTypes"],
      },
    );

    final session = YandexSearchSession._internal(
      uuid: uuid,
      search: this,
      onSuccess: onSuccess,
      onError: onError,
    );

    _sessions[uuid] = session;

    return session;
  }

  Future<void> _cancelSession(YandexSearchSession session) async {
    if (_sessions.containsKey(session._uuid)) {
      return _privateChannel.invokeMethod('cancel', session._uuid);
    }

    return null;
  }
}

class YandexSearchSession {
  String _uuid;
  YandexSearch _search;
  YandexSearchSuccessCallback _onSuccess;
  YandexSearchFailureCallback _onError;

  YandexSearchSession._internal({
    @required String uuid,
    @required YandexSearch search,
    @required YandexSearchSuccessCallback onSuccess,
    @required YandexSearchFailureCallback onError,
  })  : _uuid = uuid,
        _search = search,
        _onSuccess = onSuccess,
        _onError = onError;

  void cancel() {
    _search._cancelSession(this);
  }
}
