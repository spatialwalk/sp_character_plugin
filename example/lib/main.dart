import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp_character_plugin/character_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPAvatarKit Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Character Display'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// 使用新的 Flutter 原生 CharacterWidget 替代原来的平台视图
class CharacterNativeView extends StatefulWidget {
  const CharacterNativeView({super.key});

  @override
  State<CharacterNativeView> createState() => _CharacterNativeViewState();
}

class _CharacterNativeViewState extends State<CharacterNativeView> {
  final GlobalKey<State<CharacterWidget>> _characterKeyA =
      GlobalKey<State<CharacterWidget>>();
  final GlobalKey<State<CharacterWidget>> _characterKeyB =
      GlobalKey<State<CharacterWidget>>();

  late final CharacterController _characterControllerA;
  late final CharacterController _characterControllerB;

  bool _isCharacterLoadedA = false;
  bool _isCharacterLoadedB = false;

  bool _isConnectedA = false;
  bool _isConnectedB = false;

  String _activeCharacter = 'A';

  @override
  void initState() {
    super.initState();
    _characterControllerA = CharacterController(key: _characterKeyA);
    _characterControllerB = CharacterController(key: _characterKeyB);
  }

  /// 播放音频的独立方法
  Future<void> playAudio(String audioPath, bool end) async {
    try {
      // 发送音频
      ByteData audioData = await rootBundle.load(audioPath);
      // 转换为 Uint8List
      Uint8List audioBytes = audioData.buffer.asUint8List();
      
      if (_activeCharacter == 'A') {
        _characterControllerA.sendAudioData(audioBytes, end);
      } else {
        _characterControllerB.sendAudioData(audioBytes, end);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 加载角色到指定控制器
  Future<void> loadCharacter(String characterId, CharacterController controller, String characterName) async {
    try {
      final imagePath = 'assets/image/background.jpeg';
      final imageData = await rootBundle.load(imagePath);
      final backgroundImage = imageData.buffer.asUint8List();
      await controller.loadCharacter(
        characterId,
        backgroundImage: backgroundImage,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 连接或断开指定控制器的服务
  void toggleConnection(CharacterController controller, String characterName) {
    if (characterName == 'A') {
      if (_isConnectedA) {
        controller.close(shouldCleanup: true);
      } else {
        controller.start();
      }
    } else {
      if (_isConnectedB) {
        controller.close(shouldCleanup: true);
      } else {
        controller.start();
      }
    }
  }

  /// 打断当前激活角色的对话
  void interruptActiveCharacter() {
    if (_activeCharacter == 'A') {
      _characterControllerA.interrupt();
    } else {
      _characterControllerB.interrupt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 64.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 300,
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _activeCharacter == 'A' ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _activeCharacter == 'A' ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        CharacterWidget.createWithController(
                          key: _characterKeyA,
                          sessionToken: "",
                          setUpStateChanged: (state) {
                            debugPrint('角色A - SetUp state changed: $state');
                          },
                          loadStateChanged: (state, progress) {
                            setState(() {
                              _isCharacterLoadedA = state == CharacterLoadState.completed;
                            });
                            debugPrint('角色A - Load state changed: $state');
                          },
                          connectionStateChanged: (state) {
                            setState(() {
                              _isConnectedA = state == CharacterConnectionState.connected;
                            });
                            debugPrint('角色A - Connection state changed: $state');
                          },
                          conversationStateChanged: (state) {
                            debugPrint('角色A - Conversation state changed: $state');
                          },
                          playerStateChanged: (state) {
                            debugPrint('角色A - Player state changed: $state');
                          },
                          didEncounteredPlayerError: (error) {
                            debugPrint('角色A - Player error: $error');
                          },
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _activeCharacter == 'A' ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '角色A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCharacter = 'A';
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    height: 300,
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _activeCharacter == 'B' ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _activeCharacter == 'B' ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        CharacterWidget.createWithController(
                          key: _characterKeyB,
                          sessionToken: "",
                          setUpStateChanged: (state) {
                            debugPrint('角色B - SetUp state changed: $state');
                          },
                          loadStateChanged: (state, progress) {
                            setState(() {
                              _isCharacterLoadedB = state == CharacterLoadState.completed;
                            });
                            debugPrint('角色B - Load state changed: $state');
                          },
                          connectionStateChanged: (state) {
                            setState(() {
                              _isConnectedB = state == CharacterConnectionState.connected;
                            });
                            debugPrint('角色B - Connection state changed: $state');
                          },
                          conversationStateChanged: (state) {
                            debugPrint('角色B - Conversation state changed: $state');
                          },
                          playerStateChanged: (state) {
                            debugPrint('角色B - Player state changed: $state');
                          },
                          didEncounteredPlayerError: (error) {
                            debugPrint('角色B - Player error: $error');
                          },
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _activeCharacter == 'B' ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '角色B',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCharacter = 'B';
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeCharacter == 'A' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _activeCharacter == 'A' ? Colors.blue : Colors.green,
                    ),
                  ),
                  child: Text(
                    '当前激活角色: $_activeCharacter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _activeCharacter == 'A' ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final characterId = 'e41f7ee0-3807-4956-b169-1becf8497ebc';
                      if (_activeCharacter == 'A') {
                        loadCharacter(characterId, _characterControllerA, 'A');
                      } else {
                        loadCharacter(characterId, _characterControllerB, 'B');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _activeCharacter == 'A' 
                          ? (_isCharacterLoadedA ? '重新加载角色A' : '加载角色A')
                          : (_isCharacterLoadedB ? '重新加载角色B' : '加载角色B'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_activeCharacter == 'A') {
                        toggleConnection(_characterControllerA, 'A');
                      } else {
                        toggleConnection(_characterControllerB, 'B');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeCharacter == 'A' 
                          ? (_isConnectedA ? Colors.red : Colors.green)
                          : (_isConnectedB ? Colors.red : Colors.green),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _activeCharacter == 'A' 
                          ? (_isConnectedA ? '关闭连接' : '连接服务')
                          : (_isConnectedB ? '关闭连接' : '连接服务'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_activeCharacter == 'A' ? _isConnectedA : _isConnectedB)
                            ? () => playAudio('assets/audio/demo_pcm_audio1.pcm', false)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('播放音频1', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_activeCharacter == 'A' ? _isConnectedA : _isConnectedB)
                            ? () => playAudio('assets/audio/demo_pcm_audio2.pcm', true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('播放音频2', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: interruptActiveCharacter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('打断当前对话', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: CharacterNativeView());
  }
}
