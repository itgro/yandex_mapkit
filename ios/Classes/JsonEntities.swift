import YandexMapKit
import YandexMapKitSearch

public class JsonPoint: Codable {
    let latitude: Double
    let longitude: Double

    public required init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public required init(point: YMKPoint) {
        latitude = point.latitude
        longitude = point.longitude
    }

    public func toPoint() -> YMKPoint {
        return YMKPoint(latitude: latitude, longitude: longitude)
    }
}

public class JsonPosition: Codable {
    let target: JsonPoint
    let azimuth: Float
    let tilt: Float
    let zoom: Float

    public required init(target: JsonPoint, azimuth: Float, tilt: Float, zoom: Float) {
        self.target = target
        self.azimuth = azimuth
        self.tilt = tilt
        self.zoom = zoom
    }

    public required init(position: YMKCameraPosition) {
        target = JsonPoint(point: position.target)
        azimuth = position.azimuth
        tilt = position.tilt
        zoom = position.zoom
    }

    public func toCameraPosition() -> YMKCameraPosition {
        return YMKCameraPosition(target: target.toPoint(), zoom: zoom, azimuth: azimuth, tilt: tilt)
    }
}

public class JsonMapObjectEventWithPoint: Codable {
    let id: String
    let point: JsonPoint
    
    public required init(id: String, point: JsonPoint) {
        self.id = id
        self.point = point
    }
}

public class JsonPolygon: Codable {
    let innerPoints: [JsonPoint]
    let outerPoints: [JsonPoint]
    let fillColor: Int
    let strokeColor: Int
    let strokeWidth: Float
    let zIndex: Float

    public required init(outerPoints: [JsonPoint], innerPoints: [JsonPoint], fillColor: Int, strokeColor: Int, strokeWidth: Float, zIndex: Float) {
        self.outerPoints = outerPoints
        self.innerPoints = innerPoints
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.zIndex = zIndex
    }

    public func getPolygon() -> YMKPolygon {
        var yOuterPoints = [YMKPoint]()
        var yInnerPoints = [YMKPoint]()

        for outerPoint in outerPoints {
            yOuterPoints.append(outerPoint.toPoint())
        }

        for innerPoint in innerPoints {
            yInnerPoints.append(innerPoint.toPoint())
        }
        
        return YMKPolygon(outerRing: YMKLinearRing(points: yOuterPoints), innerRings: [YMKLinearRing(points: yInnerPoints)])
    }
}

public class JsonBoundingBox: Codable {
    let southWest: JsonPoint
    let northEast: JsonPoint

    public required init(boundingBox: YMKBoundingBox) {
        self.southWest = JsonPoint(point: boundingBox.southWest)
        self.northEast = JsonPoint(point: boundingBox.northEast)
    }

    public func toBoundingBox() -> YMKBoundingBox {
        return YMKBoundingBox(
                southWest: southWest.toPoint(),
                northEast: northEast.toPoint()
        )
    }
}

public class JsonDistance: Codable {
    let value: Double
    let text: String

    public required init(distance: YMKLocalizedValue) {
        self.value = distance.value
        self.text = distance.text
    }
}

public class JsonSuggestResult: Encodable {
    let isError: Bool
    let error: String?
    let items: [JsonSuggestItem]

    public required init(items: [YMKSuggestItem]?, error: Error?) {
        self.isError = error != nil;
        self.error = error?.localizedDescription

        var results: [JsonSuggestItem] = []
        if items != nil {
            for item in items! {
                results.append(JsonSuggestItem(item: item))
            }
        }
        self.items = results;
    }
}

public class JsonSuggestItem: Codable {
    let type: String
    let title: String
    let subtitle: String?
    let searchText: String
    let displayText: String?
    let isPersonal: Bool
    let isWordItem: Bool
    let action: String

    let distance: JsonDistance?

    let tags: [String]

    public required init(item: YMKSuggestItem) {
        switch item.type {
        case YMKSuggestItemType.unknown:
            self.type = "unknown"
            break;
        case YMKSuggestItemType.transit:
            self.type = "transit"
            break;
        case YMKSuggestItemType.toponym:
            self.type = "toponym"
            break;
        case YMKSuggestItemType.business:
            self.type = "business"
            break;
        }

        self.title = item.title.text
        self.subtitle = item.subtitle?.text
        self.searchText = item.searchText
        self.displayText = item.displayText
        self.isPersonal = item.isPersonal
        self.isWordItem = item.isWordItem

        self.distance = item.distance != nil ? JsonDistance(distance: item.distance!) : nil

        self.action = item.action == YMKSuggestItemAction.search ? "search" : "substitute"
        
        self.tags = item.tags
    }
}

public class JsonCameraPositionChangedEvent: Codable {
    let position: JsonPosition
    let finished: Bool

    public required init(position: JsonPosition, finished: Bool) {
        self.position = position
        self.finished = finished
    }

    public required init(position: YMKCameraPosition, finished: Bool) {
        self.position = JsonPosition(position: position)
        self.finished = finished
    }
}

public class JsonCameraAnimation: Codable {
    let duration: Int // duration in miliseconds
    let smooth: Bool

    public required init(duration: Int, smooth: Bool) {
        self.duration = duration
        self.smooth = smooth
    }
}

public class JsonCameraMoveParameters: Codable {
    let position: JsonPosition
    let animation: JsonCameraAnimation?

    public required init(position: JsonPosition, animation: JsonCameraAnimation?) {
        self.position = position
        self.animation = animation
    }

    public func getAnimation() -> YMKAnimation? {
        if animation != nil {
            let type: YMKAnimationType = animation?.smooth ?? false ? YMKAnimationType.smooth : YMKAnimationType.linear
            let duration: Float = Float(animation?.duration ?? 1000) / Float(1000)

            return YMKAnimation(type: type, duration: duration)
        }

        return nil
    }
}
