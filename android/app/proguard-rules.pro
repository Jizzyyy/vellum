# Suppress warnings for missing ML Kit text recognition packages you do not bundle
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**

# Preserve ML Kit and Firebase components loaded reflectively
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
-keep class com.google.mlkit.common.internal.CommonComponentRegistrar {
    public <init>();
}
-keep class com.google.mlkit.vision.common.internal.VisionCommonRegistrar {
    public <init>();
}
-keep class com.google.mlkit.vision.text.internal.TextRegistrar {
    public <init>();
}

# Preserve the public ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

# Preserve internal GMS ML Kit implementations (critical under R8 Full Mode)
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }

# Prevent native JNI methods from being renamed or stripped
-keepclasseswithmembernames class * {
    native <methods>;
}
