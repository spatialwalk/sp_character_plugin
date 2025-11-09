import UIKit
import SwiftUI
import SPAvatarKit

protocol CharacterViewControllerDelegate: AnyObject {
    func characterViewController(_ characterViewController: CharacterViewController, didReceivedEvent event: PlatformEvent, params: Any) -> Void
}

/// 角色视图控制器
class CharacterViewController: UIViewController {
    
    // MARK: - Properties
    
    private var characterManager: SPCharacterManager!
    private var characterViewController: UIHostingController<SPCharacterView>!
    
    weak var delegate: CharacterViewControllerDelegate?
        
    // MARK: - Public
    
    func loadCharacter(_ characterId: String, backgroundImage: UIImage?, isBackgroundOpaque: Bool) async {
        let character = await SPCharacterLoader.shared.loadCharacter(characterId) { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                self.handleLoadState(state)
            }
        }
        guard let character else { return }
        self.characterManager = SPCharacterManager(character: character, driveServiceType: .animation)
        self.characterManager.delegate = self
        // 在设置 characterManager 后立即设置视图
        setupCharacterView(backgroundImage: backgroundImage, isBackgroundOpaque: isBackgroundOpaque)
    }
    
    func preloadCharacter(_ characterId: String) async -> Bool {
        return await SPCharacterLoader.shared.preloadCharacter(for: characterId)
    }

    func deleteCharacterAssets(_ characterId: String) async {
        try? await SPCharacterLoader.shared.deleteCharacterAssets(for: characterId)
    }

    func deleteAllCharacterAssets() async {
        try? await SPCharacterLoader.shared.deleteAllCharacterAssets()
    }

    func start() {
        guard characterManager != nil else { return }
        guard characterManager.conversationState == .idle else { return }
        characterManager.start()
    }
    
    func close(shouldCleanup: Bool = false) {
        guard characterManager != nil else { return }
        characterManager.close(shouldCleanup: shouldCleanup)
    }
    
    func interrupt() {
        guard characterManager != nil else { return }
        characterManager.interrupt()
    }
        
    func sendAudioData(_ audioData: Data, end: Bool = false) -> String {
        guard let manager = characterManager else { return "" }
        return manager.sendAudioData(audioData, end: end)
    }

    func setVolume(_ volume: Float) {
        guard characterManager != nil else { return }
        characterManager.setPlayerVolume(volume)
    }
    
    // MARK: - Private
    
    private func setupCharacterView(backgroundImage: UIImage?, isBackgroundOpaque: Bool) {
        guard characterManager != nil else { return }

        characterViewController?.willMove(toParent: nil)
        characterViewController?.view.removeFromSuperview()
        characterViewController?.removeFromParent()

        let characterView = SPCharacterView(characterManager: characterManager, backgroundImage: backgroundImage, isOpaque: isBackgroundOpaque)
        let hostingController = UIHostingController(rootView: characterView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.alpha = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 300ms delay for flutter purple flash
            hostingController.view.alpha = 1.0
        }
        characterViewController = hostingController
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func handleLoadState(_ loadState: SPCharacterLoader.LoadState) {
        var params = [String: Any]()
        switch loadState {
        case .preparing:
            params["state"] = "preparing"
        case .downloading(let progress):
            params["state"] = "downloading"
            params["progress"] = progress.progress
        case .completed:
            params["state"] = "completed"
        case .info:
            params["state"] = "info"
        case .failed(let error):
            switch error {
            case .fetchCharacterMetaFailed:
                params["state"] = "fetchCharacterMetaFailed"
            case .downloadAssetsFailed:
                params["state"] = "downloadAssetsFailed"
            @unknown default:
                break
            }
            params["error"] = error.reason
        @unknown default:
            break
        }
        delegate?.characterViewController(self, didReceivedEvent: .loadCharacterState, params: params)
    }
}

extension CharacterViewController: SPCharacterManagerDelegate {
    func characterManager(_ characterManager: SPAvatarKit.SPCharacterManager, didUpdatedConnectionState newConnectionState: SPAvatarKit.SPAvatar.ConnectionState) {
        /// 服务连接状态发生改变，可以根据对话状态更新UI
        delegate?.characterViewController(self, didReceivedEvent: .didUpdatedConnectionState, params: "\(newConnectionState)")
    }

    func characterManager(_ characterManager: SPAvatarKit.SPCharacterManager, didUpdatedConversationState newConversationState: SPAvatarKit.SPAvatar.ConversationState) {
        /// 对话状态发生改变，可以根据对话状态更新UI
        delegate?.characterViewController(self, didReceivedEvent: .didUpdatedConversationState, params: "\(newConversationState)")
    }
    
    func characterManager(_ characterManager: SPAvatarKit.SPCharacterManager, didUpdatedPlayerState newPlayerState: SPAvatarKit.SPAvatar.PlayerState) {
        /// 播放器状态发生改变，可以根据播放器状态更新UI
        delegate?.characterViewController(self, didReceivedEvent: .didUpdatedPlayerState, params: "\(newPlayerState)")
    }
    
    func characterManager(_ characterManager: SPAvatarKit.SPCharacterManager, didEncounteredError error: SPAvatarKit.SPAvatar.Error) {
        delegate?.characterViewController(self, didReceivedEvent: .playerDidEncounteredError, params: error.id)
    }
}
