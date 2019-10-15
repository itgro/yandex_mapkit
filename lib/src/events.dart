import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:yandex_geometry/yandex_geometry.dart';

class MapObjectEvent {
  final String id;

  MapObjectEvent({
    @required this.id,
  });

  factory MapObjectEvent.fromString(String string) => MapObjectEvent.fromMap(
        json.decode(string),
      );

  factory MapObjectEvent.fromMap(Map map) => MapObjectEvent(
        id: map['id'],
      );
}

class MapObjectEventWithPoint {
  final String id;
  final Point point;

  MapObjectEventWithPoint({
    @required this.id,
    @required this.point,
  });

  factory MapObjectEventWithPoint.fromString(String string) =>
      MapObjectEventWithPoint.fromMap(
        json.decode(string),
      );

  factory MapObjectEventWithPoint.fromMap(Map map) => MapObjectEventWithPoint(
      id: map['id'], point: Point.fromMap(map['point']));
}

class CameraPositionEvent {
  final bool finished;
  final Position position;

  CameraPositionEvent({this.finished, this.position});

  @override
  String toString() =>
      'CameraPositionEvent{finished: $finished, position: $position}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraPositionEvent &&
          runtimeType == other.runtimeType &&
          finished == other.finished &&
          position == other.position;

  @override
  int get hashCode => finished.hashCode ^ position.hashCode;

  factory CameraPositionEvent.fromString(String string) =>
      CameraPositionEvent.fromMap(
        json.decode(string),
      );

  factory CameraPositionEvent.fromMap(Map map) => CameraPositionEvent(
      position: Position.fromMap(map['position']),
      finished: map['finished'] as bool);
}
