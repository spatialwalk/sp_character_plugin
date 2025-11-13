import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SDK设置状态
enum CharacterSetUpState {
  /// 未设置
  notSetUp,

  /// 设置成功
  successed,
}

/// 连接状态
enum CharacterConnectionState {
  /// 未连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 遇到错误
  error,
}

/// 播放器状态
enum CharacterPlayerState {
  /// 闲置中
  idle,

  /// 正在播放
  playing,
}

/// 播放器错误
enum CharacterPlayerError {
  /// SDK未验证
  sdkNotVerified,

  /// 数字人ID有问题
  characterIdWrong,

  /// 数字人资源有缺失
  characterAssetsMissing,

  /// 数字人相机设置有问题
  characterCameraSettingsWrong,

  /// 服务器错误
  serviceError,

  /// 激活AudioSession失败
  activeAudioSessionFailed,

  /// 启动AudioEngine失败
  startAudioEngineFailed,

  /// 发送的数据有问题
  sendDataWrong,

  /// 请求超时
  requestTimeout,
}

/// 对话状态
enum CharacterConversationState {
  /// 无对话
  idle,

  /// 正在启动
  starting,

  /// 已激活
  active,

  /// 正在关闭
  closing,
}

enum CharacterLoadState {
  /// 准备加载中
  preparing,

  /// 正在下载
  downloading,

  /// 已完成
  completed,

  /// 提示
  info,

  /// 获取数字人信息失败
  fetchCharacterMetaFailed,

  /// 下载数字人资源失败
  downloadAssetsFailed,
}

/// 数字人 Widget 的回调函数类型
typedef CharacterSetUpStateChangedCallback =
    void Function(CharacterSetUpState state);
typedef CharacterLoadStateChangedCallback =
    void Function(CharacterLoadState state, double? progress);
typedef CharacterConnectionStateChangedCallback =
    void Function(CharacterConnectionState state);
typedef CharacterConversationStateChangedCallback =
    void Function(CharacterConversationState state);
typedef CharacterPlayerStateChangedCallback =
    void Function(CharacterPlayerState state);
typedef CharacterPlayerErrorCallback =
    void Function(CharacterPlayerError error);

/// 数字人控制器，提供外部控制 CharacterWidget 的接口
class CharacterController {
  final GlobalKey<State<CharacterWidget>> _key;

  CharacterController({required GlobalKey<State<CharacterWidget>> key})
    : _key = key;

  /// 获取当前状态，如果 widget 未初始化则返回 null
  _CharacterWidgetState? get _state {
    final state = _key.currentState as _CharacterWidgetState?;
    debugPrint('[CharacterController] Getting _state: $state, key: $_key, currentState: ${_key.currentState}');
    return state;
  }

  /// 等待 Widget 初始化完成
  Future<_CharacterWidgetState?> _waitForState({int maxAttempts = 50}) async {
    for (int i = 0; i < maxAttempts; i++) {
      final state = _state;
      if (state != null && state.mounted) {
        return state;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  /// 加载数字人数据
  Future<void> loadCharacter(
    String characterId, {
    Uint8List? backgroundImage,
    bool isBackgroundOpaque = true,
  }) async {
    // if Platform.isAndroid is true, wait for the state to be initialized
    if (Platform.isAndroid && _state == null) {
      final state = await _waitForState();
      if (state == null) {
        throw Exception('CharacterWidget not initialized after waiting 5 seconds');
      }
    }
    await _state?.loadCharacter(characterId, backgroundImage: backgroundImage, isBackgroundOpaque: isBackgroundOpaque);
  }

  /// 预加载数字人数据
  Future<void> preloadCharacter(String characterId) async {
    await _state?.preloadCharacter(characterId);
  }

  /// 删除数字人数据
  /// [characterId] 数字人ID
  Future<void> deleteCharacterAssets(String characterId) async {
    await _state?.deleteCharacterAssets(characterId);
  }

  // 删除全部数字人数据
  Future<void> deleteAllCharacterAssets() async {
    await _state?.deleteAllCharacterAssets();
  }

  /// 开始数字人对话
  Future<void> start() async {
    await _state?.start();
  }

  /// 关闭数字人对话
  Future<void> close({bool shouldCleanup = false}) async {
    await _state?.close(shouldCleanup: shouldCleanup);
  }

  /// 打断当前对话
  Future<void> interrupt() async {
    await _state?.interrupt();
  }

  /// 发送音频数据
  /// [audioData] 音频二进制数据
  /// [end] 是否结束
  /// 返回对话 ID
  Future<String> sendAudioData(Uint8List audioData, bool end) async {
    return await _state?.sendAudioData(audioData, end) ?? '';
  }

  /// 设置数字人音量
  /// [volume] 音量范围 [0.0, 1.0]
  Future<void> setVolume(double volume) async {
    await _state?.setVolume(volume);
  }

  /// 获取当前SDK设置状态
  CharacterSetUpState? get setUpState => _state?.setUpState;

  /// 获取当前连接状态
  CharacterConnectionState? get connectionState => _state?.connectionState;

  /// 获取当前播放器状态
  CharacterPlayerState? get playerState => _state?.playerState;

  /// 获取当前对话状态
  CharacterConversationState? get conversationState =>
      _state?.conversationState;

  /// 获取错误信息
  String? get errorMessage => _state?.errorMessage;

  /// 检查控制器是否可用（widget 是否已初始化）
  bool get isAvailable => _state != null;
}

/// 数字人 Widget 的公共接口
mixin CharacterWidgetController {
  /// 加载数字人数据
  Future<void> loadCharacter(String characterId, {Uint8List? backgroundImage});

  /// 预加载数字人数据
  Future<void> preloadCharacter(String characterId);

  /// 删除数字人资源
  /// [characterId] 数字人ID
  Future<void> deleteCharacterAssets(String characterId);

  // 删除全部数字人资源
  Future<void> deleteAllCharacterAssets();

  /// 开始数字人对话
  Future<void> start();

  /// 关闭数字人对话
  Future<void> close({bool shouldCleanup = false});

  /// 打断当前对话
  Future<void> interrupt();

  /// 发送音频数据
  Future<String> sendAudioData(Uint8List audioData, bool end);

  /// 设置数字人音量
  Future<void> setVolume(double volume);

  /// 获取当前SDK设置状态
  CharacterSetUpState get setUpState;

  /// 获取数字人加载状态
  CharacterLoadState get loadState;

  /// 获取当前连接状态
  CharacterConnectionState get connectionState;

  /// 获取当前播放器状态
  CharacterPlayerState get playerState;

  /// 获取当前对话状态
  CharacterConversationState get conversationState;

  /// 获取错误信息
  String? get errorMessage;
}

/// Flutter 原生数字人 Widget
class CharacterWidget extends StatefulWidget {
  /// 鉴权token
  final String? sessionToken;

  /// SDK设置状态变更回调
  final CharacterSetUpStateChangedCallback? setUpStateChanged;

  /// 数字人加载状态
  final CharacterLoadStateChangedCallback? loadStateChanged;

  /// 服务连接状态变更回调
  final CharacterConnectionStateChangedCallback? connectionStateChanged;

  /// 对话状态变更回调
  final CharacterConversationStateChangedCallback? conversationStateChanged;

  /// 播放器状态变更回调
  final CharacterPlayerStateChangedCallback? playerStateChanged;

  /// 播放器错误回调
  final CharacterPlayerErrorCallback? didEncounteredPlayerError;

  const CharacterWidget({
    super.key,
    this.sessionToken,
    this.setUpStateChanged,
    this.loadStateChanged,
    this.connectionStateChanged,
    this.conversationStateChanged,
    this.playerStateChanged,
    this.didEncounteredPlayerError,
  });

  /// 创建一个带有 GlobalKey 的 CharacterWidget，方便外部控制
  static CharacterWidget createWithController({
    required GlobalKey<State<CharacterWidget>> key,
    String sessionToken = "",
    CharacterSetUpStateChangedCallback? setUpStateChanged,
    CharacterLoadStateChangedCallback? loadStateChanged,
    CharacterConnectionStateChangedCallback? connectionStateChanged,
    CharacterConversationStateChangedCallback? conversationStateChanged,
    CharacterPlayerStateChangedCallback? playerStateChanged,
    CharacterPlayerErrorCallback? didEncounteredPlayerError,
  }) {
    return CharacterWidget(
      key: key,
      sessionToken: sessionToken,
      setUpStateChanged: setUpStateChanged,
      loadStateChanged: loadStateChanged,
      connectionStateChanged: connectionStateChanged,
      conversationStateChanged: conversationStateChanged,
      playerStateChanged: playerStateChanged,
      didEncounteredPlayerError: didEncounteredPlayerError,
    );
  }

  @override
  State<CharacterWidget> createState() => _CharacterWidgetState();
}

class _CharacterWidgetState extends State<CharacterWidget> with CharacterWidgetController {
  late final String _channelName;
  late final MethodChannel _channel;

  String _sessionToken = '';
  CharacterSetUpState _setUpState = CharacterSetUpState.notSetUp;
  CharacterLoadState _loadState = CharacterLoadState.preparing;
  CharacterConnectionState _connectionState =
      CharacterConnectionState.disconnected;
  CharacterPlayerState _playerState = CharacterPlayerState.idle;
  CharacterConversationState _conversationState =
      CharacterConversationState.idle;

  String? _errorMessage;

  // 实现 CharacterWidgetController mixin 的 getter 方法
  @override
  CharacterSetUpState get setUpState => _setUpState;

  @override
  CharacterLoadState get loadState => _loadState;

  @override
  CharacterConnectionState get connectionState => _connectionState;

  @override
  CharacterPlayerState get playerState => _playerState;

  @override
  CharacterConversationState get conversationState => _conversationState;

  @override
  String? get errorMessage => _errorMessage;

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.sessionToken ?? '';
    _setUpState = CharacterSetUpState.notSetUp;
    _channelName = 'sp_avatarkit_plugin/character_view_$hashCode';
    _channel = MethodChannel(_channelName);
    _setupMethodChannel();
  }

  @override
  void dispose() {
    close(shouldCleanup: true);
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'setUpState':

          /// SDK设置状态发生改变
          _handleSetUpStateUpdate(call.arguments);
          break;

        case 'loadCharacterState':

          /// 数字人加载状态
          _handleLoadStateUpdate(call.arguments);
          break;

        case 'playerDidEncounteredError':

          /// 播放器错误
          _handlePlayerError(call.arguments);
          break;
        case 'didUpdatedConnectionState':

          /// 服务连接状态发生改变
          _handleConnectionStateUpdate(call.arguments);
          break;
        case 'didUpdatedConversationState':

          /// 会话状态发生改变
          _handleConversationStateUpdate(call.arguments);
          break;
        case 'didUpdatedPlayerState':

          /// 播放器状态发生改变
          _handlePlayerStateUpdate(call.arguments);
          break;
      }
    });
  }

  /// 加载数字人数据
  /// [characterId] 数字人ID
  /// [backgroundImage] 背景图片
  /// [isBackgroundOpaque] 是否背景不透明
  /// 返回加载是否成功
  @override
  Future<bool> loadCharacter(
    String characterId, {
    Uint8List? backgroundImage,
    bool isBackgroundOpaque = true,
  }) async {
    try {
      // 调用平台方法加载数字人数据
      final result = await _channel.invokeMethod('loadCharacterData', {
        'characterId': characterId,
        'backgroundImage': backgroundImage,
        'isBackgroundOpaque': isBackgroundOpaque,
      });
      return result == null;
    } catch (e) {
      return false;
    }
  }

  /// 预加载数字人数据
  /// [characterId] 数字人ID
  /// 返回预加载是否成功
  @override
  Future<bool> preloadCharacter(String characterId) async {
    try {
      // 调用平台方法加载数字人数据，并获取返回值
      final result = await _channel.invokeMethod(
        'preloadCharacterData',
        characterId,
      );
      return result == null;
    } catch (e) {
      return false;
    }
  }

  /// 删除数字人资源
  /// [characterId] 数字人ID
  @override
  Future<void> deleteCharacterAssets(String characterId) async {
    try {
      // 调用平台方法加载数字人数据，并获取返回值
      await _channel.invokeMethod('deleteCharacterAssets', characterId);
    } catch (e) {
      debugPrint('deleteCharacterAssets error: $e');
    }
  }

  /// 删除全部数字人资源
  @override
  Future<void> deleteAllCharacterAssets() async {
    try {
      // 调用平台方法加载数字人数据，并获取返回值
      await _channel.invokeMethod('deleteAllCharacterAssets');
    } catch (e) {
      debugPrint('deleteAllCharacterAssets error: $e');
    }
  }

  /// 开始数字人对话
  @override
  Future<void> start() async {
    if (loadState != CharacterLoadState.completed) {
      return;
    }
    try {
      await _channel.invokeMethod('start');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  /// 关闭数字人对话
  @override
  Future<void> close({bool shouldCleanup = false}) async {
    if (loadState != CharacterLoadState.completed) {
      return;
    }
    try {
      await _channel.invokeMethod('close', {'shouldCleanup': shouldCleanup});
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  /// 打断当前对话
  @override
  Future<void> interrupt() async {
    if (loadState != CharacterLoadState.completed) {
      return;
    }
    try {
      await _channel.invokeMethod('interrupt');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  /// 发送音频数据
  /// [audioData] 音频二进制数据
  /// [end] 是否结束
  /// 返回对话 ID
  @override
  Future<String> sendAudioData(Uint8List audioData, bool end) async {
    if (loadState != CharacterLoadState.completed) {
      return '';
    }
    try {
      Map<String, dynamic> arguments = {'audioData': audioData, 'end': end};
      final result = await _channel.invokeMethod('sendAudioData', arguments);
      return result as String;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      return '';
    }
  }

  /// 设置数字人音量
  /// [volume] 音量范围 [0.0, 1.0]
  @override
  Future<void> setVolume(double volume) async {
    if (loadState != CharacterLoadState.completed) {
      return;
    }
    try {
      await _channel.invokeMethod('setVolume', volume);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _handleSetUpStateUpdate(dynamic state) {
    CharacterSetUpState newState;
    if (state is String) {
      switch (state) {
        case 'notSetUp':
          newState = CharacterSetUpState.notSetUp;
          break;
        case 'successed':
          newState = CharacterSetUpState.successed;
          break;
        default:
          newState = CharacterSetUpState.notSetUp;
      }
    } else {
      newState = CharacterSetUpState.notSetUp;
    }

    widget.setUpStateChanged?.call(newState);
  }

  void _handleLoadStateUpdate(dynamic arguments) {
    Map<String, dynamic>? dataMap;

    if (arguments is Map<String, dynamic>) {
      dataMap = arguments;
    } else if (arguments is Map) {
      // 如果是Map但不是Map<String, dynamic>，尝试转换
      dataMap = Map<String, dynamic>.from(arguments);
    } else if (arguments is List) {
      return;
    } else {
      return;
    }

    final stateString = dataMap['state'] as String?;
    final progress = dataMap['progress'] as double?;

    // 处理状态更新
    if (stateString != null) {
      CharacterLoadState newState;
      switch (stateString) {
        case 'preparing':
          newState = CharacterLoadState.preparing;
          break;
        case 'downloading':
          newState = CharacterLoadState.downloading;
          break;
        case 'completed':
          newState = CharacterLoadState.completed;
          break;
        case 'info':
          newState = CharacterLoadState.info;
          break;
        case 'fetchCharacterMetaFailed':
          newState = CharacterLoadState.fetchCharacterMetaFailed;
          break;
        case 'downloadAssetsFailed':
          newState = CharacterLoadState.downloadAssetsFailed;
          break;
        default:
          newState = CharacterLoadState.preparing;
      }

      setState(() {
        _loadState = newState;
      });

      // 调用回调函数，传递状态和进度
      widget.loadStateChanged?.call(newState, progress);
    }
  }

  void _handlePlayerError(dynamic error) {
    CharacterPlayerError newError;
    if (error is String) {
      switch (error) {
        case 'sdkNotVerified':
          newError = CharacterPlayerError.sdkNotVerified;
          break;
        case 'characterIdWrong':
          newError = CharacterPlayerError.characterIdWrong;
          break;
        case 'characterAssetsMissing':
          newError = CharacterPlayerError.characterAssetsMissing;
          break;
        case 'characterCameraSettingsWrong':
          newError = CharacterPlayerError.characterCameraSettingsWrong;
          break;
        case 'activeAudioSessionFailed':
          newError = CharacterPlayerError.activeAudioSessionFailed;
          break;
        case 'startAudioEngineFailed':
          newError = CharacterPlayerError.startAudioEngineFailed;
          break;
        case 'sendDataWrong':
          newError = CharacterPlayerError.sendDataWrong;
          break;
        case 'requestTimeout':
          newError = CharacterPlayerError.requestTimeout;
          break;
        case 'serviceError':
          newError = CharacterPlayerError.serviceError;
        default:
          newError = CharacterPlayerError.sdkNotVerified;
      }
    } else {
      newError = CharacterPlayerError.sdkNotVerified;
    }

    widget.didEncounteredPlayerError?.call(newError);
  }

  void _handleConnectionStateUpdate(dynamic state) {
    CharacterConnectionState newState;
    if (state is String) {
      switch (state) {
        case 'connected':
          newState = CharacterConnectionState.connected;
          break;
        case 'connecting':
          newState = CharacterConnectionState.connecting;
          break;
        case 'error':
          newState = CharacterConnectionState.error;
          break;
        default:
          newState = CharacterConnectionState.disconnected;
      }
    } else {
      newState = CharacterConnectionState.disconnected;
    }

    setState(() {
      _connectionState = newState;
    });

    widget.connectionStateChanged?.call(newState);
  }

  void _handleConversationStateUpdate(dynamic state) {
    CharacterConversationState newState;
    if (state is String) {
      switch (state) {
        case 'idle':
          newState = CharacterConversationState.idle;
          break;
        case 'starting':
          newState = CharacterConversationState.starting;
          break;
        case 'closing':
          newState = CharacterConversationState.closing;
          break;
        case 'active':
          newState = CharacterConversationState.active;
          break;
        default:
          newState = CharacterConversationState.idle;
      }
    } else {
      newState = CharacterConversationState.idle;
    }

    setState(() {
      _conversationState = newState;
    });
    widget.conversationStateChanged?.call(newState);
  }

  void _handlePlayerStateUpdate(dynamic state) {
    CharacterPlayerState newState;
    if (state is String) {
      switch (state) {
        case 'idle':
          newState = CharacterPlayerState.idle;
          break;
        case 'playing':
          newState = CharacterPlayerState.playing;
          break;
        default:
          newState = CharacterPlayerState.idle;
      }
    } else {
      newState = CharacterPlayerState.idle;
    }

    setState(() {
      _playerState = newState;
    });
    widget.playerStateChanged?.call(newState);
  }

  @override
  Widget build(BuildContext context) {
    return _buildCharacterView();
  }

  Widget _buildCharacterView() {
    return IntrinsicHeight(
      child: IntrinsicWidth(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: _buildPlatformView(),
        ),  
      ),
    );
  }

  Widget _buildPlatformView() {
    final creationParams = {
      'viewId': hashCode, 
      'sessionToken': _sessionToken,
      'channelName': _channelName,
    };

    debugPrint('[CharacterWidget] Building platform view with params: $creationParams');

    if (kIsWeb) {
      // Web platform not supported
      return const Center(
        child: Text('Platform view not supported on web'),
      );
    } else if (Platform.isAndroid) {
      debugPrint('[CharacterWidget] Creating AndroidView');
      return AndroidView(
        viewType: 'sp_character_view',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      debugPrint('[CharacterWidget] Creating UiKitView');
      return UiKitView(
        viewType: 'sp_character_view',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return const Center(
        child: Text('Platform not supported'),
      );
    }
  }
}
