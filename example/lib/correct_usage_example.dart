import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp_character_plugin/character_widget.dart';

/// 正确使用 CharacterWidget 和 CharacterController 的示例
/// 
/// 关键点：
/// 1. Widget 必须先被添加到 widget 树中（通过 setState）
/// 2. 然后才能通过 Controller 调用方法
/// 3. Controller 内部会自动等待 Widget 初始化完成
class CorrectUsageExample extends StatefulWidget {
  const CorrectUsageExample({super.key});

  @override
  State<CorrectUsageExample> createState() => _CorrectUsageExampleState();
}

class _CorrectUsageExampleState extends State<CorrectUsageExample> {
  static const String characterId = 'your-character-id-here';
  
  GlobalKey<State<CharacterWidget>>? _characterKey;
  CharacterController? _characterController;
  bool _isLoading = false;
  String? _errorMessage;

  /// 方式 1: 推荐 - 先创建 Widget，Controller 会自动等待初始化
  Future<void> _loadCharacterRecommended() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _characterKey = GlobalKey<State<CharacterWidget>>();
      _characterController = CharacterController(key: _characterKey!);
    });

    try {
      // Controller 内部会自动等待 Widget 初始化完成
      // 最多等待 5 秒（50 * 100ms）
      await _characterController!.loadCharacter(characterId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 方式 2: 手动控制 - 先创建 Widget，等待一帧，然后调用
  Future<void> _loadCharacterManual() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _characterKey = GlobalKey<State<CharacterWidget>>();
      _characterController = CharacterController(key: _characterKey!);
    });

    // 等待 Widget 构建完成
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await _characterController!.loadCharacter(characterId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onLoadStateChanged(CharacterLoadState state, double? progress) {
    debugPrint('Load state changed: $state, progress: $progress');
    
    if (state == CharacterLoadState.completed) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Character loaded successfully!')),
        );
      }
    } else if (state == CharacterLoadState.fetchCharacterMetaFailed ||
        state == CharacterLoadState.downloadAssetsFailed) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load character: $state';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correct Usage Example'),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadCharacterRecommended,
                  child: const Text('Load Character (Recommended)'),
                ),
                
                const SizedBox(height: 10),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadCharacterManual,
                  child: const Text('Load Character (Manual)'),
                ),
              ],
            ),
          ),
          
          // 隐藏的 CharacterWidget，在后台加载
          if (_characterKey != null)
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
                  connectionStateChanged: (state) {
                    debugPrint('Connection state: $state');
                  },
                ),
              ),
            ),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Loading character...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _characterController?.close(shouldCleanup: true);
    super.dispose();
  }
}

/// 错误示例 - 不要这样做！
class WrongUsageExample extends StatefulWidget {
  const WrongUsageExample({super.key});

  @override
  State<WrongUsageExample> createState() => _WrongUsageExampleState();
}

class _WrongUsageExampleState extends State<WrongUsageExample> {
  static const String characterId = 'your-character-id-here';

  /// ❌ 错误：在 Widget 添加到树之前就调用方法
  Future<void> _loadCharacterWrong() async {
    final key = GlobalKey<State<CharacterWidget>>();
    final controller = CharacterController(key: key);
    
    // ❌ 此时 Widget 还没有被添加到树中，state 为 null
    // 在旧版本中这会静默失败
    await controller.loadCharacter(characterId);
    
    // 然后才添加到树中（太晚了！）
    setState(() {
      // ...
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrong Usage Example'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              '这是错误的使用方式示例',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '不要在 Widget 添加到树之前调用方法',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCharacterWrong,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Wrong Way (Don\'t use!)'),
            ),
          ],
        ),
      ),
    );
  }
}

