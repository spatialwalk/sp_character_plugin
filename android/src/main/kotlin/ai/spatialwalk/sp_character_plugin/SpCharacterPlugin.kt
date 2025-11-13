package ai.spatialwalk.sp_character_plugin

import android.content.Context
import ai.spatialwalk.avatarkit.AvatarKit
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SpCharacterPlugin */
class SpCharacterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sp_character_plugin")
        channel.setMethodCallHandler(this)
        
        // Register platform view factory
        val viewFactory = CharacterPlatformViewFactory(flutterPluginBinding.binaryMessenger)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("sp_character_view", viewFactory)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "supportsCurrentDevice" -> {
                // Android SDK supports devices with API 24+
                result.success(android.os.Build.VERSION.SDK_INT >= 24)
            }
            "setUpEnvironment" -> {
                try {
                    val environment = call.arguments as? String
                    if (environment != null) {
                        val env = when (environment) {
                            "develop" -> AvatarKit.Environment.TEST
                            "release" -> AvatarKit.Environment.CN
                            else -> AvatarKit.Environment.TEST
                        }
                        AvatarKit.initialize(context, "", AvatarKit.Configuration(env))
                        // Note: Initialize will be called in CharacterPlatformView when needed
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Environment must be a string", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to set up environment: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
