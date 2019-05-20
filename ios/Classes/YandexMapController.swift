import CoreLocation
import Flutter
import UIKit
import YandexMapKit

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
        let params: JsonCameraMoveParameters = try! call.fromJson(JsonCameraMoveParameters.self)
        let position = params.position.toCameraPosition()
        let animation = params.getAnimation()

        if (animation != nil) {
            mapView.mapWindow.map.move(with: position, animationType: animation ?? YMKAnimation())
        } else {
            mapView.mapWindow.map.move(with: position)
        }
    }

    private func addPolygon(_ call: FlutterMethodCall) {
        let polygon: JsonPolygon = try! call.fromJson(JsonPolygon.self)

        let mapObjects = mapView.mapWindow.map.mapObjects
        let mapObject = mapObjects.addPolygon(with: polygon.getPolygon())

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
            let data = try! JSONEncoder().encode(JsonCameraPositionChangedEvent(position: cameraPosition, finished: finished))
            let arguments = String(data: data, encoding: .utf8)

            methodChannel.invokeMethod("onCameraPositionChanged", arguments: arguments)
        }
    }
}
