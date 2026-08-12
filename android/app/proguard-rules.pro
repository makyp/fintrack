# Flutter local notifications - preserve Gson TypeToken generic signatures
# Required when R8/ProGuard is enabled to prevent:
# "TypeToken must be created with a type argument" IllegalStateException
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

# Keep flutter_local_notifications scheduled notification models
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Gson generic type preservation
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep generic signatures for all classes used with Gson TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# ML Kit text recognition (lectura de recibos).
# El plugin referencia los reconocedores de todos los alfabetos, pero solo
# empaquetamos el latino: sin esto R8 falla por las clases ausentes de
# coreano/japonés/chino/devanagari.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.** { *; }
