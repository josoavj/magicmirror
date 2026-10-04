-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit Pose Detection & MediaPipe Internal JNI field rules
-keep class com.google.android.gms.internal.mlkit_vision_mediapipe.** { *; }
-keepclassmembers class com.google.android.gms.internal.mlkit_vision_mediapipe.** { *; }
-keep class com.google.mlkit.vision.pose.** { *; }
-keepclassmembers class com.google.mlkit.vision.pose.** { *; }
