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
    static var channel: FlutterMethodChannel!
    static var controller: YandexMapController!
    static var searchController: SearchController!

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "yandex_mapkit", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(SwiftYandexMapkitPlugin(), channel: channel)
        registrar.register(
                YandexMapFactory(registrar: registrar),
                withId: "yandex_mapkit/yandex_map"
        )

        searchController = SearchController(registrar: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setApiKey":
            setApiKey(call)
            result(nil)
        case "search#withPoint":
            result(SwiftYandexMapkitPlugin.searchController.searchWithPoint(call))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setApiKey(_ call: FlutterMethodCall) {
        YMKMapKit.setApiKey(call.arguments as! String?)
    }

    internal class SearchController {
        private let registrar: FlutterPluginRegistrar
        private let searchManager: YMKSearchManager

        public required init(registrar: FlutterPluginRegistrar) {
            self.registrar = registrar
            self.searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
        }

        public func searchWithPoint(_ call: FlutterMethodCall) -> String {
            let parameters: JsonSubmitWithPointParameters = try! call.fromJson(JsonSubmitWithPointParameters.self)

            let session = SearchSessionController(
                    registrar: registrar,
                    searchManager: searchManager
            )

            session.submit(
                    with: parameters.point.toPoint(),
                    zoom: NSNumber(value: parameters.zoom!),
                    searchOptions: parameters.getSearchOptions()
            )

            return session.sessionId.uuidString
        }

        internal class SearchSessionController {
            let sessionId: UUID
            let registrar: FlutterPluginRegistrar
            let searchManager: YMKSearchManager
            let sessionChannel: FlutterMethodChannel
            var searchSession: YMKSearchSession?

            init(registrar: FlutterPluginRegistrar, searchManager: YMKSearchManager) {
                self.registrar = registrar
                self.searchManager = searchManager
                self.sessionId = UUID()
                self.sessionChannel = FlutterMethodChannel(
                        name: "yandex_mapkit_search_\(sessionId)",
                        binaryMessenger: registrar.messenger()
                )
                self.sessionChannel.setMethodCallHandler(self.handle)
            }

            public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
                switch call.method {
                case "cancel":
                    self.cancel()
                    result(nil)
                case "dispose":
                    self.dispose()
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }

            public func submit(with: YMKPoint, zoom: NSNumber?, searchOptions: YMKSearchOptions) -> Void {
                searchSession = searchManager.submit(
                        with: with,
                        zoom: zoom,
                        searchOptions: searchOptions,
                        responseHandler: self.responseHandler
                )
            }

            public func cancel() {
                searchSession?.cancel()
            }

            public func dispose() {
                // TODO ???
            }

            private func reportError(error: Error) -> Void {
                sessionChannel.invokeMethod(
                        "failure",
                        arguments: [
                            "uuid": sessionId.uuidString,
                            "description": error.localizedDescription
                        ]
                )
            }

            private func responseHandler(response: YMKSearchResponse?, error: Error?) -> Void {
                if error != nil {
                    self.reportError(error: error!)
                }

                do {
                    let response = JsonSearchResponse(response: response!)
                    let data = try String(data: JSONEncoder().encode(response), encoding: .utf8)
                    sessionChannel.invokeMethod("success", arguments: data)
                } catch {
                    self.reportError(error: error)
                }
            }
        }
    }
}
