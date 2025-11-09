import Flutter
import UIKit

public class SPAvatarKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // 注册平台视图工厂
        let factory = CharacterPlatformViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "sp_character_view")
        
        // 注册MethodChannel
        let channel = FlutterMethodChannel(name: "spavatar_kit_plugin/character_view", binaryMessenger: registrar.messenger())
        let instance = SPAvatarKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 处理全局的MethodChannel调用
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
