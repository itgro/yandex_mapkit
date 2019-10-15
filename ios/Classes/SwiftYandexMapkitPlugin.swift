import Flutter
import UIKit
import YandexMapKit
import YandexMapKitSearch

extension FlutterMethodCall {
    func fromJson<T>(_ type: T.Type) throws -> T where T: Decodable {
        let jsonString = self.arguments as! String;
        return try! JSONDecoder().decode(type, from: jsonString.data(using: .utf8)!)
    }
}

extension UIColor {
    static func fromInteger(_ intValue: Int) -> UIColor {
        let intAlpha = (UInt(intValue) & UInt(0xFF000000)) >> 24;
        let intRed   = (intValue & 0x00FF0000) >> 16;
        let intGreen = (intValue & 0x0000FF00) >> 8;
        let intBlue  = (intValue & 0x000000FF);
        
        let alpha = CGFloat(intAlpha) / 255.0
        let red   = CGFloat(intRed)   / 255.0
        let green = CGFloat(intGreen) / 255.0
        let blue  = CGFloat(intBlue)  / 255.0
        
        return UIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

extension UIImage {
    private func scale(scale: Float) -> UIImage {
        if (fabs(scale - 1) > 1e-3) {
            return UIImage(
                cgImage: cgImage!,
                scale: self.scale * CGFloat(scale),
                orientation: imageOrientation
            )
        }
        
        return self
    }
    
    private func resize(targetSize: CGSize) -> UIImage {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    public static func fromFlutter(registrar: FlutterPluginRegistrar, data: [String]) -> UIImage? {
        var image: UIImage?
        
        if (!data.isEmpty) {
           if (data[0] == "defaultMarker") {
                // TODO default marker implementation
            } else if (data[0] == "fromAsset") {
                if (data.count == 2) {
                    image = UIImage(named: registrar.lookupKey(forAsset: data[1]))
                } else {
                    image = UIImage(named: registrar.lookupKey(forAsset: data[1], fromPackage: data[2]))
                }
            } else if (data[0] == "fromAssetImage") {
                image = UIImage(named: registrar.lookupKey(forAsset: data[1]))
            
                if (image != nil) {
                    if (data.count == 3) {
                       let scaleParam: Float = Float(data[2])!
                       
                        image = image!.scale(scale: scaleParam)
                   } else if (data.count == 4) {
                       let width: Float = Float(data[2])!
                       let height: Float = Float(data[3])!
                       
                        image = image!.resize(
                            targetSize: CGSize(
                                width: CGFloat(width) * UIScreen.main.scale,
                                height: CGFloat(height) * UIScreen.main.scale
                            )
                        )
                   } else {
                       // TODO Error
                   }
                }
            
               
            } else if (data[0] == "fromBytes") {
                // TODO from bytes implementation
            }
        }
        
        return image
    }
}

public class SwiftYandexMapkitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    static var sharedInstance: SwiftYandexMapkitPlugin?

    let channel: FlutterMethodChannel!
    let registrar: FlutterPluginRegistrar!

    let suggestChannel: FlutterEventChannel

    var controller: YandexMapController?
    var manager: YMKSearchManager?

    var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yandex_mapkit", binaryMessenger: registrar.messenger())

        self.sharedInstance = SwiftYandexMapkitPlugin(channel: channel, registrar: registrar);

        registrar.addMethodCallDelegate(self.sharedInstance!, channel: channel)

        registrar.register(
                YandexMapFactory(registrar: registrar),
                withId: "yandex_mapkit/yandex_map"
        )
    }

    public init(channel: FlutterMethodChannel!, registrar: FlutterPluginRegistrar!) {
        self.channel = channel
        self.registrar = registrar
        self.suggestChannel = FlutterEventChannel(
                name: "yandex_mapkit_suggest_result",
                binaryMessenger: registrar.messenger()
        )
        super.init()

        self.suggestChannel.setStreamHandler(self)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    private func getSearchManager() -> YMKSearchManager {
        if self.manager == nil {
            self.manager = YMKSearch.sharedInstance().createSearchManager(with: .online)
        }
        
        return self.manager!
    }
    
    private func suggestResponseHandler(items: [YMKSuggestItem]?, error: Error?) {
        DispatchQueue.main.async {
            if self.eventSink != nil {
                let data = try! JSONEncoder().encode(JsonSuggestResult(items: items, error: error))
                self.eventSink!(String(data: data, encoding: .utf8))
            }
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setApiKey":
            setApiKey(call)
            result(nil)
            break;
        case "cancelSuggest":
            self.manager?.cancelSuggest()
            result(nil)
            break;
        case "suggest":
            let params: SuggestArguments = try! call.fromJson(SuggestArguments.self)
            let options: YMKSearchOptions = YMKSearchOptions()

            if params.type == "biz" {
                options.searchTypes = YMKSearchType.biz
            } else if params.type == "geo" {
                options.searchTypes = YMKSearchType.geo
            }

            DispatchQueue.main.async {
                self.getSearchManager().suggest(
                    withText: params.text,
                    window: params.window.toBoundingBox(),
                    searchOptions: options,
                    responseHandler: self.suggestResponseHandler
                )
            }

            result(nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    internal class SuggestArguments: Decodable {
        let text: String
        let type: String
        let window: JsonBoundingBox
    }

    private func setApiKey(_ call: FlutterMethodCall) {
        YMKMapKit.setApiKey(call.arguments as! String?)
    }
}
