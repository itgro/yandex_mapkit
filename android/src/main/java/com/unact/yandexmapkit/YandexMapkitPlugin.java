package com.unact.yandexmapkit;

import android.app.Activity;
import android.location.Geocoder;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.yandex.mapkit.MapKitFactory;

public class YandexMapkitPlugin implements MethodCallHandler {
    static MethodChannel channel;
    private Activity activity;


    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), "yandex_mapkit");
        final YandexMapkitPlugin instance = new YandexMapkitPlugin(registrar.activity());

        channel.setMethodCallHandler(instance);
        registrar.platformViewRegistry().registerViewFactory(
                "yandex_mapkit/yandex_map",
                new YandexMapFactory(registrar)
        );
    }

    private YandexMapkitPlugin(Activity activity) {
        this.activity = activity;
    }

    private void setApiKey(MethodCall call) {
        MapKitFactory.setApiKey(call.arguments.toString());
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "setApiKey":
                setApiKey(call);
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
}
