import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp_character_plugin/character_widget.dart';

class CharacterDisplayPage extends StatefulWidget {
  final String characterName;
  final CharacterController? preloadedController;
  final GlobalKey<State<CharacterWidget>>? characterKey;

  const CharacterDisplayPage({
    super.key,
    required this.characterName,
    this.preloadedController,
    this.characterKey,
  });

  @override
  State<CharacterDisplayPage> createState() => _CharacterDisplayPageState();
}

class _CharacterDisplayPageState extends State<CharacterDisplayPage> {
  late final CharacterController _characterController;
  late final GlobalKey<State<CharacterWidget>> _characterKey;

  bool _isCharacterLoaded = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.preloadedController != null && widget.characterKey != null) {
      _characterController = widget.preloadedController!;
      _characterKey = widget.characterKey!;
    } else {
      _characterKey = GlobalKey<State<CharacterWidget>>();
      _characterController = CharacterController(key: _characterKey);
    }
  }

  @override
  void dispose() {
    _characterController.close(shouldCleanup: true);
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
      body: Column(
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
                        debugPrint('Avatar ${widget.characterName} - SetUp state: $state');
                      },
                      loadStateChanged: (state, progress) {
                        setState(() {
                          _isCharacterLoaded = state == CharacterLoadState.completed;
                        });
                        debugPrint('Avatar ${widget.characterName} - Load state: $state, progress: $progress');
                      },
                      connectionStateChanged: (state) {
                        setState(() {
                          _isConnected = state == CharacterConnectionState.connected;
                        });
                        debugPrint('Avatar ${widget.characterName} - Connection state: $state');
                      },
                      conversationStateChanged: (state) {
                        debugPrint('Avatar ${widget.characterName} - Conversation state: $state');
                      },
                      playerStateChanged: (state) {
                        debugPrint('Avatar ${widget.characterName} - Player state: $state');
                      },
                      didEncounteredPlayerError: (error) {
                        debugPrint('Avatar ${widget.characterName} - Player error: $error');
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
                    onPressed: _isCharacterLoaded ? _toggleConnection : null,
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
    );
  }
}