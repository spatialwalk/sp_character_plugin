import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp_character_plugin/character_widget.dart';
import 'character_display_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String characterId = 'e41f7ee0-3807-4956-b169-1becf8497ebc';
  
  bool _isLoading = false;
  String _loadingCharacterName = '';
  
  GlobalKey<State<CharacterWidget>>? _characterKey;
  CharacterController? _characterController;

  Future<void> _loadAndNavigate(String characterName) async {
    setState(() {
      _isLoading = true;
      _loadingCharacterName = characterName;
      _characterKey = GlobalKey<State<CharacterWidget>>();
      _characterController = CharacterController(key: _characterKey!);
    });

    try {      
      final imagePath = 'assets/image/background.jpeg';
      final imageData = await rootBundle.load(imagePath);
      final backgroundImage = imageData.buffer.asUint8List();
      await _characterController!.loadCharacter(
        characterId,
        backgroundImage: backgroundImage,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loading failed: $e')),
        );
      }
    }
  }
  
  void _onLoadStateChanged(CharacterLoadState state, double? progress) {
    if (!mounted) return;
    
    if (state == CharacterLoadState.completed) {
      setState(() {
        _isLoading = false;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterDisplayPage(
            characterName: _loadingCharacterName,
            preloadedController: _characterController!,
            characterKey: _characterKey!,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _characterKey = null;
            _characterController = null;
            _loadingCharacterName = '';
          });
        }
      });
    } else if (state == CharacterLoadState.fetchCharacterMetaFailed ||
        state == CharacterLoadState.downloadAssetsFailed) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading failed: $state')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Demo'),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _loadAndNavigate('A'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Load Avatar A',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _loadAndNavigate('B'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Load Avatar B',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading && _characterKey != null)
            Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: Opacity(
                    opacity: 0.0,
                    child: CharacterWidget.createWithController(
                      key: _characterKey!,
                      sessionToken: "",
                      loadStateChanged: _onLoadStateChanged,
                      setUpStateChanged: (state) {
                        debugPrint('SetUp state: $state');
                      },
                    ),
                  ),
                ),
                
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
                          'Loading Avatar $_loadingCharacterName...',
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
        ],
      ),
    );
  }
}

