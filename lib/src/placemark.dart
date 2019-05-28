import 'package:flutter/material.dart';
import 'package:yandex_geometry/yandex_geometry.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'entities.dart';

class Placemark {
  final Point point;
  final double opacity;
  final bool draggable;
  final String icon;
  final Function onTap;

  static const double kOpacity = 0.5;

  static void _kOnTap(double latitude, double longitude) => null;

  Placemark({
    @required this.point,
    this.opacity = kOpacity,
    this.draggable = false,
    this.onTap = _kOnTap,
    this.icon,
  });

  Map toMap() => {
        'point': this.point.toMap(),
        'opacity': this.opacity,
        'draggable': this.draggable,
        'icon': this.icon,
      };

  @override
  String toString() =>
      'Placemark{point: $point, opacity: $opacity, draggable: $draggable, icon: $icon, onTap: $onTap}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Placemark &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          opacity == other.opacity &&
          draggable == other.draggable &&
          icon == other.icon &&
          onTap == other.onTap;

  @override
  int get hashCode =>
      point.hashCode ^
      opacity.hashCode ^
      draggable.hashCode ^
      icon.hashCode ^
      onTap.hashCode;

  factory Placemark.fromMap(Map map) {
    return Placemark(
      point: Point.fromMap(map['point']),
      opacity: map['opacity'] as double,
      draggable: map['draggable'] as bool,
      icon: map['icon'] as String,
    );
  }
}
