package com.unact.yandexmapkit;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.google.gson.Gson;
import com.unact.yandexmapkit.YandexJsonConversion.JsonSearchResponse;
import com.yandex.mapkit.MapKitFactory;
import com.yandex.mapkit.geometry.BoundingBox;
import com.yandex.mapkit.geometry.Point;
import com.yandex.mapkit.search.Response;
import com.yandex.mapkit.search.SearchFactory;
import com.yandex.mapkit.search.SearchManager;
import com.yandex.mapkit.search.SearchManagerType;
import com.yandex.mapkit.search.SearchOptions;
import com.yandex.mapkit.search.SearchType;
import com.yandex.mapkit.search.Session;
import com.yandex.mapkit.search.SuggestItem;
import com.yandex.runtime.Error;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class YandexMapkitPlugin implements MethodCallHandler {
    private static boolean isApiKeySet = false;
    private static Registrar registrar;
    private static MethodChannel channel;

    private Activity activity;

    private Map<String, DisposableSearchManager> searchManagers = new HashMap<>();

    public static void registerWith(Registrar registrar) {
        YandexMapkitPlugin.registrar = registrar;
        channel = new MethodChannel(registrar.messenger(), "yandex_mapkit");

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
            case "createSearchManager": {
                DisposableSearchManager manager = new DisposableSearchManager(call);

                searchManagers.put(manager.getUuid(), manager);

                result.success(manager.getUuid());
            }
            break;
            case "disposeSearchManager": {
                //noinspection SuspiciousMethodCalls
                searchManagers.remove(call.arguments);

                result.success(null);
            }
            break;
            default:
                result.notImplemented();
                break;
        }
    }

    private class DisposableSearchManager implements MethodCallHandler, SearchManager.SuggestListener {
        private UUID uuid;
        private SearchManager searchManager;
        private MethodChannel methodChannel;

        private Map<String, Session> sessions = new HashMap<>();

        private int sessionCounter;

        DisposableSearchManager(MethodCall call) {
            uuid = UUID.randomUUID();

            SearchManagerType type = SearchManagerType.DEFAULT;

            if (call.hasArgument("type")) {
                switch (call.<String>argument("type")) {
                    case "combined":
                        type = SearchManagerType.COMBINED;
                        break;
                    case "online":
                        type = SearchManagerType.ONLINE;
                        break;
                    case "offline":
                        type = SearchManagerType.OFFLINE;
                        break;
                }
            }

            searchManager = SearchFactory.getInstance().createSearchManager(type);

            methodChannel = new MethodChannel(registrar.messenger(), "yandex_mapkit/search_manager_" + uuid.toString());
            methodChannel.setMethodCallHandler(this);
        }

        String getUuid() {
            return uuid.toString();
        }

        String submitWithPoint(MethodCall call) throws Exception {
            String sessionId = Integer.toString(sessionCounter);
            Session session = searchManager.submit(
                    point(call, null),
                    zoom(call),
                    options(call),
                    new SessionResultListener(sessionId)
            );

            sessionCounter++;
            sessions.put(sessionId, session);

            return sessionId;
        }

        void suggestWithText(MethodCall call) throws Exception {
            String suggestText = call.argument("text");

            searchManager.suggest(
                    suggestText == null ? "" : suggestText,
                    boundingBox(call),
                    options(call),
                    this
            );
        }

        BoundingBox boundingBox(MethodCall call) throws Exception {
            Point northEast = point(call, "1");
            Point southWest = point(call, "2");

            return new BoundingBox(northEast, southWest);
        }

        private Point point(MethodCall call, @Nullable String prefix) throws Exception {
            String latitudeKey = "latitude";
            String longitudeKey = "longitude";

            if (prefix != null) {
                latitudeKey += prefix;
                longitudeKey += prefix;
            }

            if (!call.hasArgument(latitudeKey) || !call.hasArgument(longitudeKey)) {
                throw new Exception("Invalid parameters");
            }

            return new Point(
                    (double) call.argument(latitudeKey),
                    (double) call.argument(longitudeKey)
            );
        }

        private int zoom(MethodCall call) {
            int zoom = 17;

            if (call.hasArgument("zoom")) {
                //noinspection ConstantConditions
                zoom = call.argument("zoom");
            }

            return zoom;
        }

        private SearchOptions options(MethodCall call) {
            List<String> stringTypes = call.argument("types");

            SearchOptions options = new SearchOptions();

            int searchTypes = 0;

            if (stringTypes != null) {
                for (String value : stringTypes) {
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
            }

            options.setSearchTypes(searchTypes);

            return options;
        }

        @Override
        public void onMethodCall(MethodCall call, Result result) {
            switch (call.method) {
                case "submitWithPoint": {
                    try {
                        result.success(submitWithPoint(call));
                    } catch (Exception ignored) {
                        result.error("", null, null);
                    }
                }
                case "suggestWithText": {
                    try {
                        suggestWithText(call);
                        result.success(null);
                    } catch (Exception ignored) {
                        result.error("", null, null);
                    }
                }
                case "cancelSuggest": {
                    try {
                        searchManager.cancelSuggest();
                        result.success(null);
                    } catch (Exception ignored) {
                        result.error("", null, null);
                    }
                }
                break;
                case "cancel": {
                    //noinspection SuspiciousMethodCalls
                    Session session = sessions.get(call.arguments);

                    if (session != null) {
                        session.cancel();
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
        public void onSuggestResponse(@NonNull List<SuggestItem> list) {

        }

        @Override
        public void onSuggestError(@NonNull Error error) {

        }

        private class SessionResultListener implements Session.SearchListener {
            String sessionId;

            SessionResultListener(String sessionId) {
                this.sessionId = sessionId;
            }

            @Override
            public void onSearchResponse(@NonNull Response response) {
                sendToDart(new JsonSearchResponse(sessionId, response));
            }

            @Override
            public void onSearchError(@NonNull Error error) {
                sendToDart(new JsonSearchResponse(sessionId, error));
            }

            private void sendToDart(JsonSearchResponse response) {
                if (sessions.containsKey(sessionId)) {
                    methodChannel.invokeMethod("searchResponse", new Gson().toJson(response));
                }
            }
        }
    }
}
