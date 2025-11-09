import Flutter
import UIKit
import SPAvatarKit

public class SpCharacterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sp_character_plugin", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SpCharacterPlugin(), channel: channel)
        
        let viewFactory = CharacterPlatformViewFactory(messenger: registrar.messenger())
        registrar.register(viewFactory, withId: "sp_character_view")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "supportsCurrentDevice":
            result(SPAvatarSDK.shared.supportsCurrentDevice())
        case "setUpEnvironment":
            if let environment = call.arguments as? String, let environment = SPAvatarSDK.Environment(rawValue: environment) {
                SPAvatarSDK.shared.setUpEnvironment(environment)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Failed to set up environment", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
