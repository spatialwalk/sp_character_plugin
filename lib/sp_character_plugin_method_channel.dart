import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sp_character_plugin_platform_interface.dart';

/// An implementation of [SpCharacterPluginPlatform] that uses method channels.
class MethodChannelSpCharacterPlugin extends SpCharacterPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sp_character_plugin');

  @override
  Future<bool> supportsCurrentDevice() async {
    final result = await methodChannel.invokeMethod<bool>(
      'supportsCurrentDevice',
    );
    return result ?? false;
  }

  @override
  Future<void> setUpEnvironment(String environment) async {
    await methodChannel.invokeMethod<void>(
      'setUpEnvironment',
      environment,
    );
  }
}
