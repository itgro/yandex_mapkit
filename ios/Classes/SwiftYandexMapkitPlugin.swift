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
        if self.eventSink != nil {
            let data = try! JSONEncoder().encode(JsonSuggestResult(items: items, error: error))
            self.eventSink!(String(data: data, encoding: .utf8))
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

            self.getSearchManager().suggest(
                withText: params.text,
                window: params.window.toBoundingBox(),
                searchOptions: options,
                responseHandler: self.suggestResponseHandler
            )

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
