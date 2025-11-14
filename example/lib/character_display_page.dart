import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp_character_plugin/character_widget.dart';

class CharacterDisplayPage extends StatefulWidget {
  final String characterName;
  final String characterId;

  const CharacterDisplayPage({
    super.key,
    required this.characterName,
    required this.characterId,
  });

  @override
  State<CharacterDisplayPage> createState() => _CharacterDisplayPageState();
}

class _CharacterDisplayPageState extends State<CharacterDisplayPage> {
  late final CharacterController _characterController;
  late final GlobalKey<State<CharacterWidget>> _characterKey;

  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _characterKey = GlobalKey<State<CharacterWidget>>();
    _characterController = CharacterController(key: _characterKey);
  }

  Future<void> _loadCharacter() async { 
    try {
      await _characterController.loadCharacter(
        widget.characterId,
        backgroundImage: null,
      );
    } catch (e) {
      debugPrint('Loading failed: $e');
    }
  }

  @override
  void deactivate() {
    _characterController.close(shouldCleanup: true);
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleConnection() {
    if (_isConnected) {
      _characterController.close(shouldCleanup: false);
    } else {
      _characterController.start();
    }
  }

  Future<void> _playAudio(String audioPath, bool end) async {
    try {
      ByteData audioData = await rootBundle.load(audioPath);
      Uint8List audioBytes = audioData.buffer.asUint8List();
      await _characterController.sendAudioData(audioBytes, end);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }
  }

  void _interrupt() {
    _characterController.interrupt();
  }

  @override
  Widget build(BuildContext context) {
    final characterColor = widget.characterName == 'A' ? Colors.blue : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text('Avatar ${widget.characterName}'),
        backgroundColor: characterColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      margin: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(color: characterColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CharacterWidget.createWithController(
                          key: _characterKey,
                          sessionToken: "",
                          setUpStateChanged: (state) {
                            // 在数字人组件 setup 好之后，才开始调用数字人方法                            
                            if (state == CharacterSetUpState.successed) {
                              _loadCharacter();
                            }
                          },
                          loadStateChanged: (state, progress) {
                            setState(() {
                              _isLoading = !(state == CharacterLoadState.completed 
                              || state == CharacterLoadState.fetchCharacterMetaFailed 
                              || state == CharacterLoadState.downloadAssetsFailed);
                            });
                            debugPrint('Avatar Load state: $state, progress: $progress');
                          },
                          connectionStateChanged: (state) {
                            setState(() {
                              _isConnected = state == CharacterConnectionState.connected;
                            });
                            debugPrint('Avatar Connection state: $state');
                          },
                          conversationStateChanged: (state) {
                            debugPrint('Avatar Conversation state: $state');
                          },
                          playerStateChanged: (state) {
                            debugPrint('Avatar Player state: $state');
                          },
                          didEncounteredPlayerError: (error) {
                            debugPrint('Avatar Player error: $error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Player error: $error')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: !_isLoading ? _toggleConnection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isConnected ? 'Disconnect' : 'Connect',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isConnected
                              ? () => _playAudio('assets/audio/demo_pcm_audio1.pcm', false)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '  Send\nAudio 1',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isConnected
                              ? () => _playAudio('assets/audio/demo_pcm_audio2.pcm', true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send \n  Audio 2 (End)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isConnected ? _interrupt : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Interrupt',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading Avatar ${widget.characterName}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}