#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sp_character_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sp_character_plugin'
  s.version          = '1.0.0-beta.47'
  s.summary          = 'A Flutter plugin for SPAvatarKit.'
  s.description      = 'A Flutter plugin that provides iOS and Android integration for SPAvatarKit.'
  s.homepage         = 'https://github.com/spatialwalk/sp_character_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'spatialwalk.ai' => 'yuhang@spatialwalk.net' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/SPAvatarKit.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  
  # Add system library dependencies for SPAvatarKit
  s.libraries = 'z', 'c++'
  
  # Download SPAvatarKit.xcframework dynamically
  s.prepare_command = <<-CMD
    # Clean up old framework and resources if they exist
    if [ -d "Frameworks/SPAvatarKit.xcframework" ]; then
      echo "Removing old SPAvatarKit.xcframework..."
      rm -rf "Frameworks/SPAvatarKit.xcframework"
    fi
    
    if [ -d "Resources/SPAvatarKitResources.bundle" ]; then
      echo "Removing old resource bundle..."
      rm -rf "Resources/SPAvatarKitResources.bundle"
    fi
    
    # Download fresh framework
    echo "Downloading SPAvatarKit.xcframework..."
    curl -L -o SPAvatarKit.zip "https://character-resource-bj-1373098193.cos.ap-beijing.myqcloud.com/xcframework/SPAvatarKit-20251114_092829.zip"
    unzip -q SPAvatarKit.zip
    mkdir -p Frameworks
    mv SPAvatarKit.xcframework Frameworks/
    rm SPAvatarKit.zip
    echo "SPAvatarKit.xcframework downloaded successfully"

    # Copy resource bundle to Resources directory for proper inclusion
    mkdir -p Resources
    if [ -d "Frameworks/SPAvatarKit.xcframework/ios-arm64/SPAvatarKit.framework/Resources/SPAvatarKitResources.bundle" ]; then
      cp -R "Frameworks/SPAvatarKit.xcframework/ios-arm64/SPAvatarKit.framework/Resources/SPAvatarKitResources.bundle" "Resources/"
      echo "Resource bundle copied to Resources directory"
    fi
  CMD

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lz -lc++'
  }
  s.swift_version = '5.0'
  s.resources = ['Resources/SPAvatarKitResources.bundle']
end