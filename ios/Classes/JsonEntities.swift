import YandexMapKit

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
        if (animation != nil) {
            let type: YMKAnimationType = animation?.smooth ?? false ? YMKAnimationType.smooth : YMKAnimationType.linear
            let duration: Float = Float(animation?.duration ?? 1000) / Float(1000)

            return YMKAnimation(type: type, duration: duration)
        }

        return nil
    }
}
