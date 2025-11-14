package ai.spatialwalk.sp_character_plugin

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.*

/**
 * CharacterPlatformView - manages the native Android view for character display
 */
class CharacterPlatformView(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val viewId: Int,
    sessionToken: String,
    channelName: String
) : PlatformView, CharacterViewControllerDelegate {
    
    companion object {
        private const val TAG = "AvatarKitCharacterPlatformView"
    }

    private val containerView: FrameLayout = FrameLayout(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, channelName)
    // Lifecycle-aware coroutine scope that runs on background thread
    // SupervisorJob ensures failure in one coroutine doesn't cancel others
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val characterViewController: CharacterViewController

    init {
        Log.d(TAG, "Initializing CharacterPlatformView with viewId: $viewId, channelName: $channelName")
        
        characterViewController = CharacterViewController(context, coroutineScope)
        characterViewController.delegate = this
        
        // Setup method channel handler
        Log.d(TAG, "Setting up MethodChannel handler for: $channelName")
        methodChannel.setMethodCallHandler { call, result ->
            handleFlutterCall(call, result)
        }
        
        // Initialize SDK if needed
        AvatarSDK.setupIfNeeded(context)
        AvatarSDK.setSessionToken(sessionToken)
        
        // Notify setup state
        onReceivedEvent(PlatformEvent.DID_UPDATED_CONNECTION_STATE, "disconnected")
    }

    override fun getView(): View {
        return containerView
    }

    override fun dispose() {
        Log.d(TAG, "Disposing CharacterPlatformView")
        characterViewController.cleanup()
        coroutineScope.cancel()
        methodChannel.setMethodCallHandler(null)
    }

    /**
     * Handle Flutter method calls
     */
    private fun handleFlutterCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Received Flutter call: ${call.method}")
        val method = PlatformMethod.fromValue(call.method)
        
        if (method == null) {
            Log.w(TAG, "Unknown method: ${call.method}")
            result.notImplemented()
            return
        }

        when (method) {
            PlatformMethod.LOAD_CHARACTER_DATA -> {
                handleLoadCharacter(call, result)
            }
            PlatformMethod.PRELOAD_CHARACTER_DATA -> {
                handlePreloadCharacter(call, result)
            }
            PlatformMethod.DELETE_CHARACTER_ASSETS -> {
                handleDeleteCharacterAssets(call, result)
            }
            PlatformMethod.DELETE_ALL_CHARACTER_ASSETS -> {
                handleDeleteAllCharacterAssets(result)
            }
            PlatformMethod.START -> {
                characterViewController.start()
                result.success(null)
            }
            PlatformMethod.CLOSE -> {
                val shouldCleanup = (call.arguments as? Map<*, *>)?.get("shouldCleanup") as? Boolean ?: false
                characterViewController.close(shouldCleanup)
                result.success(null)
            }
            PlatformMethod.INTERRUPT -> {
                characterViewController.interrupt()
                result.success(null)
            }
            PlatformMethod.SEND_AUDIO_DATA -> {
                handleSendAudioData(call, result)
            }
            PlatformMethod.SET_VOLUME -> {
                val volume = call.arguments as? Double
                if (volume != null) {
                    characterViewController.setVolume(volume.toFloat())
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Volume must be a number", null)
                }
            }
        }
    }

    /**
     * Handle load character request
     */
    private fun handleLoadCharacter(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val characterId = args?.get("characterId") as? String
        val backgroundImage = args?.get("backgroundImage") as? ByteArray
        val isBackgroundOpaque = args?.get("isBackgroundOpaque") as? Boolean ?: true

        if (characterId == null) {
            result.error("INVALID_ARGUMENT", "characterId is required", null)
            return
        }

        
        // Add avatar view to container when available
        coroutineScope.launch(Dispatchers.IO) {
            // Load character
            characterViewController.loadCharacter(characterId, backgroundImage, isBackgroundOpaque)
            characterViewController.getView()?.let { avatarView ->
                withContext(Dispatchers.Main) {
                    containerView.removeAllViews()
                    containerView.addView(
                        avatarView,
                        FrameLayout.LayoutParams(
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            FrameLayout.LayoutParams.MATCH_PARENT
                        )
                    )
                }
            }
            result.success(null)
        }
    }

    /**
     * Handle preload character request
     */
    private fun handlePreloadCharacter(call: MethodCall, result: MethodChannel.Result) {
        val characterId = call.arguments as? String
        
        if (characterId == null) {
            result.error("INVALID_ARGUMENT", "characterId is required", null)
            return
        }

        coroutineScope.launch {
            val success = characterViewController.preloadCharacter(characterId)
            result.success(success)
        }
    }

    /**
     * Handle delete character assets request
     */
    private fun handleDeleteCharacterAssets(call: MethodCall, result: MethodChannel.Result) {
        val characterId = call.arguments as? String
        
        if (characterId == null) {
            result.error("INVALID_ARGUMENT", "characterId is required", null)
            return
        }

        coroutineScope.launch {
            characterViewController.deleteCharacterAssets(characterId)
            result.success(null)
        }
    }

    /**
     * Handle delete all character assets request
     */
    private fun handleDeleteAllCharacterAssets(result: MethodChannel.Result) {
        coroutineScope.launch {
            characterViewController.deleteAllCharacterAssets()
            result.success(null)
        }
    }

    /**
     * Handle send audio data request
     */
    private fun handleSendAudioData(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val audioData = args?.get("audioData") as? ByteArray
        val end = args?.get("end") as? Boolean ?: false

        if (audioData == null) {
            result.error("INVALID_ARGUMENT", "audioData is required", null)
            return
        }

        val ret = characterViewController.sendAudioData(audioData, end)
        result.success(ret)
    }

    /**
     * CharacterViewControllerDelegate implementation
     */
    override fun onReceivedEvent(event: PlatformEvent, params: Any) {
        Log.d(TAG, "Received event: ${event.value}, params: $params")
        coroutineScope.launch(Dispatchers.Main) {
            methodChannel.invokeMethod(event.value, params)
        }
    }
}

/**
 * Singleton for SDK initialization
 */
object AvatarSDK {
    private const val TAG = "AvatarSDK"
    private var isInitialized = false
    private var environment: ai.spatialwalk.avatarkit.AvatarKit.Environment =
        ai.spatialwalk.avatarkit.AvatarKit.Environment.TEST

    @Synchronized
    fun setupIfNeeded(context: Context) {
        if (isInitialized) {
            return
        }

        try {
            Log.d(TAG, "Initializing AvatarKit SDK")
            ai.spatialwalk.avatarkit.AvatarKit.initialize(
                context = context,
                appId = "", // App ID should be set by the application
                configuration = ai.spatialwalk.avatarkit.AvatarKit.Configuration(
                    environment = environment
                )
            )
            isInitialized = true
            Log.d(TAG, "AvatarKit SDK initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize AvatarKit SDK: ${e.message}", e)
        }
    }

    fun setEnvironment(env: ai.spatialwalk.avatarkit.AvatarKit.Environment) {
        environment = env
    }

    fun setSessionToken(token: String) {
        ai.spatialwalk.avatarkit.AvatarKit.sessionToken = token
    }
}

