import CoreLocation
import Flutter
import UIKit
import YandexMapKit

struct Point: Codable {
    let latitude: Double
    let longitude: Double
}

struct Position: Codable {
    let azimuth: Float
    let target: Point
    let tilt: Float
    let zoom: Float
}

struct Polygon: Codable {
    let points: [Point]
    let fillColor: Int
    let strokeColor: Int
    let strokeWidth: Float
    let zIndex: Float
}

struct PositionChangedEvent: Codable {
    let position: Position
    let finished: Bool
}

struct CameraAnimation: Codable {
    let smooth: Bool
    let duration: Int
}

struct CameraMoveParameters: Codable {
    let position: Position
    let animation: CameraAnimation?
}

extension YMKCameraPosition {
    static func fromPosition(_ position: Position) -> YMKCameraPosition {
        return YMKCameraPosition(
                target: YMKPoint.fromPoint(position.target),
                zoom: position.zoom,
                azimuth: position.azimuth,
                tilt: position.tilt
        )
    }
}

extension YMKPoint {
    func toPoint() -> Point {
        return Point(latitude: self.latitude, longitude: self.longitude);
    }

    static func fromPoint(_ point: Point) -> YMKPoint {
        return YMKPoint(latitude: point.latitude, longitude: point.longitude)
    }
}

extension FlutterMethodCall {
    func fromJson<T>(_ type: T.Type) throws -> T where T: Decodable {
        let jsonString = self.arguments as! String;
        return try! JSONDecoder().decode(type, from: jsonString.data(using: .utf8)!)
    }
}

extension UIColor {
    static func fromInteger(_ intValue: Int) -> UIColor {
        let alpha = CGFloat((intValue & 0xFF000000) >> 24) / 255.0
        let red = CGFloat((intValue & 0x00FF0000) >> 16) / 255.0
        let green = CGFloat((intValue & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(intValue & 0x000000FF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public class YandexMapController: NSObject, FlutterPlatformView {
    private let methodChannel: FlutterMethodChannel!
    private let cameraPositionListener: CameraListener!
    public let mapView: YMKMapView

    public required init(id: Int64, frame: CGRect, registrar: FlutterPluginRegistrar) {
        self.mapView = YMKMapView(frame: frame)
        self.methodChannel = FlutterMethodChannel(
                name: "yandex_mapkit/yandex_map_\(id)",
                binaryMessenger: registrar.messenger()
        )
        self.cameraPositionListener = CameraListener(channel: methodChannel)
        super.init()
        self.mapView.mapWindow.map.addCameraListener(with: self.cameraPositionListener)
        self.methodChannel.setMethodCallHandler(self.handle)
    }

    public func view() -> UIView {
        return self.mapView
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "move":
            move(call)
            result(nil)
        case "addPolygon":
            addPolygon(call)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func move(_ call: FlutterMethodCall) {
        let params: CameraMoveParameters = try! call.fromJson(CameraMoveParameters.self)
        let position = YMKCameraPosition.fromPosition(params.position)

        if (params.animation != nil) {
            let type = params.animation?.smooth ?? false ? YMKAnimationType.smooth : YMKAnimationType.linear
            let animationType = YMKAnimation(type: type, duration: Float(params.animation?.duration ?? 0) / Float(1000))

            mapView.mapWindow.map.move(with: position, animationType: animationType)
        } else {
            mapView.mapWindow.map.move(with: position)
        }
    }

    private func addPolygon(_ call: FlutterMethodCall) {
        let polygon: Polygon = try! call.fromJson(Polygon.self)

        var points = [YMKPoint]()

        for point in polygon.points {
            points.append(YMKPoint.fromPoint(point))
        }

        let mapObjects = mapView.mapWindow.map.mapObjects
        let mapObject = mapObjects.addPolygon(with: YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: []))

        mapObject.fillColor = UIColor.fromInteger(polygon.fillColor)
        mapObject.strokeColor = UIColor.fromInteger(polygon.strokeColor)
        mapObject.strokeWidth = polygon.strokeWidth
        mapObject.zIndex = polygon.zIndex
    }

    internal class CameraListener: NSObject, YMKMapCameraListener {
        private let methodChannel: FlutterMethodChannel!

        public required init(channel: FlutterMethodChannel) {
            self.methodChannel = channel
        }

        func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateSource: YMKCameraUpdateSource, finished: Bool) -> Void {
            let target = Point(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude)
            let position = Position(azimuth: cameraPosition.azimuth, target: target, tilt: cameraPosition.tilt, zoom: cameraPosition.zoom)
            let event = PositionChangedEvent(position: position, finished: finished)

            let encoder = JSONEncoder()
            let data = try! encoder.encode(event)
            let arguments = String(data: data, encoding: .utf8)

            methodChannel.invokeMethod("onCameraPositionChanged", arguments: arguments)
        }
    }
}
