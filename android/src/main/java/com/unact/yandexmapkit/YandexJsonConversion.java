package com.unact.yandexmapkit;

import androidx.annotation.Nullable;

import com.yandex.mapkit.Animation;
import com.yandex.mapkit.GeoObject;
import com.yandex.mapkit.GeoObjectCollection;
import com.yandex.mapkit.atom.Link;
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

    static class JsonAddressComponent {
        String name;
        List<String> kinds = new LinkedList<>();

        JsonAddressComponent(Address.Component component) {
            name = component.getName();

            for (Address.Component.Kind kind : component.getKinds()) {
                switch (kind) {
                    case UNKNOWN:
                        kinds.add("unknown");
                        break;
                    case COUNTRY:
                        kinds.add("country");
                        break;
                    case REGION:
                        kinds.add("region");
                        break;
                    case PROVINCE:
                        kinds.add("province");
                        break;
                    case AREA:
                        kinds.add("area");
                        break;
                    case LOCALITY:
                        kinds.add("locality");
                        break;
                    case DISTRICT:
                        kinds.add("district");
                        break;
                    case STREET:
                        kinds.add("street");
                        break;
                    case HOUSE:
                        kinds.add("house");
                        break;
                    case ENTRANCE:
                        kinds.add("entrance");
                        break;
                    case ROUTE:
                        kinds.add("route");
                        break;
                    case STATION:
                        kinds.add("station");
                        break;
                    case METRO_STATION:
                        kinds.add("metro_station");
                        break;
                    case RAILWAY_STATION:
                        kinds.add("railway_station");
                        break;
                    case VEGETATION:
                        kinds.add("vegetation");
                        break;
                    case HYDRO:
                        kinds.add("hydro");
                        break;
                    case AIRPORT:
                        kinds.add("airport");
                        break;
                    case OTHER:
                        kinds.add("other");
                        break;
                }
            }
        }
    }

    static class JsonAddress {
        String formattedAddress;
        String additionalInfo;
        String postalCode;
        String countryCode;
        List<JsonAddressComponent> components = new LinkedList<>();

        JsonAddress(Address address) {
            formattedAddress = address.getFormattedAddress();
            additionalInfo = address.getAdditionalInfo();
            postalCode = address.getPostalCode();
            countryCode = address.getCountryCode();

            for (Address.Component component : address.getComponents()) {
                this.components.add(new JsonAddressComponent(component));
            }
        }
    }

    static class JsonToponymData {
        String id;
        String precision;
        String formerName;
        JsonPoint balloonPoint;
        JsonAddress address;

        JsonToponymData(ToponymObjectMetadata metadata) {
            this.id = metadata.getId();
            this.formerName = metadata.getFormerName();
            this.balloonPoint = new JsonPoint(metadata.getBalloonPoint());
            this.address = new JsonAddress(metadata.getAddress());

            if (metadata.getPrecision() != null) {
                switch (metadata.getPrecision()) {
                    case EXACT:
                        precision = "exact";
                        break;
                    case NUMBER:
                        precision = "number";
                        break;
                    case RANGE:
                        precision = "range";
                        break;
                    case NEARBY:
                        precision = "nearby";
                        break;
                }
            }
        }
    }

    static class JsonSearchResultItem {
        String name;
        String description;

        JsonToponymData toponym;

        JsonSearchResultItem(GeoObject obj) {
            this.name = obj.getName();
            this.description = obj.getDescriptionText();

            Collection metadata = obj.getMetadataContainer();
            ToponymObjectMetadata toponym = metadata.getItem(ToponymObjectMetadata.class);

            if (toponym != null) {
                this.toponym = new JsonToponymData(toponym);
            }
        }
    }

    static class JsonSearchResponse {
        String sessionId;
        boolean isSuccess;
        LinkedList<JsonSearchResultItem> items = new LinkedList<>();

        JsonSearchResponse(String sessionId, Response response) {
            this.sessionId = sessionId;
            this.isSuccess = true;
            for (GeoObjectCollection.Item item : response.getCollection().getChildren()) {
                if (item.getObj() != null) {
                    items.add(new JsonSearchResultItem(item.getObj()));
                }
            }
        }

        JsonSearchResponse(String sessionId, Error error) {
            this.sessionId = sessionId;
            this.isSuccess = false;
        }
    }
}
