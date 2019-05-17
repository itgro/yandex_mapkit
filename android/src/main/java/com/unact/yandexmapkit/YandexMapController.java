package com.unact.yandexmapkit;

import android.content.Context;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.yandex.mapkit.Animation;
import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.geometry.LinearRing;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.geometry.Polygon;
import com.yandex.mapkit.map.CameraListener;
import com.yandex.mapkit.map.CameraPosition;
import com.yandex.mapkit.map.CameraUpdateSource;
import com.yandex.mapkit.map.PolygonMapObject;
import com.yandex.mapkit.mapview.MapView;
import com.yandex.mapkit.map.Map;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;


public class YandexMapController implements PlatformView, MethodChannel.MethodCallHandler, Map.CameraCallback {
    private final MapView mapView;
    private final MethodChannel methodChannel;

    public YandexMapController(int id, Context context, PluginRegistry.Registrar registrar) {
        MapKitFactory.initialize(context);

        mapView = new MapView(context);

        MapKitFactory.getInstance().onStart();

        mapView.onStart();

        methodChannel = new MethodChannel(registrar.messenger(), "yandex_mapkit/yandex_map_" + id);
        methodChannel.setMethodCallHandler(this);

        mapView.getMap().addCameraListener(new YandexCameraListener());
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        mapView.onStop();
        MapKitFactory.getInstance().onStop();
    }

    @SuppressWarnings("unchecked")
    private void move(MethodCall call) {
        JsonCameraMoveParameters params = new Gson().fromJson(
                (String) call.arguments,
                JsonCameraMoveParameters.class
        );

        CameraPosition position = params.position.toCameraPosition();
        Animation animation = params.getAnimation();

        if (animation != null) {
            mapView.getMap().move(position, animation, this);
        } else {
            mapView.getMap().move(position);
        }
    }

    @SuppressWarnings("unchecked")
    private void addPolygon(MethodCall call) {
        JsonPolygon params = new Gson().fromJson(
                (String) call.arguments,
                JsonPolygon.class
        );

        Polygon polygon = params.getPolygon();

        PolygonMapObject mapObject = mapView.getMap().getMapObjects().addPolygon(polygon);
        mapObject.setFillColor((int) params.fillColor);
        mapObject.setStrokeColor((int) params.strokeColor);
        mapObject.setStrokeWidth(params.strokeWidth);
        mapObject.setZIndex(params.zIndex);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "move":
                move(call);
                result.success(null);
                break;
            case "addPolygon":
                addPolygon(call);
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onMoveFinished(boolean b) {
    }

    private class JsonPoint {
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

    private class JsonPosition {
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

    private class JsonPolygon {
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

    private class JsonPositionChangedEvent {
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

    private class JsonCameraAnimation {
        long duration; // duration in miliseconds
        boolean smooth;

        JsonCameraAnimation(boolean smooth, int duration) {
            this.smooth = smooth;
            this.duration = duration;
        }
    }

    private class JsonCameraMoveParameters {
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

    private class YandexCameraListener implements CameraListener {
        @Override
        public void onCameraPositionChanged(@NonNull Map map, @NonNull CameraPosition position, @NonNull CameraUpdateSource cameraUpdateSource, boolean finished) {
            JsonPositionChangedEvent event = new JsonPositionChangedEvent(position, finished);
            methodChannel.invokeMethod("onCameraPositionChanged", new Gson().toJson(event));
        }
    }
}
