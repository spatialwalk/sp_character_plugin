package ai.spatialwalk.sp_character_plugin

import android.content.Context
import android.util.Log
import ai.spatialwalk.avatarkit.AvatarView
import ai.spatialwalk.avatarkit.assets.AvatarManager
import ai.spatialwalk.avatarkit.AvatarController
import kotlinx.coroutines.*

/**
 * Delegate interface for CharacterViewController events
 */
interface CharacterViewControllerDelegate {
    fun onReceivedEvent(event: PlatformEvent, params: Any)
}

/**
 * Character view controller that manages avatar operations
 */
class CharacterViewController(
    private val context: Context,
    private val coroutineScope: CoroutineScope
) {
    companion object {
        private const val TAG = "AvatarKitCharacterViewController"
    }

    private var avatarView: AvatarView? = null
    private var avatarController: AvatarController? = null
    var delegate: CharacterViewControllerDelegate? = null

    /**
     * Get the avatar view
     */
    fun getView(): AvatarView? = avatarView

    /**
     * Load character with specified ID
     */
    suspend fun loadCharacter(
        characterId: String,
        backgroundImage: ByteArray?,
        isBackgroundOpaque: Boolean
    ) {
        try {
            AvatarManager.initialize(context)

            // Notify preparing state
            notifyLoadState("preparing", null)

            // Load avatar
            val avatar = AvatarManager.load(characterId) { progress ->
                when (progress) {
                    is AvatarManager.LoadProgress.Downloading -> {
                        notifyLoadState("downloading", progress.progress.toDouble())
                    }

                    is AvatarManager.LoadProgress.Completed -> {
                        Log.d(TAG, "Avatar loaded successfully")
                        notifyLoadState("completed", null)
                    }

                    is AvatarManager.LoadProgress.Failed -> {
                        Log.e(TAG, "Failed to load avatar: ${progress.error.message}")
                        notifyLoadState("downloadAssetsFailed", null)
                    }
                }
            }

            withContext(Dispatchers.Main) {
                avatarView = AvatarView(context)
                avatarView?.init(avatar, coroutineScope)
                avatarView?.isOpaque = isBackgroundOpaque
            }

            avatarController = avatarView?.avatarController
            // Setup connection state listener
            avatarController?.onConnectionState = { state ->
                val stateString = when (state) {
                    is AvatarController.ConnectionState.Disconnected -> "disconnected"
                    is AvatarController.ConnectionState.Connecting -> "connecting"
                    is AvatarController.ConnectionState.Connected -> "connected"
                    is AvatarController.ConnectionState.Failed -> "error"
                    else -> "disconnected"
                }
                delegate?.onReceivedEvent(
                    PlatformEvent.DID_UPDATED_CONNECTION_STATE,
                    stateString
                )
            }

            // Setup avatar state listener (maps to player state)
            avatarController?.onAvatarState = { state ->
                val stateString = when (state.name) {
                    "Idle" -> "idle"
                    "Playing" -> "playing"
                    else -> "idle"
                }
                delegate?.onReceivedEvent(
                    PlatformEvent.DID_UPDATED_PLAYER_STATE,
                    stateString
                )
            }

            // Setup error listener
            avatarController?.onError = { error ->
                Log.e(TAG, "Avatar error: ${error.message}")
                delegate?.onReceivedEvent(
                    PlatformEvent.PLAYER_DID_ENCOUNTERED_ERROR,
                    "serviceError"
                )
            }

            notifyLoadState("completed", null)
        } catch (e: Exception) {
            Log.e(TAG, "Error loading character: ${e.message}", e)
            notifyLoadState("fetchCharacterMetaFailed", null)
        }
    }

    /**
     * Preload character data
     */
    suspend fun preloadCharacter(characterId: String): Boolean {
        return try {
            withContext(Dispatchers.IO) {
                AvatarManager.initialize(context)
                AvatarManager.load(characterId)
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error preloading character: ${e.message}", e)
            false
        }
    }

    /**
     * Delete character assets
     */
    suspend fun deleteCharacterAssets(characterId: String) {
        try {
            withContext(Dispatchers.IO) {
                AvatarManager.clear(characterId)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting character assets: ${e.message}", e)
        }
    }

    /**
     * Delete all character assets
     */
    suspend fun deleteAllCharacterAssets() {
        try {
            withContext(Dispatchers.IO) {
                AvatarManager.clearAll()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting all character assets: ${e.message}", e)
        }
    }

    /**
     * Start avatar conversation
     */
    fun start() {
        try {
            avatarController?.start()
            delegate?.onReceivedEvent(
                PlatformEvent.DID_UPDATED_CONVERSATION_STATE,
                "active"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error starting conversation: ${e.message}", e)
        }
    }

    /**
     * Close avatar conversation
     */
    fun close(shouldCleanup: Boolean = false) {
        try {
            avatarController?.stop()
            if (shouldCleanup) {
                cleanup()
            }
            delegate?.onReceivedEvent(
                PlatformEvent.DID_UPDATED_CONVERSATION_STATE,
                "idle"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error closing conversation: ${e.message}", e)
        }
    }

    /**
     * Interrupt current conversation
     */
    fun interrupt() {
        try {
            avatarController?.interrupt()
        } catch (e: Exception) {
            Log.e(TAG, "Error interrupting conversation: ${e.message}", e)
        }
    }

    /**
     * Send audio data
     */
    fun sendAudioData(audioData: ByteArray, end: Boolean): String {
        return try {
            avatarController?.send(audioData, end)
            "success"
        } catch (e: Exception) {
            Log.e(TAG, "Error sending audio data: ${e.message}", e)
            ""
        }
    }

    /**
     * Set player volume
     */
    fun setVolume(volume: Float) {
        try {
            // Note: AvatarController doesn't expose volume control in the documented API
            // This is a placeholder for future implementation
            Log.d(TAG, "setVolume called with $volume")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting volume: ${e.message}", e)
        }
    }

    /**
     * Pause rendering
     */
    fun onPause() {
        avatarView?.onPause()
    }

    /**
     * Resume rendering
     */
    fun onResume() {
        avatarView?.onResume()
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        avatarView?.cleanup()
        avatarView = null
        avatarController = null
    }

    /**
     * Notify load state changes
     */
    private fun notifyLoadState(state: String, progress: Double?) {
        val params = mutableMapOf<String, Any>("state" to state)
        progress?.let { params["progress"] = it }
        runBlocking {
            withContext(Dispatchers.Main) {
                delegate?.onReceivedEvent(PlatformEvent.LOAD_CHARACTER_STATE, params)
            }
        }
    }
}

