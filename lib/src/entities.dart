import 'dart:convert';

import 'package:flutter/material.dart';

double _double(source) => double.tryParse(source.toString()) ?? .0;

enum Kind {
  /// станция
  Station,

  /// станция
  MetroStation,

  /// станция
  RailwayStation,

  /// вход
  Entrance,

  /// отдельный дом
  House,

  /// улица
  Street,

  /// станция метро
  Metro,

  /// район города
  District,

  /// населённый пункт: город / поселок / деревня / село и т. п.
  Locality,

  /// район области
  Area,

  /// область
  Province,

  /// страна
  Country,

  /// регион
  Region,

  /// река / озеро / ручей / водохранилище и т. п.
  Hydro,

  /// ж.д. станция
  Railway,

  /// линия метро / шоссе / ж.д. линия
  Route,

  /// лес / парк / сад и т. п.
  Vegetation,

  /// аэропорт
  Airport,
  Other,
  Unknown,
}

enum Precision {
  /// Найден дом с указанным номером дома.
  Exact,

  /// Найден дом с указанным номером, но с другим номером строения или корпуса.
  Number,

  /// Найден дом с номером, близким к запрошенному.
  Near,

  /// Найдены приблизительные координаты запрашиваемого дома.
  Range,

  /// Найдена только улица.
  Street,

  /// Не найдена улица, но найден, например, посёлок, район и т. п.
  Other,
}

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

  const SearchOptions({this.searchTypes = const []});

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
class AddressComponent {
  final String name;
  final List<Kind> kinds;

  AddressComponent({
    @required this.name,
    @required this.kinds,
  });

  @override
  String toString() =>
      'SearchResultItemAddressComponent{name: $name, kinds: $kinds}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressComponent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          kinds == other.kinds;

  @override
  int get hashCode => name.hashCode ^ kinds.hashCode;

  factory AddressComponent.fromMap(Map map) {
    List<Kind> kinds = [];

    if (map.containsKey('kinds')) {
      var jsonItems = map['kinds'];

      if (jsonItems is Iterable) {
        for (String kind in jsonItems) {
          switch (kind) {
            case 'station':
              kinds.add(Kind.Station);
              break;
            case 'metro_station':
              kinds.add(Kind.MetroStation);
              break;
            case 'railway_station':
              kinds.add(Kind.RailwayStation);
              break;
            case 'entrance':
              kinds.add(Kind.Entrance);
              break;
            case 'house':
              kinds.add(Kind.House);
              break;
            case 'street':
              kinds.add(Kind.Street);
              break;
            case 'metro':
              kinds.add(Kind.Station);
              break;
            case 'district':
              kinds.add(Kind.District);
              break;
            case 'locality':
              kinds.add(Kind.Locality);
              break;
            case 'area':
              kinds.add(Kind.Area);
              break;
            case 'province':
              kinds.add(Kind.Province);
              break;
            case 'country':
              kinds.add(Kind.Country);
              break;
            case 'region':
              kinds.add(Kind.Region);
              break;
            case 'hydro':
              kinds.add(Kind.Hydro);
              break;
            case 'railway':
              kinds.add(Kind.Railway);
              break;
            case 'route':
              kinds.add(Kind.Route);
              break;
            case 'vegetation':
              kinds.add(Kind.Vegetation);
              break;
            case 'airport':
              kinds.add(Kind.Airport);
              break;
            case 'other':
              kinds.add(Kind.Other);
              break;
            default:
              kinds.add(Kind.Unknown);
              break;
          }
        }
      }
    }

    return AddressComponent(
      name: map['name'] as String,
      kinds: kinds,
    );
  }
}

@immutable
class Address {
  final String formattedAddress;
  final String additionalInfo;
  final String countryCode;
  final String postalCode;
  final List<AddressComponent> components;

  Address({
    @required this.formattedAddress,
    @required this.additionalInfo,
    @required this.countryCode,
    @required this.postalCode,
    @required this.components,
  });

  @override
  String toString() =>
      'SearchResultItemAddress{formattedAddress: $formattedAddress, additionalInfo: $additionalInfo, countryCode: $countryCode, postalCode: $postalCode, components: $components}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
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

  factory Address.fromMap(Map map) => Address(
        formattedAddress: map['formattedAddress'] as String,
        additionalInfo: map['additionalInfo'] as String,
        countryCode: map['countryCode'] as String,
        postalCode: map['postalCode'] as String,
        components:
            (map['components'] as List).map<AddressComponent>((dynamic value) {
          return AddressComponent.fromMap(value);
        }).toList(),
      );
}

@immutable
class ToponymMetadata {
  final String id;
  final Precision precision;
  final String formerName;
  final Point balloonPoint;
  final Address address;

  ToponymMetadata({
    @required this.id,
    @required this.precision,
    @required this.formerName,
    @required this.balloonPoint,
    @required this.address,
  });

  factory ToponymMetadata.fromMap(Map map) {
    Precision precision;

    switch (map['precision']) {
      case "exact":
        precision = Precision.Exact;
        break;
      case "number":
        precision = Precision.Number;
        break;
      case "range":
        precision = Precision.Range;
        break;
      case "nearby":
        precision = Precision.Near;
        break;
    }

    return ToponymMetadata(
      id: map['id'] as String,
      formerName: map['formerName'] as String,
      balloonPoint: Point.fromMap(map["balloonPoint"]),
      address: Address.fromMap(map['address']),
      precision: precision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToponymMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          precision == other.precision &&
          formerName == other.formerName &&
          balloonPoint == other.balloonPoint &&
          address == other.address;

  @override
  int get hashCode =>
      id.hashCode ^
      precision.hashCode ^
      formerName.hashCode ^
      balloonPoint.hashCode ^
      address.hashCode;
}

@immutable
class SearchResultItem {
  final String name;
  final String description;
  final ToponymMetadata toponym;

  SearchResultItem({
    @required this.name,
    this.description,
    this.toponym,
  });

  Kind get kind {
    if (toponym != null &&
        toponym.address != null &&
        toponym.address.components != null &&
        toponym.address.components.isNotEmpty) {
      return toponym.address.components.last.kinds.last;
    }

    return Kind.Unknown;
  }

  factory SearchResultItem.fromMap(Map map) {
    ToponymMetadata toponym;

    if (map.containsKey("toponym") && map["toponym"] != null) {
      toponym = ToponymMetadata.fromMap(map["toponym"]);
    }

    return SearchResultItem(
      name: map['name'] as String,
      description: map['description'] as String,
      toponym: toponym,
    );
  }

  @override
  String toString() =>
      'SearchResultItem{name: $name, description: $description, toponym: $toponym}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          toponym == other.toponym;

  @override
  int get hashCode => name.hashCode ^ description.hashCode ^ toponym.hashCode;
}

@immutable
class SearchResult {
  final String sessionId;
  final bool isSuccess;
  final List<SearchResultItem> items;

  SearchResult({
    @required this.sessionId,
    @required this.isSuccess,
    this.items = const [],
  });

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

    return SearchResult(
      isSuccess: map['isSuccess'] as bool,
      sessionId: map['sessionId'] as String,
      items: items,
    );
  }

  @override
  String toString() {
    return 'SearchResult{sessionId: $sessionId, isSuccess: $isSuccess, items: $items}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          isSuccess == other.isSuccess &&
          items == other.items;

  @override
  int get hashCode => sessionId.hashCode ^ isSuccess.hashCode ^ items.hashCode;
}
