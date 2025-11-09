import 'sp_character_plugin_platform_interface.dart';

class SpCharacterPlugin {
  Future<bool> supportsCurrentDevice() {
    return SpCharacterPluginPlatform.instance.supportsCurrentDevice();
  }

  /// 设置环境 develop / release
  Future<void> setUpEnvironment(String environment) {
    return SpCharacterPluginPlatform.instance.setUpEnvironment(environment);
  }
}