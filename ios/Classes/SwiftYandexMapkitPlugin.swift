import Flutter
import UIKit
import YandexMapKit
import YandexMapKitSearch

public class SwiftYandexMapkitPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel!
    static var controller: YandexMapController!
    static var pluginRegistrar: FlutterPluginRegistrar!

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "yandex_mapkit", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(SwiftYandexMapkitPlugin(), channel: channel)
        registrar.register(
                YandexMapFactory(registrar: registrar),
                withId: "yandex_mapkit/yandex_map"
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setApiKey":
            setApiKey(call)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setApiKey(_ call: FlutterMethodCall) {
        YMKMapKit.setApiKey(call.arguments as! String?)
    }

    internal class YandexGeocoder: NSObject {
        private let channel: FlutterMethodChannel
        private let searchManager: YMKSearchManager

        public required init(registrar: FlutterPluginRegistrar) {
            channel = FlutterMethodChannel(name: "yandex_mapkit_search", binaryMessenger: registrar.messenger())
            searchManager = YMKSearchManager()
            super.init()
            channel.setMethodCallHandler(self.handle)
        }

        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "withPoint":
                _withPoint(call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        public func _withPoint(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            //searchManager.submit(with: , zoom: <#T##NSNumber?##Foundation.NSNumber?#>, searchOptions: <#T##YMKSearchOptions##YandexMapKitSearch.YMKSearchOptions#>, responseHandler: <#T##@escaping YMKSearchSessionResponseHandler##@escaping YandexMapKitSearch.YMKSearchSessionResponseHandler#>)
        }
    }
}
