package com.unact.yandexmapkit;

import androidx.annotation.Nullable;

import com.yandex.mapkit.Animation;
import com.yandex.mapkit.GeoObject;
import com.yandex.mapkit.GeoObjectCollection;
import com.yandex.mapkit.atom.Link;
import com.yandex.mapkit.geometry.BoundingBox;
import com.yandex.mapkit.geometry.LinearRing;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polygon;
import com.yandex.mapkit.map.CameraPosition;
import com.yandex.mapkit.search.Address;
import com.yandex.mapkit.search.BusinessObjectMetadata;
import com.yandex.mapkit.search.Response;
import com.yandex.mapkit.search.Search;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.SearchType;
import com.yandex.mapkit.search.ToponymObjectMetadata;
import com.yandex.runtime.Error;
import com.yandex.runtime.any.Collection;

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

    static class JsonBoundingBox {
        JsonPoint northEast;
        JsonPoint southWest;

        JsonBoundingBox(BoundingBox boundingBox) {
            this.northEast = new JsonPoint(boundingBox.getNorthEast());
            this.southWest = new JsonPoint(boundingBox.getSouthWest());
        }

        BoundingBox toBoundingBox() {
            return new BoundingBox(
                    southWest.toPoint(),
                    northEast.toPoint()
            );
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
}
