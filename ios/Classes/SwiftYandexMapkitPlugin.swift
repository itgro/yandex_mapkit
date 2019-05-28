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
        let alpha = CGFloat((intValue & 0xFF000000) >> 24) / 255.0
        let red = CGFloat((intValue & 0x00FF0000) >> 16) / 255.0
        let green = CGFloat((intValue & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(intValue & 0x000000FF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public class SwiftYandexMapkitPlugin: NSObject, FlutterPlugin {
    static var sharedInstance: SwiftYandexMapkitPlugin?

    let channel: FlutterMethodChannel!
    let registrar: FlutterPluginRegistrar!

    var controller: YandexMapController?

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
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setApiKey":
            setApiKey(call)
            result(nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setApiKey(_ call: FlutterMethodCall) {
        YMKMapKit.setApiKey(call.arguments as! String?)
    }
}
