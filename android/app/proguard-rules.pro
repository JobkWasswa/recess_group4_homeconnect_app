#########################################
# 🔐 Flutter ProGuard Rules for Release
#########################################

# Firebase Core (prevents core features from being stripped)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter engine & plugins
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
-dontwarn io.flutter.plugins.**

# Required for AndroidX (used in most Firebase + modern Jetpack libs)
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# WorkManager – required by Firebase Messaging and background services
-keep class androidx.work.** { *; }

# Firebase Messaging specific (for push notifications)
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Firestore
-keep class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Gson (used internally by Firebase and other libs)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Needed for Kotlin coroutines / metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes KotlinMetadata

# Don't strip generic types
-keepattributes Signature

# Optional: helpful during debugging obfuscation
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
