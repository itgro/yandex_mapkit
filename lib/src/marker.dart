import 'package:flutter/material.dart';
import 'package:yandex_geometry/yandex_geometry.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

@immutable
class MarkerId {
  MarkerId(this.value) : assert(value != null);

  final String value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final MarkerId typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return 'MarkerId{value: $value}';
  }
}

@immutable
class MarkerUpdate {
  final double alpha;

  final BitmapDescriptor icon;

  final double zIndex;

  final bool draggable;

  final bool visible;

  final VoidCallback onTap;

  MarkerUpdate({
    this.alpha = 1.0,
    this.icon = BitmapDescriptor.defaultMarker,
    this.draggable = false,
    this.visible = true,
    this.onTap,
    this.zIndex = 1,
  });

  Map toMap() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('alpha', alpha);
    addIfPresent('draggable', draggable);
    addIfPresent('visible', visible);
    addIfPresent('icon', icon?.toMap());
    addIfPresent('zIndex', zIndex);

    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerUpdate &&
          runtimeType == other.runtimeType &&
          alpha == other.alpha &&
          icon == other.icon &&
          zIndex == other.zIndex &&
          onTap == other.onTap;

  @override
  int get hashCode =>
      alpha.hashCode ^ icon.hashCode ^ zIndex.hashCode ^ onTap.hashCode;

  @override
  String toString() {
    return 'MarkerUpdate{alpha: $alpha, icon: $icon, zIndex: $zIndex, draggable: $draggable, visible: $visible, onTap: $onTap}';
  }
}
