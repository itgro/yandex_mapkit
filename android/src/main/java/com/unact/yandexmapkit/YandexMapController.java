package com.unact.yandexmapkit;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.Image;
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
import com.yandex.mapkit.layers.ObjectEvent;
import com.yandex.mapkit.map.CameraListener;
import com.yandex.mapkit.map.CameraPosition;
import com.yandex.mapkit.map.CameraUpdateSource;
import com.yandex.mapkit.map.MapObject;
import com.yandex.mapkit.map.MapObjectDragListener;
import com.yandex.mapkit.map.MapObjectTapListener;
import com.yandex.mapkit.map.PlacemarkMapObject;
import com.yandex.mapkit.map.PolygonMapObject;
import com.yandex.mapkit.mapview.MapView;
import com.yandex.mapkit.map.Map;
import com.yandex.mapkit.user_location.UserLocationLayer;
import com.yandex.mapkit.user_location.UserLocationObjectListener;
import com.yandex.mapkit.user_location.UserLocationView;
import com.yandex.runtime.image.ImageProvider;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.UUID;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.view.FlutterMain;

public class YandexMapController implements PlatformView, MethodChannel.MethodCallHandler, Map.CameraCallback {
    private final MapView mapView;
    private final MethodChannel methodChannel;
    private final YandexCameraListener cameraListener;

    private java.util.Map<String, YandexMapMarkerController> idToController = new HashMap<>();

    private YandexMapUserLayerController userLocationController;

    private Context context;

    YandexMapController(int id, Context context, PluginRegistry.Registrar registrar) {
        MapKitFactory.initialize(context);

        mapView = new MapView(context);

        MapKitFactory.getInstance().onStart();

        mapView.onStart();

        methodChannel = new MethodChannel(registrar.messenger(), "yandex_mapkit/yandex_map_" + id);
        methodChannel.setMethodCallHandler(this);

        cameraListener = new YandexCameraListener();

        mapView.getMap().addCameraListener(cameraListener);

        this.context = context;
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


    private String addMarker(MethodCall call) {
        YandexJsonConversion.JsonPoint point = new Gson().fromJson(
                (String) call.argument("point"),
                YandexJsonConversion.JsonPoint.class
        );

        YandexMapMarkerController markerController = new YandexMapMarkerController(point);

        updateMarkerWithController(markerController, call);

        return markerController.id;
    }

    private void updateMarker(MethodCall call) {
        String id = call.argument("id");

        YandexMapMarkerController controller = idToController.get(id);

        if (controller != null) {
            updateMarkerWithController(controller, call);
        }
    }

    private void updateMarkerWithController(YandexMapMarkerController markerController, MethodCall call) {
        if (call.hasArgument("icon")) {
            markerController.setIcon(call.argument("icon"));
        }

        if (call.hasArgument("visible")) {
            markerController.setVisible((boolean) call.argument("visible"));
        }

        if (call.hasArgument("draggable")) {
            markerController.setDraggable((boolean) call.argument("draggable"));
        }

        if (call.hasArgument("zIndex")) {
            markerController.setZIndex(((Double) call.argument("zIndex")).floatValue());
        }

        if (call.hasArgument("opacity")) {
            markerController.setZIndex(((Double) call.argument("opacity")).floatValue());
        }
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "move":
                move(call);
                result.success(null);
                break;

            case "showUserLocation": {
                if (userLocationController == null) {
                    ImageProvider image = YandexJsonConversion.ImageConversion.fromFlutter(context, call.arguments);

                    if (image != null) {
                        userLocationController = new YandexMapUserLayerController(image);
                    }
                }
            }

            case "polygon#add":
                addPolygon(call);
                result.success(null);
                break;
            case "marker#init":
                result.success(addMarker(call));
                break;
            case "marker#update":
                updateMarker(call);
                result.success(null);
                break;
            case "marker#remove": {
                String id = call.argument("id");

                YandexMapMarkerController controller = idToController.get(id);

                if (controller != null) {
                    controller.remove();
                }

                result.success(null);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onMoveFinished(boolean b) {
    }


    private class YandexMapUserLayerController implements UserLocationObjectListener {
        private ImageProvider image;

        YandexMapUserLayerController(ImageProvider image) {
            this.image = image;

            UserLocationLayer userLocationLayer = mapView.getMap().getUserLocationLayer();

            userLocationLayer.setEnabled(true);
            userLocationLayer.setHeadingEnabled(true);

            userLocationLayer.setObjectListener(this);
        }

        @Override
        public void onObjectAdded(@NonNull UserLocationView userLocationView) {
            userLocationView.getPin().setIcon(image);
            userLocationView.getArrow().setVisible(false);
            userLocationView.getAccuracyCircle().setVisible(false);
        }

        @Override
        public void onObjectRemoved(@NonNull UserLocationView userLocationView) {

        }

        @Override
        public void onObjectUpdated(@NonNull UserLocationView userLocationView, @NonNull ObjectEvent objectEvent) {

        }
    }

    private class YandexMapMarkerController implements MapObjectTapListener, MapObjectDragListener {
        String id;
        private PlacemarkMapObject mapObject;

        YandexMapMarkerController(YandexJsonConversion.JsonPoint point) {
            this(point.toPoint());
        }

        YandexMapMarkerController(Point point) {
            id = UUID.randomUUID().toString();

            mapObject = mapView.getMap().getMapObjects().addPlacemark(point);

            mapObject.addTapListener(this);
            mapObject.setDragListener(this);

            idToController.put(id, this);
        }


        public void setIcon(Object o) {
            ImageProvider provider = YandexJsonConversion.ImageConversion.fromFlutter(context, o);

            if (provider != null) {
                mapObject.setIcon(provider);
            }
        }

        public void setOpacity(float opacity) {
            mapObject.setOpacity(opacity);
        }

        public void setZIndex(float zIndex) {
            mapObject.setZIndex(zIndex);
        }

        public void setDraggable(boolean draggable) {
            mapObject.setDraggable(draggable);
        }

        public void setVisible(boolean visible) {
            mapObject.setVisible(visible);
        }

        public void remove() {
            mapView.getMap().getMapObjects().remove(mapObject);
            idToController.remove(id);
        }

        @Override
        public void onMapObjectDragStart(@NonNull MapObject mapObject) {
            methodChannel.invokeMethod("onMapObjectDragStart", id);
        }

        @Override
        public void onMapObjectDrag(@NonNull MapObject mapObject, @NonNull Point point) {
            methodChannel.invokeMethod("onMapObjectDrag", new Gson().toJson(new YandexJsonConversion.JsonMapObjectEventWithPoint(id, point)));
        }

        @Override
        public void onMapObjectDragEnd(@NonNull MapObject mapObject) {
            methodChannel.invokeMethod("onMapObjectDragEnd", id);
        }

        @Override
        public boolean onMapObjectTap(@NonNull MapObject mapObject, @NonNull Point point) {
            methodChannel.invokeMethod("onMapObjectTap", new Gson().toJson(new YandexJsonConversion.JsonMapObjectEventWithPoint(id, point)));

            return true;
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
