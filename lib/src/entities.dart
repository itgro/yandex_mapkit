import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:yandex_geometry/yandex_geometry.dart';
import 'package:yandex_geometry/json_conversion.dart';

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

@immutable
class SuggestItem {
  final SuggestItemType type;
  final String title;
  final String subtitle;
  final String searchText;
  final String displayText;
  final bool isPersonal;
  final bool isWordItem;
  final SuggestItemAction action;
  final Distance distance;
  final List<String> tags;

  SuggestItem({
    this.type,
    this.title,
    this.subtitle,
    this.searchText,
    this.displayText,
    this.isPersonal,
    this.isWordItem,
    this.action,
    this.distance,
    this.tags,
  });

  factory SuggestItem.fromMap(Map map) {
    SuggestItemType type;

    switch (stringFromJson(map, 'type')) {
      case "transit":
        type = SuggestItemType.Transit;
        break;
      case "toponym":
        type = SuggestItemType.Toponym;
        break;
      case "business":
        type = SuggestItemType.Business;
        break;
      default:
        type = SuggestItemType.Unknown;
        break;
    }

    SuggestItemAction action;

    switch (stringFromJson(map, 'action')) {
      case "search":
        action = SuggestItemAction.Search;
        break;
      default:
        action = SuggestItemAction.Substitute;
        break;
    }

    return SuggestItem(
      type: type,
      title: stringFromJson(map, "title"),
      subtitle: stringFromJson(map, "subtitle"),
      searchText: stringFromJson(map, "searchText"),
      displayText: stringFromJson(map, "displayText"),
      isPersonal: boolFromJson(map, "isPersonal"),
      isWordItem: boolFromJson(map, "isWordItem"),
      action: action,
      tags: collectionFromJson<String, String>(
          map, "tags", (String value) => value),
    );
  }

  @override
  String toString() =>
      'SuggestItem{type: $type, title: $title, subtitle: $subtitle, searchText: $searchText, displayText: $displayText, isPersonal: $isPersonal, isWordItem: $isWordItem, action: $action, distance: $distance, tags: $tags}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestItem &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title &&
          subtitle == other.subtitle &&
          searchText == other.searchText &&
          displayText == other.displayText &&
          isPersonal == other.isPersonal &&
          isWordItem == other.isWordItem &&
          action == other.action &&
          distance == other.distance &&
          tags == other.tags;

  @override
  int get hashCode =>
      type.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      searchText.hashCode ^
      displayText.hashCode ^
      isPersonal.hashCode ^
      isWordItem.hashCode ^
      action.hashCode ^
      distance.hashCode ^
      tags.hashCode;
}

@immutable
class SuggestResult {
  final bool isError;
  final String error;
  final List<SuggestItem> items;

  SuggestResult({
    this.isError,
    this.error,
    this.items,
  });

  factory SuggestResult.fromMap(Map map) => SuggestResult(
        isError: boolFromJson(map, 'isError'),
        error: stringFromJson(map, 'error'),
        items: collectionFromJson<SuggestItem, Map>(
            map, 'items', (Map map) => SuggestItem.fromMap(map)),
      );

  factory SuggestResult.fromString(String string) {
    try {
      Map map = json.decode(string);

      if (map is Map) {
        return SuggestResult.fromMap(map);
      }

      return SuggestResult(
        isError: true,
        error: "Cannot parse suggest result",
        items: [],
      );
    } catch (error) {
      return SuggestResult(
        isError: true,
        error: error.toString(),
        items: [],
      );
    }
  }

  @override
  String toString() =>
      'SuggestResult{isError: $isError, error: $error, items: $items}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestResult &&
          runtimeType == other.runtimeType &&
          isError == other.isError &&
          error == other.error &&
          items == other.items;

  @override
  int get hashCode => isError.hashCode ^ error.hashCode ^ items.hashCode;
}

enum SuggestItemAction { Search, Substitute }

enum SuggestItemType { Unknown, Transit, Toponym, Business }

enum SearchType { Geo, Biz }
