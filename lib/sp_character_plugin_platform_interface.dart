import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sp_character_plugin_method_channel.dart';

abstract class SpCharacterPluginPlatform extends PlatformInterface {
  /// Constructs a SpCharacterPluginPlatform.
  SpCharacterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SpCharacterPluginPlatform _instance = MethodChannelSpCharacterPlugin();

  /// The default instance of [SpCharacterPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSpCharacterPlugin].
  static SpCharacterPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SpCharacterPluginPlatform] when
  /// they register themselves.
  static set instance(SpCharacterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> supportsCurrentDevice() {
    throw UnimplementedError('supportsCurrentDevice() has not been implemented.');
  }

  Future<void> setUpEnvironment(String environment) {
    throw UnimplementedError('setUpEnvironment() has not been implemented.');
  }
}
