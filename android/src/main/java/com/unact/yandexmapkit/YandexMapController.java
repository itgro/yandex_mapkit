package com.unact.yandexmapkit;

import android.content.Context;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.unact.yandexmapkit.YandexJsonConversion.JsonCameraMoveParameters;
import com.unact.yandexmapkit.YandexJsonConversion.JsonPolygon;
import com.unact.yandexmapkit.YandexJsonConversion.JsonPositionChangedEvent;
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
    private final YandexCameraListener cameraListener;

    public YandexMapController(int id, Context context, PluginRegistry.Registrar registrar) {
        MapKitFactory.initialize(context);

        mapView = new MapView(context);

        MapKitFactory.getInstance().onStart();

        mapView.onStart();

        methodChannel = new MethodChannel(registrar.messenger(), "yandex_mapkit/yandex_map_" + id);
        methodChannel.setMethodCallHandler(this);

        cameraListener = new YandexCameraListener();

        mapView.getMap().addCameraListener(cameraListener);
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

    private class YandexCameraListener implements CameraListener {
        @Override
        public void onCameraPositionChanged(@NonNull Map map, @NonNull CameraPosition position, @NonNull CameraUpdateSource cameraUpdateSource, boolean finished) {
            JsonPositionChangedEvent event = new JsonPositionChangedEvent(position, finished);
            methodChannel.invokeMethod("onCameraPositionChanged", new Gson().toJson(event));
        }
    }
}
