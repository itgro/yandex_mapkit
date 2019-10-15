import CoreLocation
import Flutter
import UIKit
import YandexMapKit

public class YandexMapMarkerController: NSObject, YMKMapObjectTapListener, YMKMapObjectDragListener {
    public let id: String
    private let controller: YandexMapController
    
    private var mapObject: YMKPlacemarkMapObject
    
    public required init(point: YMKPoint, controller: YandexMapController) {
        self.id = UUID().uuidString

        self.controller = controller
        
        mapObject = controller.mapView.mapWindow.map.mapObjects.addPlacemark(with: point)
        
        super.init()
        
        mapObject.addTapListener(with: self)
        mapObject.setDragListenerWith(self)
        
        controller.idToController[id] = self
    }
    
    public func setIcon(icon: UIImage) {
        mapObject.setIconWith(icon)
    }
    
    public func setIcon(data: [String]) {
        let image: UIImage? = UIImage.fromFlutter(registrar: controller.registrar, data: data)
        
        if (image != nil) {
            setIcon(icon: image!)
        }
    }
    
    public func setOpacity(opacity: Float) {
        mapObject.opacity = opacity
    }
    
    public func setZIndex(zIndex: Float) {
        mapObject.zIndex = zIndex
    }
    
    public func setDraggable(draggable: Bool) {
        mapObject.isDraggable = draggable
    }
    
    public func setVisible(visible: Bool) {
        mapObject.isVisible = visible
    }
    
    public func remove() {
        controller.mapView.mapWindow.map.mapObjects.remove(with: mapObject)
        controller.idToController.removeValue(forKey: id)
    }
    
    public func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
       let data = try! JSONEncoder().encode(JsonMapObjectEventWithPoint(id: id, point: JsonPoint(point: point)))
       let arguments = String(data: data, encoding: .utf8)
       
       controller.methodChannel.invokeMethod("onMapObjectTap", arguments: arguments)
        
        return true
    }
    
    public func onMapObjectDrag(with mapObject: YMKMapObject, point: YMKPoint) {
        let data = try! JSONEncoder().encode(JsonMapObjectEventWithPoint(id: id, point: JsonPoint(point: point)))
        let arguments = String(data: data, encoding: .utf8)
        
        controller.methodChannel.invokeMethod("onMapObjectDrag", arguments: arguments)
    }
    
    public func onMapObjectDragEnd(with mapObject: YMKMapObject) {
        controller.methodChannel.invokeMethod("onMapObjectDragEnd", arguments: id)
    }
    
    public func onMapObjectDragStart(with mapObject: YMKMapObject) {
        controller.methodChannel.invokeMethod("onMapObjectDragStart", arguments: id)
    }
}

public class YandexMapUserLayerController: NSObject, YMKUserLocationObjectListener {
    private let controller: YandexMapController
    private let image: UIImage
    
    public required init(controller: YandexMapController, image: UIImage) {
        self.controller = controller
        self.image = image
        
        let scale = UIScreen.main.scale
        let userLocationLayer = controller.mapView.mapWindow.map.userLocationLayer
        userLocationLayer.isEnabled = true
        userLocationLayer.isHeadingEnabled = true
            // userLocationLayer.setAnchorWithAnchorNormal(
            //CGPoint(x: 0.5 * controller.mapView.frame.size.width * scale, y: 0.5 * controller.mapView.frame.size.height * scale),
            //anchorCourse: CGPoint(x: 0.5 * controller.mapView.frame.size.width * scale, y: 0.83 * controller.mapView.frame.size.height * scale))
        
        super.init()
        
        userLocationLayer.setObjectListenerWith(self)
    }
    
    public func onObjectAdded(with view: YMKUserLocationView) {
        view.pin.setIconWith(image)
        view.accuracyCircle.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    public func onObjectRemoved(with view: YMKUserLocationView) {}

    public func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}

public class YandexMapController: NSObject, FlutterPlatformView {
    public let methodChannel: FlutterMethodChannel!
    public let mapView: YMKMapView
    public let registrar: FlutterPluginRegistrar!
    
    private let cameraPositionListener: CameraListener!
    
    public var idToController : [String: YandexMapMarkerController]
    
    private var userLocationController: YandexMapUserLayerController?

    public required init(id: Int64, frame: CGRect, registrar: FlutterPluginRegistrar) {
        self.mapView = YMKMapView(frame: frame)
        self.methodChannel = FlutterMethodChannel(
                name: "yandex_mapkit/yandex_map_\(id)",
                binaryMessenger: registrar.messenger()
        )
        self.cameraPositionListener = CameraListener(channel: methodChannel)
        self.registrar = registrar
        
        idToController = [String: YandexMapMarkerController]()
        
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
            break;
            
        case "showUserLocation":
            if (userLocationController == nil) {
                let image: UIImage? = UIImage.fromFlutter(registrar: registrar, data: call.arguments as! [String])
                
                if (image != nil) {
                    userLocationController = YandexMapUserLayerController(controller: self, image: image!)
                }
            }
            
            break;
            
        case "polygon#add":
            addPolygon(call)
            result(nil)
            break;
        case "marker#init":
            result(addMarker(call))
            break;
        case "marker#update":
            updateMarker(call.arguments as! [String: Any])
            result(nil)
            break;
        case "marker#remove":
            let id = call.arguments as! String
            idToController[id]?.remove()
            result(nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
            break;
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

     private func addMarker(_ call: FlutterMethodCall) -> String {
        let arguments = call.arguments as! [String: Any]
        
        let jsonString = arguments["point"] as! String;
        let point: JsonPoint = try! JSONDecoder().decode(JsonPoint.self, from: jsonString.data(using: .utf8)!)
    
        let markerController = YandexMapMarkerController(point: point.toPoint(), controller: self)
        
        updateMarkerWithController(markerController, arguments)
        
        return markerController.id
    }
    
    private func updateMarker(_ arguments: [String: Any]) {
        let id = arguments["id"] as! String
        
        let markerController = idToController[id]
        
        if (markerController != nil) {
            updateMarkerWithController(markerController!, arguments)
        }
    }
    
    private func updateMarkerWithController(_ markerController: YandexMapMarkerController, _ arguments: [String: Any]) {
        let icon = arguments["icon"] as! [String]?
        let visible = arguments["visible"] as! Bool?
        let draggable = arguments["draggable"] as! Bool?
        let zIndex = arguments["zIndex"] as! Float?
        let opacity = arguments["opacity"] as! Float?
                
        if (icon != nil) {
            markerController.setIcon(data: icon!)
        }
        
        if (visible != nil) {
            markerController.setVisible(visible: visible!)
        }
        
        if (draggable != nil) {
            markerController.setDraggable(draggable: draggable!)
        }
        
        if (zIndex != nil) {
            markerController.setZIndex(zIndex: zIndex!)
        }
        
        if (opacity != nil) {
            markerController.setOpacity(opacity: opacity!)
        }
    }
    
    private func removeMarker(_ call: FlutterMethodCall) {
        let markerId = call.arguments as! String;
        
        let objectController = idToController[markerId]
        
        if (objectController != nil) {
            objectController?.remove()
        }
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
