# sp_character_plugin

A Flutter plugin for character management on iOS 16+ with SPAvatarKit integration.

## Features

- **Character Management**: Create, load, and manage 3D characters
- **Real-time Animation**: Support for real-time character animation
- **iOS 16+ Support**: Optimized for iOS 16 and above
- **Dynamic Framework Loading**: Automatically downloads SPAvatarKit framework during installation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  sp_character_plugin: ^1.0.0-beta.41
```

Then run:

```bash
flutter pub get
```

## iOS Setup

### Minimum Requirements

- iOS 16.0+
- Xcode 16.0+
- Flutter 3.3.0+

### Podfile Configuration

Add the following to your `ios/Podfile`:

```ruby
platform :ios, '16.0'
```

### Privacy Permissions

Add the following permissions to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for character capture</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for audio processing</string>
```

## Usage

### Basic Character Widget

```dart
import 'package:sp_character_plugin/character_widget.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  late final CharacterController characterController;
  
  final characterKey = GlobalKey<State<CharacterWidget>>();

  @override
  void initState() {
    super.initState();
    characterController = CharacterController(key: characterKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CharacterWidget.createWithController(
        key: characterKey,
      ),
    );
  }
```

### Character Management

```dart
// Load a character
try {
  // optional background image
  final imagePath = 'assets/image/background.jpeg';
  final imageData = await rootBundle.load(imagePath);
  final backgroundImage = imageData.buffer.asUint8List();

  await _characterController.loadCharacter(
    'characterId',
    backgroundImage: backgroundImage,
  );
} catch (e) {
  print('Failed to load character: $e');
}

// start connection
_characterController.start()

// close connection
_characterController.close()

// play audio
try {
  ByteData audioData = await rootBundle.load(audioPath);
  Uint8List audioBytes = audioData.buffer.asUint8List();    _characterController.sendAudioData(audioBytes, true);
} catch (e) {
  print('Failed to play audio: $e');
}
```

## Architecture

The plugin uses a hybrid approach:

- **Dart Layer**: Provides the Flutter interface and character management logic
- **iOS Native Layer**: Handles SPAvatarKit integration and platform-specific functionality
- **Dynamic Framework Loading**: SPAvatarKit is downloaded automatically during pod install

## Framework Integration

SPAvatarKit is integrated as a dynamic dependency that gets downloaded during the CocoaPods installation process. This keeps the plugin package size minimal while providing full functionality.

## Troubleshooting

### Common Issues

1. **Build Errors**: Ensure you're using iOS 16.0+ and Xcode 16.0+
2. **Framework Not Found**: Run `cd ios && pod install` to download SPAvatarKit
3. **Permission Errors**: Add required permissions to Info.plist

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:

- GitHub Issues: [Create an issue](https://github.com/spatialwalk/sp_character_plugin/issues)
- Email: contact@spatialwalk.com

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.