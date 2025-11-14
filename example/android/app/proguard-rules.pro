# ProGuard rules for sp_character_plugin example app

# Keep all classes in ai.spatialwalk.avatarkit.model.driveningress package
# Don't obfuscate, optimize, or shrink these classes
-keep class ai.spatialwalk.avatarkit.model.driveningress.** { *; }

# Keep all members (fields and methods) of classes in this package
-keepclassmembers class ai.spatialwalk.avatarkit.model.driveningress.** { *; }

# Don't warn about classes in this package
-dontwarn ai.spatialwalk.avatarkit.model.driveningress.**

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Keep annotations
-keepattributes *Annotation*

