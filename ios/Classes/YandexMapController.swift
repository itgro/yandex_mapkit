import CoreLocation
import Flutter
import UIKit
import YandexMapKit

public class YandexMapController: NSObject, FlutterPlatformView {
  private let methodChannel: FlutterMethodChannel!
  private let pluginRegistrar: FlutterPluginRegistrar!
  private let cameraPositionListener: CameraListener!
  private var placemarks: [YMKPlacemarkMapObject] = []
  public let mapView: YMKMapView

  public required init(id: Int64, frame: CGRect, registrar: FlutterPluginRegistrar) {
    self.pluginRegistrar = registrar
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

  public func move(_ call: FlutterMethodCall) {
    struct Params:Codable {
        let point: Point
        let zoom: Float
        let azimuth: Float
        let tilt: Float
        let animate: Bool
        let smoothAnimation: Bool
        let animationDuration: Float
    }
    
    let jsonString = call.arguments as! String
    let params = try! JSONDecoder().decode(Params.self, from: jsonString.data(using: .utf8)!)
    
    let point = YMKPoint(latitude: params.point.latitude, longitude: params.point.longitude)
    
    let cameraPosition = YMKCameraPosition(
      target: point,
      zoom: params.zoom,
      azimuth: params.azimuth,
      tilt: params.tilt
    )
    
    if (params.animate) {
        let type = params.smoothAnimation ? YMKAnimationType.smooth : YMKAnimationType.linear
        let animationType = YMKAnimation(type: type, duration: params.animationDuration)
        
        mapView.mapWindow.map.move(with: cameraPosition, animationType: animationType)
    } else {
        mapView.mapWindow.map.move(with: cameraPosition)
    }
  }

  struct Point:Codable{
    let latitude: Double
    let longitude: Double
  }
  
    private func int2color(intValue: Int) -> UIColor {
        let alpha =   CGFloat((intValue & 0xFF000000) >> 24) / 255.0
        let red = CGFloat((intValue & 0x00FF0000) >> 16) / 255.0
        let green =  CGFloat((intValue & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(intValue & 0x000000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
  private func addPolygon(_ call: FlutterMethodCall) {
    struct Polygon:Codable{
        let points: [Point]
        let fillColor: Int
        let strokeColor: Int
        let strokeWidth: Float
        let zIndex: Float
    }
    
    let jsonString = call.arguments as! String
    let polyline = try! JSONDecoder().decode(Polygon.self, from: jsonString.data(using: .utf8)!)
    
    var points = [YMKPoint]()
    
    for point in polyline.points {
        points.append(YMKPoint(latitude: point.latitude, longitude: point.longitude))
    }
    
    let mapObjects = mapView.mapWindow.map.mapObjects
    let mapObject = mapObjects.addPolygon(with: YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: []))
    
    mapObject.fillColor = int2color(intValue: polyline.fillColor)
    mapObject.strokeColor = int2color(intValue: polyline.strokeColor)
    mapObject.strokeWidth = polyline.strokeWidth
    mapObject.zIndex = polyline.zIndex
  }

    internal class CameraListener: NSObject, YMKMapCameraListener {
        private let methodChannel: FlutterMethodChannel!
        
        struct CameraPosition:Codable{
            let azimuth: Float
            let target: Point
            let tilt: Float
            let zoom: Float
        }
        
        struct PositionChangedEvent:Codable{
            let position: CameraPosition
            let finished: Bool
        }
        
        public required init(channel: FlutterMethodChannel) {
            self.methodChannel = channel
        }
        
        func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateSource: YMKCameraUpdateSource, finished: Bool) -> Void {
            let target = Point(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude)
            let position = CameraPosition(azimuth: cameraPosition.azimuth, target: target, tilt: cameraPosition.tilt, zoom: cameraPosition.zoom)
            let event = PositionChangedEvent(position: position, finished: finished)
            
            let encoder = JSONEncoder()
            let data = try! encoder.encode(event)
            let arguments = String(data: data, encoding: .utf8)
            
            methodChannel.invokeMethod("onCameraPositionChanged", arguments: arguments)
        }
    }
}
