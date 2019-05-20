package com.unact.yandexmapkit;

import android.app.Activity;
import android.location.Geocoder;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.google.gson.Gson;
import com.unact.yandexmapkit.YandexJsonConversion.JsonSearchResponse;
import com.unact.yandexmapkit.YandexJsonConversion.JsonSubmitWithPointParameters;
import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.search.Response;
import com.yandex.mapkit.search.Search;
import com.yandex.mapkit.search.SearchFactory;
import com.yandex.mapkit.search.SearchManager;
import com.yandex.mapkit.search.SearchManagerType;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.Session;
import com.yandex.runtime.Error;

import java.util.UUID;

public class YandexMapkitPlugin implements MethodCallHandler {
    static MethodChannel channel;
    static Registrar registrar;
    private Activity activity;

    SearchController searchController;

    public static void registerWith(Registrar registrar) {
        YandexMapkitPlugin.registrar = registrar;
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
        SearchFactory.initialize(activity.getApplicationContext());
        searchController = new SearchController();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "setApiKey":
                setApiKey(call);
                result.success(null);
                break;
            case "search#withPoint":
                result.success(searchController.searchWithPoint(call));
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private class SearchController {
        private SearchManager searchManager;

        SearchController() {
            searchManager = SearchFactory.getInstance().createSearchManager(SearchManagerType.COMBINED);
        }

        String searchWithPoint(MethodCall call) {
            JsonSubmitWithPointParameters params = new Gson().fromJson(
                    (String) call.arguments,
                    JsonSubmitWithPointParameters.class
            );

            SearchSessionController session = new SearchSessionController();

            session.submit(params.point.toPoint(), 0, params.getSearchOptions());

            return session.sessionId.toString();
        }

        private class SearchSessionController implements Session.SearchListener, MethodCallHandler {
            UUID sessionId;
            private MethodChannel methodChannel;
            private Session searchSession;

            SearchSessionController() {
                sessionId = UUID.randomUUID();

                methodChannel = new MethodChannel(YandexMapkitPlugin.registrar.messenger(), "yandex_mapkit_search_" + sessionId.toString());
                methodChannel.setMethodCallHandler(this);
            }

            void submit(Point point, int zoom, SearchOptions searchOptions) {
                searchSession = searchManager.submit(point, 20, searchOptions, this);
            }

            void cancel() {
                if (searchSession != null) {
                    searchSession.cancel();
                }
            }

            void dispose() {
                // TODO ???
            }

            @Override
            public void onSearchResponse(@NonNull Response response) {
                try {
                    JsonSearchResponse jsonResponse = new JsonSearchResponse(response);
                    methodChannel.invokeMethod("success", new Gson().toJson(jsonResponse));
                } catch (Exception e) {
                    methodChannel.invokeMethod("failure", e.getLocalizedMessage());
                }
            }

            @Override
            public void onSearchError(@NonNull Error error) {
                methodChannel.invokeMethod("failure", error.toString());
            }

            @Override
            public void onMethodCall(MethodCall call, Result result) {
                switch (call.method) {
                    case "cancel":
                        cancel();
                        result.success(null);
                        break;
                    case "dispose":
                        dispose();
                        result.success(null);
                    default:
                        result.notImplemented();
                        break;
                }
            }
        }
    }
}
