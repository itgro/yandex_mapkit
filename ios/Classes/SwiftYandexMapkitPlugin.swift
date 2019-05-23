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
    static var registrar: FlutterPluginRegistrar!
    static var controller: YandexMapController!

    var searchManagers: [String: DisposableSearchManager] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "yandex_mapkit", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(SwiftYandexMapkitPlugin(), channel: channel)
        registrar.register(
                YandexMapFactory(registrar: registrar),
                withId: "yandex_mapkit/yandex_map"
        )
        self.registrar = registrar
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setApiKey":
            setApiKey(call)
            result(nil)
            break;
        case "createSearchManager":
            let manager = DisposableSearchManager(call);

            searchManagers[manager.uuid.uuidString] = manager

            result(manager.uuid.uuidString)
            break;
        case "disposeSearchManager":
            searchManagers.removeValue(forKey: call.arguments as! String)

            result(nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setApiKey(_ call: FlutterMethodCall) {
        YMKMapKit.setApiKey(call.arguments as! String?)
    }

    internal class DisposableSearchManager {
        let uuid: UUID
        let searchManager: YMKSearchManager
        let methodChannel: FlutterMethodChannel

        var sessions: [String: YMKSearchSession] = [:]
        var sessionCounter: Int = 0

        init(_ call: FlutterMethodCall) {
            let arguments: [String: String] = call.arguments as! [String: String]

            self.uuid = UUID()

            var type: YMKSearchSearchManagerType = .default

            let stringType: String? = arguments["type"]

            if (stringType != nil) {
                switch stringType {
                case "combined":
                    type = .combined
                    break;
                case "online":
                    type = .online
                    break;
                case "offline":
                    type = .offline
                    break;
                default:
                    type = .default
                    break;
                }
            }

            searchManager = YMKSearch.sharedInstance().createSearchManager(with: type)

            methodChannel = FlutterMethodChannel(
                    name: "yandex_mapkit/search_manager_\(self.uuid.uuidString)",
                    binaryMessenger: registrar.messenger()
            )

            methodChannel.setMethodCallHandler(self.handle)
        }

        public func submitWithPoint(_ call: FlutterMethodCall) throws -> String {
            let arguments: [String: Any] = call.arguments as! [String: Any]

            let latitude: Double = arguments["latitude"] as! Double
            let longitude: Double = arguments["longitude"] as! Double

            if latitude == 0 || longitude == 0 {
                throw NSError()
            }

            var zoom: Int = arguments["zoom"] as! Int

            if zoom == 0 {
                zoom = 17
            }

            let point = YMKPoint(latitude: latitude, longitude: longitude)

            sessionCounter += 1
            let sessionId: String = String(sessionCounter)

            let container: SessionContainer = SessionContainer(
                    sessionId: sessionId,
                    channel: methodChannel
            )

            let session: YMKSearchSession = searchManager.submit(
                    with: point,
                    zoom: NSNumber(value: zoom),
                    searchOptions: options(call),
                    responseHandler: container.responseHandler
            )

            sessions[sessionId] = session

            return String(sessionCounter)
        }

        private func options(_ call: FlutterMethodCall) -> YMKSearchOptions {
            let arguments: [String: Any] = call.arguments as! [String: Any]
            let types: [String] = arguments["types"] as! [String]
            let options: YMKSearchOptions = YMKSearchOptions()

            var searchTypes = YMKSearchType()

            for type in types {
                switch type {
                case "geo":
                    searchTypes.insert(YMKSearchType.geo)
                    break;
                case "biz":
                    searchTypes.insert(YMKSearchType.biz)
                    break;
                case "transit":
                    searchTypes.insert(YMKSearchType.transit)
                    break;
                case "collections":
                    searchTypes.insert(YMKSearchType.collections)
                    break;
                case "direct":
                    searchTypes.insert(YMKSearchType.direct)
                    break;
                default:
                    break;
                }
            }

            options.searchTypes = searchTypes

            return options
        }

        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "submitWithPoint":
                do {
                    try result(submitWithPoint(call))
                } catch {
                    result(FlutterError())
                }
                break;
            case "cancel":
                let session: YMKSearchSession? = sessions[call.arguments as! String]

                if session != nil {
                    session!.cancel()
                }
                result(nil)
                break;
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    internal class SessionContainer {
        let sessionId: String
        let sessionMethodChannel: FlutterMethodChannel

        init(sessionId: String, channel: FlutterMethodChannel) {
            self.sessionId = sessionId
            self.sessionMethodChannel = channel
        }

        public func responseHandler(response: YMKSearchResponse?, error: Error?) -> Void {
            if (error != nil) {
                sendToDart(response: JsonSearchResponse(sessionId: sessionId, error: error!))
            } else {
                sendToDart(response: JsonSearchResponse(sessionId: sessionId, response: response!))
            }
        }

        private func sendToDart(response: JsonSearchResponse) {
            let data = try! JSONEncoder().encode(response)
            let arguments = String(data: data, encoding: .utf8)

            sessionMethodChannel.invokeMethod("searchResponse", arguments: arguments)
        }
    }
}
