import Flutter
import UIKit
import SPAvatarKit

class CharacterPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        var sessionToken = ""
        var customViewId: Int64 = viewId
        var channelName = ""
        
        if let args = args as? [String: Any] {
            if let viewIdParam = args["viewId"] as? Int64 {
                customViewId = viewIdParam
            }
            if let token = args["sessionToken"] as? String {
                sessionToken = token
            }
            if let channel = args["channelName"] as? String {
                channelName = channel
            }
        }
        
        return CharacterPlatformView(
            frame: frame,
            sessionToken: sessionToken,
            viewIdentifier: customViewId,
            channelName: channelName,
            messenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class CharacterPlatformView: NSObject, FlutterPlatformView, CharacterViewControllerDelegate {
    private var _characterView: UIView
    private var _characterVC: CharacterViewController
    private var channel: FlutterMethodChannel

    init(frame: CGRect, sessionToken: String, viewIdentifier viewId: Int64, channelName: String, messenger: FlutterBinaryMessenger) {
        _characterVC = CharacterViewController()
        _characterView = _characterVC.view
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        super.init()
        _characterVC.delegate = self
        _characterVC.view.frame = frame
        
        AvatarSDK.shared.setupIfNeeded(sessionToken: sessionToken)
        
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleFlutterCall(call, result: result)
        }
    }
    
    func view() -> UIView {
        return _characterView
    }
    
    func handleFlutterCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = PlatformMethod(rawValue: call.method) else {
            print("❌ CharacterPlatformView: 未知方法: \(call.method)")
            return result(FlutterMethodNotImplemented) 
        }
        switch method {
        case .loadCharacterData:
            if let dict = call.arguments as? [String: Any], let characterId = dict["characterId"] as? String {
                let isBackgroundOpaque = dict["isBackgroundOpaque"] as? Bool ?? true
                if let backgroundImage = dict["backgroundImage"] as? FlutterStandardTypedData {
                  Task {
                      let image = UIImage(data: backgroundImage.data)
                      await _characterVC.loadCharacter(characterId, backgroundImage: image, isBackgroundOpaque: isBackgroundOpaque)
                  }
                } else {
                  Task {
                    await _characterVC.loadCharacter(characterId, backgroundImage: nil, isBackgroundOpaque: isBackgroundOpaque)
                  }
                }
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_PATH", message: "Expected Map path", details: nil))
            }
        case .preloadCharacterData:
            if let characterId = call.arguments as? String {
                Task {
                    let success = await _characterVC.preloadCharacter(characterId)
                    result(success)
                }
                result(nil)
            }  else {
                result(FlutterError(code: "INVALID_PATH", message: "Expected String path", details: nil))
            }
        case .deleteCharacterAssets:
            if let characterId = call.arguments as? String {
                Task {
                     await _characterVC.deleteCharacterAssets(characterId)
                }
                result(nil)
            }  else {
                result(FlutterError(code: "INVALID_PATH", message: "Expected String path", details: nil))
            }
        case .deleteAllCharacterAssets:
            Task {
                await _characterVC.deleteAllCharacterAssets()
            }
            result(nil)
        case .start:
            _characterVC.start()
            result(nil)
        case .close:
            if let dict = call.arguments as? [String: Any], let shouldCleanup = dict["shouldCleanup"] as? Bool {
                _characterVC.close(shouldCleanup: shouldCleanup)
            } else {
                _characterVC.close()
            }
            result(nil)
        case .interrupt:
            _characterVC.interrupt()
            result(nil)
        case .sendAudioData:
            guard AvatarSDK.shared.setUpState == .successed else {
                return result(FlutterError(code: "SDK_NOT_SETUP", message: "SDK setup not completed", details: nil))
            }
            if let dict = call.arguments as? [String: Any], let data = dict["audioData"] as? FlutterStandardTypedData, let end = dict["end"] as? Bool {
                let audioData = data.data
                let ret = _characterVC.sendAudioData(audioData, end: end)
                result(ret)
            } else {
                result(FlutterError(code: "INVALID_DATA", message: "Expected Uint8List", details: nil))
            }
        case .setVolume:
            if let volume = call.arguments as? Double {
                _characterVC.setVolume(Float(volume))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_DATA", message: "Expected Double", details: nil))
            }
        }
    }
    
    func didReceiveEvent(event: PlatformEvent, params: Any) {
        // 当事件发生时，通过MethodChannel通知Flutter
        print("🔧 CharacterPlatformView: 发送事件到Flutter，事件: \(event.rawValue), 参数: \(params)")
        channel.invokeMethod(event.rawValue, arguments: params)
    }
    
    // MARK: - CharacterViewControllerDelegate
    
    func characterViewController(_ characterViewController: CharacterViewController, didReceivedEvent event: PlatformEvent, params: Any) {
        didReceiveEvent(event: event, params: params)
    }
}

class AvatarSDK: SPAvatarSDKDelegate {
    static let shared = AvatarSDK()

    private init() {}

    private var onceToken = false

    func setupIfNeeded(sessionToken: String) {
        guard !onceToken else { return }
        onceToken = true
        SPAvatarSDK.shared.setup(sessionToken: sessionToken, configuration: SPAvatarSDK.Configuration(), delegate: self)
    }

    private(set) var setUpState: PlatformSetUpState = .successed

    func avatarSDKDidStarted() {
        setUpState = .successed
    }
    
    func avatarSDKFailedToStart() {
        setUpState = .notSetUp
    }
}
