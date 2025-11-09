import Foundation

/// 平台事件枚举
enum PlatformEvent: String {
    case loadCharacterState = "loadCharacterState"
    case didUpdatedConnectionState = "didUpdatedConnectionState"
    case didUpdatedConversationState = "didUpdatedConversationState"
    case didUpdatedPlayerState = "didUpdatedPlayerState"
    case playerDidEncounteredError = "playerDidEncounteredError"
}

enum PlatformSetUpState: String {
    case notSetUp = "notSetUp"
    case successed = "successed"
}

/// 平台方法枚举
enum PlatformMethod: String {
    case loadCharacterData = "loadCharacterData"
    case preloadCharacterData = "preloadCharacterData"
    case start = "start"
    case close = "close"
    case interrupt = "interrupt"
    case sendAudioData = "sendAudioData"
    case setVolume = "setVolume"
    case deleteCharacterAssets = "deleteCharacterAssets"
    case deleteAllCharacterAssets = "deleteAllCharacterAssets"
}
