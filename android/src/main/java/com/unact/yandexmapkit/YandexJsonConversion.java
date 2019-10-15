package com.unact.yandexmapkit;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Log;

import androidx.annotation.Nullable;

import com.yandex.mapkit.Animation;
import com.yandex.mapkit.GeoObject;
import com.yandex.mapkit.GeoObjectCollection;
import com.yandex.mapkit.LocalizedValue;
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
import com.yandex.mapkit.search.SuggestItem;
import com.yandex.mapkit.search.ToponymObjectMetadata;
import com.yandex.runtime.Error;
import com.yandex.runtime.any.Collection;
import com.yandex.runtime.image.ImageProvider;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import io.flutter.view.FlutterMain;

class YandexJsonConversion {
    static class ImageConversion {
        static Bitmap scaleBitmap(Bitmap bitmap, double scale) {
            return resizeBitmap(bitmap, (int) (bitmap.getWidth() * scale), (int) (bitmap.getHeight() * scale));
        }

        static Bitmap resizeBitmap(Bitmap bitmap, int targetW, int targetH) {
            double widthRatio = (double) targetW / (double) bitmap.getWidth();
            double heightRatio = (double) targetH / (double) bitmap.getHeight();

            double newWidth;
            double newHeight;

            if (widthRatio > heightRatio) {
                newWidth = bitmap.getWidth() * heightRatio;
                newHeight = bitmap.getHeight() * heightRatio;
            } else {
                newWidth = bitmap.getWidth() * widthRatio;
                newHeight = bitmap.getHeight() * widthRatio;
            }

            return Bitmap.createScaledBitmap(bitmap, (int) newWidth, (int) newHeight, false);
        }

        static ImageProvider fromFlutter(Context context, Object o) {
            try {
                final List<?> data = (List<?>) o;

                switch ((String) data.get(0)) {
                    case "defaultMarker": {
                        break;
                    }

                    case "fromAsset": {
                        String assetName;

                        if (data.size() == 2) {
                            assetName = FlutterMain.getLookupKeyForAsset((String) data.get(1));
                        } else {
                            assetName = FlutterMain.getLookupKeyForAsset((String) data.get(1), (String) data.get(2));
                        }

                        return ImageProvider.fromAsset(context, assetName);
                    }

                    case "fromAssetImage": {
                        String assetName = FlutterMain.getLookupKeyForAsset((String) data.get(1));
                        ImageProvider provider = ImageProvider.fromAsset(context, assetName);

                        if (data.size() == 3) {
                            double scaleParam = Double.parseDouble((String) data.get(2));
                            return ImageProvider.fromBitmap(scaleBitmap(provider.getImage(), scaleParam));
                        } else if (data.size() == 4) {
                            int width = (int) Double.parseDouble((String) data.get(2));
                            int height = (int) Double.parseDouble((String) data.get(3));

                            return ImageProvider.fromBitmap(
                                    resizeBitmap(
                                            provider.getImage(),
                                            (int) (width * context.getResources().getDisplayMetrics().density),
                                            (int) (height * context.getResources().getDisplayMetrics().density)
                                    )
                            );
                        }
                    }
                }
            } catch (Exception e) {
                Log.d("FLUTTER", e.getLocalizedMessage());
            }

            return null;
        }
    }

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

    static class JsonDistance {
        double value;
        String text;

        JsonDistance(LocalizedValue distance) {
            this.value = distance.getValue();
            this.text = distance.getText();
        }
    }

    static class JsonSuggestResult {
        boolean isError;
        String error;
        List<JsonSuggestItem> items;


        JsonSuggestResult(List<SuggestItem> list) {
            isError = false;
            error = null;

            items = new ArrayList<>();

            for (SuggestItem item : list) {
                items.add(new JsonSuggestItem(item));
            }
        }

        JsonSuggestResult(Error error) {
            this.isError = true;
            this.error = error.getClass().getCanonicalName();
            this.items = new ArrayList<>();
        }
    }

    static class JsonSuggestItem {
        String type;
        String title;
        String subtitle;
        String searchText;
        String displayText;
        String action;
        boolean isPersonal;
        boolean isWordItem;

        JsonDistance distance;

        List<String> tags;

        JsonSuggestItem(SuggestItem item) {
            switch (item.getType()) {
                case UNKNOWN:
                    this.type = "unknown";
                    break;
                case TOPONYM:
                    this.type = "toponym";
                    break;
                case BUSINESS:
                    this.type = "business";
                    break;
                case TRANSIT:
                    this.type = "transit";
                    break;
            }

            this.title = item.getTitle().getText();
            if (item.getSubtitle() != null) {
                this.subtitle = item.getSubtitle().getText();
            }
            this.searchText = item.getSearchText();
            this.displayText = item.getDisplayText();
            this.isPersonal = item.getIsPersonal();
            this.isWordItem = item.getIsWordItem();

            if (item.getDistance() != null) {
                this.distance = new JsonDistance(item.getDistance());
            }

            this.action = item.getAction() == SuggestItem.Action.SEARCH ? "search" : "substitute";

            this.tags = item.getTags();
        }
    }

    static class JsonMapObjectEventWithPoint {
        String id;
        JsonPoint point;

        JsonMapObjectEventWithPoint(String id, JsonPoint point) {
            this.id = id;
            this.point = point;
        }

        JsonMapObjectEventWithPoint(String id, Point point) {
            this.id = id;
            this.point = new JsonPoint(point);
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
