import 'package:flutter/material.dart';

@immutable
class Point {
  final double _latitude;
  final double _longitude;

  Point(double latitude, double longitude)
      : _latitude = latitude,
        _longitude = longitude;

  double get latitude => _latitude;

  double get longitude => _longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          _latitude == other._latitude &&
          _longitude == other._longitude;

  @override
  int get hashCode => _latitude.hashCode ^ _longitude.hashCode;

  Map toMap() => {
        "latitude": _latitude,
        "longitude": _longitude,
      };

  @override
  String toString() => 'Point{_latitude: $_latitude, _longitude: $_longitude}';

  factory Point.fromMap(Map map) {
    return Point(map['latitude'] as double, map['longitude'] as double);
  }
}

class Position {
  final Point target;
  final double tilt;
  final double zoom;
  final double azimuth;

  Position({
    @required this.target,
    this.tilt = 0.0,
    this.zoom = 14.4,
    this.azimuth = 0.0,
  });

  @override
  String toString() =>
      'Position{target: $target, tilt: $tilt, zoom: $zoom, azimuth: $azimuth}';

  Map toMap() => {
        "target": target.toMap(),
        "tilt": tilt,
        "zoom": zoom,
        "azimuth": azimuth,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          tilt == other.tilt &&
          zoom == other.zoom &&
          azimuth == other.azimuth;

  @override
  int get hashCode =>
      target.hashCode ^ tilt.hashCode ^ zoom.hashCode ^ azimuth.hashCode;

  factory Position.fromMap(Map map) => Position(
        target: Point.fromMap(map['target']),
        tilt: map['tilt'] as double,
        zoom: map['zoom'] as double,
        azimuth: map['azimuth'] as double,
      );
}

class MapAnimation {
  final Duration duration;
  final bool smooth;

  const MapAnimation({
    this.smooth = true,
    this.duration = const Duration(seconds: 1),
  });

  Map toMap() {
    return {
      "smooth": smooth,
      "duration": duration.inMilliseconds,
    };
  }

  @override
  String toString() => 'MapAnimation{duration: $duration, smooth: $smooth}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapAnimation &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          smooth == other.smooth;

  @override
  int get hashCode => duration.hashCode ^ smooth.hashCode;

  factory MapAnimation.fromMap(Map map) => MapAnimation(
        smooth: map['smooth'] as bool,
        duration: Duration(milliseconds: map['duration'] as int),
      );
}
