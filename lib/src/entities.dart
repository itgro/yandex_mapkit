import 'dart:convert';

import 'package:flutter/material.dart';

double _double(source) => double.tryParse(source.toString()) ?? .0;

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
    return Point(
      _double(map['latitude']),
      _double(map['longitude']),
    );
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
        tilt: _double(map['tilt']),
        zoom: _double(map['zoom']),
        azimuth: _double(map['azimuth']),
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

enum SearchType { Geo, Biz, Transit, Collections, Direct }

@immutable
class SearchOptions {
  final List<SearchType> searchTypes;

  SearchOptions({this.searchTypes = const []});

  Map toMap() => {
        "searchTypes": searchTypes.map<String>((SearchType type) {
          switch (type) {
            case SearchType.Geo:
              return "geo";
            case SearchType.Biz:
              return "biz";
            case SearchType.Transit:
              return "transit";
            case SearchType.Collections:
              return "collections";
            case SearchType.Direct:
              return "direct";
          }
        }).toList(growable: false),
      };

  @override
  String toString() => 'SearchOptions{searchTypes: $searchTypes}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchOptions &&
          runtimeType == other.runtimeType &&
          searchTypes == other.searchTypes;

  @override
  int get hashCode => searchTypes.hashCode;
}

class SubmitWithPointParameters {
  final Point point;
  final double zoom;
  final SearchOptions searchOptions;

  SubmitWithPointParameters({
    @required this.point,
    this.zoom,
    this.searchOptions,
  });

  Map toMap() => {
        "point": point.toMap(),
        "zoom": zoom,
        "searchOptions": searchOptions?.toMap(),
      };

  @override
  String toString() =>
      'SubmitWithPointParameters{point: $point, zoom: $zoom, searchOptions: $searchOptions}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmitWithPointParameters &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          zoom == other.zoom &&
          searchOptions == other.searchOptions;

  @override
  int get hashCode => point.hashCode ^ zoom.hashCode ^ searchOptions.hashCode;
}

@immutable
class SearchResultItemAddressComponent {
  final String name;
  final List<String> kinds;

  SearchResultItemAddressComponent({
    this.name,
    this.kinds,
  });

  @override
  String toString() =>
      'SearchResultItemAddressComponent{name: $name, kinds: $kinds}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItemAddressComponent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          kinds == other.kinds;

  @override
  int get hashCode => name.hashCode ^ kinds.hashCode;

  factory SearchResultItemAddressComponent.fromMap(Map map) {
    List<String> kinds = [];

    if (map.containsKey('kinds')) {
      var jsonItems = map['kinds'];

      if (jsonItems is Iterable) {
        for (String kind in jsonItems) {
          kinds.add(kind);
        }
      }
    }

    return SearchResultItemAddressComponent(
      name: map['name'] as String,
      kinds: kinds,
    );
  }
}

@immutable
class SearchResultItemAddress {
  final String formattedAddress;
  final String additionalInfo;
  final String countryCode;
  final String postalCode;
  final List<SearchResultItemAddressComponent> components;

  SearchResultItemAddress({
    this.formattedAddress,
    this.additionalInfo,
    this.countryCode,
    this.postalCode,
    this.components,
  });

  @override
  String toString() =>
      'SearchResultItemAddress{formattedAddress: $formattedAddress, additionalInfo: $additionalInfo, countryCode: $countryCode, postalCode: $postalCode, components: $components}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItemAddress &&
          runtimeType == other.runtimeType &&
          formattedAddress == other.formattedAddress &&
          additionalInfo == other.additionalInfo &&
          countryCode == other.countryCode &&
          postalCode == other.postalCode &&
          components == other.components;

  @override
  int get hashCode =>
      formattedAddress.hashCode ^
      additionalInfo.hashCode ^
      countryCode.hashCode ^
      postalCode.hashCode ^
      components.hashCode;

  factory SearchResultItemAddress.fromMap(Map map) => SearchResultItemAddress(
        formattedAddress: map['formattedAddress'] as String,
        additionalInfo: map['additionalInfo'] as String,
        countryCode: map['countryCode'] as String,
        postalCode: map['postalCode'] as String,
        components: (map['components'] as List)
            .map<SearchResultItemAddressComponent>((dynamic value) {
          return SearchResultItemAddressComponent.fromMap(value);
        }).toList(),
      );
}

@immutable
class SearchResultItem {
  final String name;
  final String description;
  final SearchResultItemAddress address;

  SearchResultItem({@required this.name, this.description, this.address});

  factory SearchResultItem.fromMap(Map map) => SearchResultItem(
        name: map['name'] as String,
        description: map['description'] as String,
        address: SearchResultItemAddress.fromMap(map['address']),
      );

  @override
  String toString() =>
      'SearchResultItem{name: $name, description: $description, address: $address}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          address == other.address;

  @override
  int get hashCode => name.hashCode ^ description.hashCode ^ address.hashCode;
}

@immutable
class SearchResult {
  final List<SearchResultItem> items;

  SearchResult({@required this.items});

  factory SearchResult.fromString(String jsonString) =>
      SearchResult.fromMap(json.decode(jsonString));

  factory SearchResult.fromMap(Map map) {
    List<SearchResultItem> items = [];

    if (map.containsKey('items')) {
      var jsonItems = map['items'];

      if (jsonItems is Iterable) {
        for (Map item in jsonItems) {
          items.add(SearchResultItem.fromMap(item));
        }
      }
    }

    return SearchResult(items: items);
  }

  @override
  String toString() => 'SearchResult{items: $items}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          items == other.items;

  @override
  int get hashCode => items.hashCode;
}
