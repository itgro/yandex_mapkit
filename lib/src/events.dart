import 'dart:convert';

import 'package:yandex_geometry/yandex_geometry.dart';

import '../yandex_mapkit.dart';

class CameraPositionEvent {
  final bool finished;
  final Position position;

  CameraPositionEvent({this.finished, this.position});

  @override
  String toString() => 'CameraPositionEvent{finished: $finished, position: $position}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CameraPositionEvent &&
              runtimeType == other.runtimeType &&
              finished == other.finished &&
              position == other.position;

  @override
  int get hashCode =>
      finished.hashCode ^
      position.hashCode;

  factory CameraPositionEvent.fromString(String string) =>
      CameraPositionEvent.fromMap(
        json.decode(string),
      );

  factory CameraPositionEvent.fromMap(Map map) => CameraPositionEvent(
      position: Position.fromMap(map['position']),
      finished: map['finished'] as bool);
}