package com.unact.yandexmapkit;

import android.app.Activity;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.search.SearchFactory;

public class YandexMapkitPlugin implements MethodCallHandler {
    private static boolean isApiKeySet = false;

    private Activity activity;


    public static void registerWith(Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), "yandex_mapkit");

        channel.setMethodCallHandler(
                new YandexMapkitPlugin(registrar.activity())
        );
        registrar.platformViewRegistry().registerViewFactory(
                "yandex_mapkit/yandex_map",
                new YandexMapFactory(registrar)
        );
    }

    private YandexMapkitPlugin(Activity activity) {
        this.activity = activity;
    }

    private void setApiKey(MethodCall call) {
        if (!isApiKeySet) {
            isApiKeySet = true;
            MapKitFactory.setApiKey(call.arguments.toString());
            SearchFactory.initialize(activity.getApplicationContext());
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "setApiKey": {
                setApiKey(call);
                result.success(null);
            }
            break;
            default:
                result.notImplemented();
                break;
        }
    }
}
