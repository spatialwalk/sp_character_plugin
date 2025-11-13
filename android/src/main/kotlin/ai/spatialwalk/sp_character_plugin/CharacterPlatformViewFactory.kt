package ai.spatialwalk.sp_character_plugin

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for creating CharacterPlatformView instances
 */
class CharacterPlatformViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        private const val TAG = "AvatarKitCharacterPlatformViewFactory"
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        Log.d(TAG, "Creating CharacterPlatformView with viewId: $viewId")
        
        var sessionToken = ""
        var customViewId = viewId
        var channelName = "sp_avatarkit_plugin/character_view_$viewId"

        // Parse creation arguments
        if (args is Map<*, *>) {
            sessionToken = args["sessionToken"] as? String ?: ""
            customViewId = (args["viewId"] as? Number)?.toInt() ?: viewId
            channelName = args["channelName"] as? String ?: channelName
            
            Log.d(TAG, "Creation params - viewId: $customViewId, channelName: $channelName")
        }

        return CharacterPlatformView(
            context = context,
            messenger = messenger,
            viewId = customViewId,
            sessionToken = sessionToken,
            channelName = channelName
        )
    }
}

