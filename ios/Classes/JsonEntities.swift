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

public class JsonPolygon: Codable {
    let points: [JsonPoint]
    let fillColor: Int
    let strokeColor: Int
    let strokeWidth: Float
    let zIndex: Float

    public required init(points: [JsonPoint], fillColor: Int, strokeColor: Int, strokeWidth: Float, zIndex: Float) {
        self.points = points
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.zIndex = zIndex
    }

    public func getPolygon() -> YMKPolygon {
        var polygonPoints = [YMKPoint]()

        for point in points {
            polygonPoints.append(point.toPoint())
        }

        return YMKPolygon(outerRing: YMKLinearRing(points: polygonPoints), innerRings: [])
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

public class JsonAddressComponent: Codable {
    let name: String
    let kinds: [String]

    public init(component: YMKSearchAddressComponent) {
        self.name = component.name

        var kinds = [String]()

        for kind in component.kinds {
            switch kind.uintValue {
            case YMKSearchComponentKind.country.rawValue:
                kinds.append("country")
                break;
            case YMKSearchComponentKind.region.rawValue:
                kinds.append("region")
                break;
            case YMKSearchComponentKind.province.rawValue:
                kinds.append("province")
                break;
            case YMKSearchComponentKind.area.rawValue:
                kinds.append("area")
                break;
            case YMKSearchComponentKind.locality.rawValue:
                kinds.append("locality")
                break;
            case YMKSearchComponentKind.district.rawValue:
                kinds.append("district")
                break;
            case YMKSearchComponentKind.street.rawValue:
                kinds.append("street")
                break;
            case YMKSearchComponentKind.house.rawValue:
                kinds.append("house")
                break;
            case YMKSearchComponentKind.entrance.rawValue:
                kinds.append("entrance")
                break;
            case YMKSearchComponentKind.route.rawValue:
                kinds.append("route")
                break;
            case YMKSearchComponentKind.station.rawValue:
                kinds.append("station")
                break;
            case YMKSearchComponentKind.metroStation.rawValue:
                kinds.append("metro_station")
                break;
            case YMKSearchComponentKind.railwayStation.rawValue:
                kinds.append("railway_station")
                break;
            case YMKSearchComponentKind.vegetation.rawValue:
                kinds.append("vegetation")
                break;
            case YMKSearchComponentKind.hydro.rawValue:
                kinds.append("hydro")
                break;
            case YMKSearchComponentKind.airport.rawValue:
                kinds.append("airport")
                break;
            case YMKSearchComponentKind.other.rawValue:
                kinds.append("other")
                break;
            default:
                kinds.append("unknown")
                break;
            }
        }

        self.kinds = kinds
    }
}

public class JsonAddress: Codable {
    let formattedAddress: String?
    let additionalInfo: String?
    let postalCode: String?
    let countryCode: String?
    let components: [JsonAddressComponent]

    public init(address: YMKSearchAddress) {
        self.formattedAddress = address.formattedAddress
        self.additionalInfo = address.additionalInfo
        self.postalCode = address.postalCode
        self.countryCode = address.countryCode

        var components = [JsonAddressComponent]()

        for component in address.components {
            components.append(JsonAddressComponent(component: component))
        }

        self.components = components
    }
}

public class JsonToponymData: Codable {
    let id: String
    let precision: String
    let formerName: String?
    let balloonPoint: JsonPoint
    let address: JsonAddress

    public init(metadata: YMKSearchToponymObjectMetadata) {
        self.id = metadata.id!
        self.formerName = metadata.formerName
        self.balloonPoint = JsonPoint(point: metadata.balloonPoint)

        self.address = JsonAddress(address: metadata.address)

        if metadata.precision != nil {
            switch (metadata.precision!.uintValue) {
            case YMKSearchPrecision.exact.rawValue:
                self.precision = "exact"
                break;
            case YMKSearchPrecision.number.rawValue:
                self.precision = "number"
                break;
            case YMKSearchPrecision.range.rawValue:
                self.precision = "range"
                break;
            case YMKSearchPrecision.nearby.rawValue:
                self.precision = "nearby"
                break;
            default:
                self.precision = "unknown"
                break;
            }
        } else {
            self.precision = "unknown"
        }
    }
}

public class JsonSearchResultItem: Codable {
    let name: String?
    let description: String?
    let toponym: JsonToponymData?

    public init(obj: YMKGeoObject) {
        self.name = obj.name
        self.description = obj.descriptionText

        let toponym: YMKSearchToponymObjectMetadata? =
                obj.metadataContainer.getItemOf(YMKSearchToponymObjectMetadata.self) as? YMKSearchToponymObjectMetadata

        if toponym != nil {
            self.toponym = JsonToponymData(metadata: toponym!)
        } else {
            self.toponym = nil
        }
    }
}

public class JsonSearchResponse: Codable {
    let sessionId: String
    let isSuccess: Bool
    let items: [JsonSearchResultItem]

    public init(sessionId: String, response: YMKSearchResponse) {
        var items = [JsonSearchResultItem]()

        for item in response.collection.children {
            items.append(JsonSearchResultItem(obj: item.obj))
        }

        self.items = items
        self.sessionId = sessionId
        self.isSuccess = true
    }

    public init(sessionId: String, error: Error) {
        self.items = [JsonSearchResultItem]()
        self.sessionId = sessionId
        self.isSuccess = false
    }
}
