package com.unact.yandexmapkit;

import android.app.Activity;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.google.gson.Gson;
import com.unact.yandexmapkit.YandexJsonConversion.JsonBoundingBox;
import com.unact.yandexmapkit.YandexJsonConversion.JsonSuggestResult;
import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.search.SearchFactory;
import com.yandex.mapkit.search.SearchManager;
import com.yandex.mapkit.search.SearchManagerType;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.SearchType;
import com.yandex.mapkit.search.SuggestItem;
import com.yandex.runtime.Error;

import java.util.List;

public class YandexMapkitPlugin implements MethodCallHandler, EventChannel.StreamHandler {
    private static boolean isApiKeySet = false;

    @SuppressWarnings("FieldCanBeLocal")
    private static MethodChannel channel;

    @SuppressWarnings("FieldCanBeLocal")
    private static EventChannel suggestChannel;

    private Activity activity;
    private SearchManager manager;

    private EventChannel.EventSink eventSink;

    public static void registerWith(Registrar registrar) {
        YandexMapkitPlugin instance = new YandexMapkitPlugin(registrar.activity());

        channel = new MethodChannel(registrar.messenger(), "yandex_mapkit");
        channel.setMethodCallHandler(instance);

        suggestChannel = new EventChannel(registrar.messenger(), "yandex_mapkit_suggest_result");
        suggestChannel.setStreamHandler(instance);

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

    private SearchManager getManager() {
        if (manager == null) {
            manager = SearchFactory.getInstance().createSearchManager(SearchManagerType.COMBINED);
        }

        return manager;
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    class SuggestArguments {
        String text;
        String type;
        JsonBoundingBox window;

        public SuggestArguments(String text, String type, JsonBoundingBox window) {
            this.text = text;
            this.type = type;
            this.window = window;
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "setApiKey": {
                setApiKey(call);
                result.success(null);
            }
            case "cancelSuggest": {
                setApiKey(call);
                result.success(null);
            }
            case "suggest": {
                SuggestArguments params = new Gson().fromJson(
                        (String) call.arguments,
                        SuggestArguments.class
                );
                SearchOptions options = new SearchOptions();

                if (params.type.equals("biz")) {
                    options.setSearchTypes(SearchType.BIZ.value);
                } else if (params.type.equals("geo")) {
                    options.setSearchTypes(SearchType.GEO.value);
                }

                this.getManager().suggest(
                        params.text,
                        params.window.toBoundingBox(),
                        options,
                        new SearchManager.SuggestListener() {
                            @Override
                            public void onSuggestResponse(@NonNull List<SuggestItem> list) {
                                JsonSuggestResult result = new JsonSuggestResult(list);

                                if (eventSink != null) {
                                    eventSink.success(new Gson().toJson(result));
                                }
                            }

                            @Override
                            public void onSuggestError(@NonNull Error error) {
                                JsonSuggestResult result = new JsonSuggestResult(error);

                                if (eventSink != null) {
                                    eventSink.success(new Gson().toJson(result));
                                }
                            }
                        }
                );
            }
            break;
            default:
                result.notImplemented();
                break;
        }
    }
}
