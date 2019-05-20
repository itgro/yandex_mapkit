package com.unact.yandexmapkit;

import androidx.annotation.Nullable;

import com.yandex.mapkit.Animation;
import com.yandex.mapkit.GeoObject;
import com.yandex.mapkit.GeoObjectCollection;
import com.yandex.mapkit.geometry.LinearRing;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polygon;
import com.yandex.mapkit.map.CameraPosition;
import com.yandex.mapkit.search.Response;
import com.yandex.mapkit.search.Search;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.SearchType;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

class YandexJsonConversion {
    static class JsonPoint {
        double latitude;
        double longitude;

        JsonPoint(double latitude, double longitude) {
            this.latitude = latitude;
            this.longitude = longitude;
        }

        JsonPoint(Point point) {
            this.latitude = point.getLatitude();
            this.longitude = point.getLongitude();
        }

        Point toPoint() {
            return new Point(latitude, longitude);
        }
    }

    static class JsonPosition {
        JsonPoint target;
        float azimuth;
        float tilt;
        float zoom;

        JsonPosition(JsonPoint target, float azimuth, float tilt, float zoom) {
            this.target = target;
            this.azimuth = azimuth;
            this.tilt = tilt;
            this.zoom = zoom;
        }

        JsonPosition(CameraPosition position) {
            this.target = new JsonPoint(position.getTarget());
            this.azimuth = position.getAzimuth();
            this.tilt = position.getTilt();
            this.zoom = position.getZoom();
        }

        CameraPosition toCameraPosition() {
            return new CameraPosition(target.toPoint(), zoom, azimuth, tilt);
        }
    }

    static class JsonPolygon {
        LinkedList<JsonPoint> points;
        long fillColor;
        long strokeColor;
        float strokeWidth;
        float zIndex;

        JsonPolygon(LinkedList<JsonPoint> points, int fillColor, int strokeColor, float strokeWidth, float zIndex) {
            this.points = points;
            this.fillColor = fillColor;
            this.strokeColor = strokeColor;
            this.strokeWidth = strokeWidth;
            this.zIndex = zIndex;
        }

        Polygon getPolygon() {
            List<Point> polygonPoints = new ArrayList<>();

            for (JsonPoint point : points) {
                polygonPoints.add(point.toPoint());
            }

            return new Polygon(new LinearRing(polygonPoints), new ArrayList<LinearRing>());
        }
    }

    static class JsonPositionChangedEvent {
        JsonPosition position;
        boolean finished;

        JsonPositionChangedEvent(JsonPosition position, boolean finished) {
            this.position = position;
            this.finished = finished;
        }

        JsonPositionChangedEvent(CameraPosition position, boolean finished) {
            this.position = new JsonPosition(position);
            this.finished = finished;
        }
    }

    static class JsonCameraAnimation {
        long duration; // duration in miliseconds
        boolean smooth;

        JsonCameraAnimation(boolean smooth, int duration) {
            this.smooth = smooth;
            this.duration = duration;
        }
    }

    static class JsonCameraMoveParameters {
        JsonPosition position;
        JsonCameraAnimation animation;

        JsonCameraMoveParameters(JsonPosition position, JsonCameraAnimation animation) {
            this.position = position;
            this.animation = animation;
        }

        Animation getAnimation() {
            if (this.animation != null) {
                Animation.Type type = this.animation.smooth
                        ? Animation.Type.SMOOTH
                        : Animation.Type.LINEAR;

                float duration = (float) this.animation.duration / 1000;

                return new Animation(type, duration);
            }

            return null;
        }
    }

    static class JsonSearchOptions {
        LinkedList<String> searchTypes;

        JsonSearchOptions(LinkedList<String> searchTypes) {
            this.searchTypes = searchTypes;
        }

        JsonSearchOptions(int searchTypes) {
            this.searchTypes = new LinkedList<>();

            if ((searchTypes & SearchType.GEO.value) != 0) {
                this.searchTypes.add("geo");
            }

            if ((searchTypes & SearchType.BIZ.value) != 0) {
                this.searchTypes.add("biz");
            }

            if ((searchTypes & SearchType.TRANSIT.value) != 0) {
                this.searchTypes.add("transit");
            }

            if ((searchTypes & SearchType.COLLECTIONS.value) != 0) {
                this.searchTypes.add("collections");
            }

            if ((searchTypes & SearchType.DIRECT.value) != 0) {
                this.searchTypes.add("direct");
            }
        }

        SearchOptions toSearchOptions() {
            SearchOptions options = new SearchOptions();

            int searchTypes = 0;

            for (String value : this.searchTypes) {
                switch (value.toLowerCase()) {
                    case "geo":
                        searchTypes |= SearchType.GEO.value;
                        break;
                    case "biz":
                        searchTypes |= SearchType.BIZ.value;
                        break;
                    case "transit":
                        searchTypes |= SearchType.TRANSIT.value;
                        break;
                    case "collections":
                        searchTypes |= SearchType.COLLECTIONS.value;
                        break;
                    case "direct":
                        searchTypes |= SearchType.DIRECT.value;
                        break;
                }
            }

            options.setSearchTypes(searchTypes);

            return options;
        }
    }

    static class JsonSubmitWithPointParameters {
        JsonPoint point;
        float zoom;
        JsonSearchOptions searchOptions;

        public JsonSubmitWithPointParameters(JsonPoint point, @Nullable float zoom, @Nullable JsonSearchOptions searchOptions) {
            this.point = point;
            this.zoom = zoom;
            this.searchOptions = searchOptions;
        }

        public SearchOptions getSearchOptions() {
            if (searchOptions != null) {
                return searchOptions.toSearchOptions();
            }

            return new SearchOptions();
        }
    }

    static class JsonSearchResultItem {
        String name;
        String description;

        public JsonSearchResultItem(GeoObject obj) {
            this.name = obj.getName();
            this.description = obj.getDescriptionText();
        }
    }

    static class JsonSearchResponse {
        LinkedList<JsonSearchResultItem> items;

        public JsonSearchResponse(Response response) {
            items = new LinkedList<>();

            for (GeoObjectCollection.Item item : response.getCollection().getChildren()) {
                if (item.getObj() != null) {
                    items.add(new JsonSearchResultItem(item.getObj()));
                }
            }
        }
    }
}
