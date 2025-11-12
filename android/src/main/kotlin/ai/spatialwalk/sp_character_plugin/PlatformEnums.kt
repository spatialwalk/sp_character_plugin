package ai.spatialwalk.sp_character_plugin

/**
 * Platform event enums
 */
enum class PlatformEvent(val value: String) {
    LOAD_CHARACTER_STATE("loadCharacterState"),
    DID_UPDATED_CONNECTION_STATE("didUpdatedConnectionState"),
    DID_UPDATED_CONVERSATION_STATE("didUpdatedConversationState"),
    DID_UPDATED_PLAYER_STATE("didUpdatedPlayerState"),
    PLAYER_DID_ENCOUNTERED_ERROR("playerDidEncounteredError")
}

/**
 * Platform setup state
 */
enum class PlatformSetUpState(val value: String) {
    NOT_SET_UP("notSetUp"),
    SUCCEEDED("successed")
}

/**
 * Platform methods
 */
enum class PlatformMethod(val value: String) {
    LOAD_CHARACTER_DATA("loadCharacterData"),
    PRELOAD_CHARACTER_DATA("preloadCharacterData"),
    START("start"),
    CLOSE("close"),
    INTERRUPT("interrupt"),
    SEND_AUDIO_DATA("sendAudioData"),
    SET_VOLUME("setVolume"),
    DELETE_CHARACTER_ASSETS("deleteCharacterAssets"),
    DELETE_ALL_CHARACTER_ASSETS("deleteAllCharacterAssets");

    companion object {
        fun fromValue(value: String): PlatformMethod? {
            return entries.find { it.value == value }
        }
    }
}

