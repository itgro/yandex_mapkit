import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mapkit/src/events.dart';

import 'map_animation.dart';
import 'placemark.dart';
import 'entities.dart';

class YandexMapController {
  final MethodChannel _channel;

  final _cameraPositionController = StreamController<CameraPositionEvent>();

  Stream<CameraPositionEvent> get onCameraPositionChanged =>
      _cameraPositionController.stream;

  YandexMapController(MethodChannel channel) : _channel = channel {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  dispose() {
    _cameraPositionController.close();
  }

  factory YandexMapController.fromViewId(int id) => YandexMapController(
        MethodChannel('yandex_mapkit/yandex_map_$id'),
      );

  Future<void> move({
    @required Point point,
    double zoom = 14.4,
    double azimuth = 0.0,
    double tilt = 0.0,
    MapAnimation animation,
  }) {
    return _channel.invokeMethod(
      'move',
      json.encode({
        'point': point.toMap(),
        'zoom': zoom,
        'azimuth': azimuth,
        'tilt': tilt,
        'animate': animation != null,
        'smoothAnimation': animation?.smooth,
        'animationDuration': animation?.duration
      }),
    );
  }

//  Future<void> addPlacemark(Placemark placemark) {
//    return _channel.invokeMethod('addPlacemark', placemark.toMap());
//  }
//
//  Future<void> removePlacemark(Placemark placemark) {
//    return _channel
//        .invokeMethod('removePlacemark', {'hashCode': placemark.hashCode});
//  }

  Future<void> addPolygon({
    @required List<Point> points,
    @required Color fillColor,
    @required Color strokeColor,
    @required double strokeWidth,
    @required double zIndex,
  }) {
    return _channel.invokeMethod(
      "addPolygon",
      json.encode({
        "points": points
            .map<Map>((Point point) => point.toMap())
            .toList(growable: false),
        "fillColor": fillColor.value,
        "strokeColor": strokeColor.value,
        "strokeWidth": strokeWidth,
        "zIndex": zIndex,
      }),
    );
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
//      case 'onMapObjectTap':
//        _onMapObjectTap(call.arguments);
//        break;
      case 'onCameraPositionChanged':
        _onCameraPositionChanged(call.arguments);
        break;
      default:
        throw MissingPluginException();
    }
  }

//  void _onMapObjectTap(dynamic arguments) {
//    debugPrint(arguments.toString());
//  }

  void _onCameraPositionChanged(String arguments) {
    _cameraPositionController.sink
        .add(CameraPositionEvent.fromString(arguments));
  }
}
