import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_geometry/yandex_geometry.dart';
import 'package:yandex_mapkit/src/events.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

typedef MarkerOnTapHandler = void Function(Point point);
typedef MarkerOnDragHandler = void Function(Point point);
typedef MarkerOnDragStartHandler = void Function();
typedef MarkerOnDragEndHandler = void Function();

_kDefaultOnTap(Point point) {}

_kDefaultOnDrag() {}

class YandexMapMarkerController {
  final String _id;
  final YandexMapController _controller;

  MarkerOnTapHandler _onTap = _kDefaultOnTap;
  MarkerOnDragStartHandler _onDragStart = _kDefaultOnDrag;
  MarkerOnDragHandler _onDrag = _kDefaultOnTap;
  MarkerOnDragEndHandler _onDragEnd = _kDefaultOnDrag;

  YandexMapMarkerController._(this._controller, this._id);

  void setOnTap(MarkerOnTapHandler callback) {
    _onTap = callback;
  }

  void setOnDragStart(MarkerOnDragStartHandler callback) {
    _onDragStart = callback;
  }

  void setOnDrag(MarkerOnDragHandler callback) {
    _onDrag = callback;
  }

  void setOnDragEnd(MarkerOnDragEndHandler callback) {
    _onDragEnd = callback;
  }

  Future update(MarkerUpdate parameters) {
    Map<String, dynamic> map = parameters.toMap();
    map['id'] = _id;

    return _controller._channel.invokeMethod('marker#update', map);
  }

  Future remove() {
    return _controller._channel.invokeMethod('marker#remove', _id);
  }
}

class YandexMapController {
  final MethodChannel _channel;

  final _cameraPositionController =
      StreamController<CameraPositionEvent>.broadcast();

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
    @required Position position,
    MapAnimation animation,
  }) {
    return _channel.invokeMethod(
      'move',
      json.encode({
        'position': position.toMap(),
        'animation': animation.toMap(),
      }),
    );
  }

  Future<void> showUserLocation(BitmapDescriptor icon) {
    return _channel.invokeMethod('showUserLocation', icon.toMap());
  }

  Map<String, YandexMapMarkerController> idToController = {};

  Future<YandexMapMarkerController> addMarker(Point point,
      [MarkerUpdate marker]) async {
    Map<String, dynamic> map = marker.toMap();
    map['point'] = jsonEncode(point.toMap());

    String markerId = await _channel.invokeMethod('marker#init', map);

    idToController[markerId] = YandexMapMarkerController._(this, markerId);

    return idToController[markerId];
  }

  Future<void> addPolygon({
    @required List<Point> outerPoints,
    @required List<Point> innerPoints,
    @required Color fillColor,
    @required Color strokeColor,
    @required double strokeWidth,
    @required double zIndex,
  }) {
    return _channel.invokeMethod(
      "polygon#add",
      json.encode({
        "outerPoints": outerPoints
            .map<Map>((Point point) => point.toMap())
            .toList(growable: false),
        "innerPoints": innerPoints
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
      case 'onMapObjectTap':
        _onMapObjectTap(call.arguments);
        break;
      case 'onMapObjectDrag':
        _onMapObjectDrag(call.arguments);
        break;
      case 'onMapObjectDragEnd':
        _onMapObjectDragEnd(call.arguments);
        break;
      case 'onMapObjectDragStart':
        _onMapObjectDragStart(call.arguments);
        break;
      case 'onCameraPositionChanged':
        _onCameraPositionChanged(call.arguments);
        break;
      default:
        throw MissingPluginException();
    }
  }

  void _onMapObjectTap(dynamic arguments) {
    MapObjectEventWithPoint event =
        MapObjectEventWithPoint.fromString(arguments);
    idToController[event.id]?._onTap(event.point);
  }

  void _onMapObjectDrag(dynamic arguments) {
    MapObjectEventWithPoint event =
        MapObjectEventWithPoint.fromString(arguments);
    idToController[event.id]?._onDrag(event.point);
  }

  void _onMapObjectDragEnd(dynamic arguments) {
    MapObjectEvent event = MapObjectEvent.fromString(arguments);
    idToController[event.id]?._onDragEnd;
  }

  void _onMapObjectDragStart(dynamic arguments) {
    MapObjectEvent event = MapObjectEvent.fromString(arguments);
    idToController[event.id]?._onDragStart;
  }

  void _onCameraPositionChanged(String arguments) {
    _cameraPositionController.sink
        .add(CameraPositionEvent.fromString(arguments));
  }
}
