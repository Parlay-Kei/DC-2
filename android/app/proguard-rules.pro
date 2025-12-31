# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Stripe SDK rules
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Keep annotation classes
-keepattributes *Annotation*

# Keep generic signatures (for Gson, etc.)
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Google Maps (if used)
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Supabase / GoTrue (network libraries)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core (for deferred components, split APKs)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }

# Suppress warnings for missing Play Core classes (optional feature)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ==========================================
# Direct Cuts Security-Sensitive Classes
# ==========================================

# Obfuscate all application classes while keeping Flutter communication intact
-keep,allowobfuscation class com.directcuts.app.** { *; }

# Remove all debug logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Obfuscate sensitive data handling
-keepclassmembers class * {
    private java.lang.String token;
    private java.lang.String apiKey;
    private java.lang.String password;
    private java.lang.String deviceToken;
}

# Enhanced obfuscation settings
-repackageclasses 'o'
-allowaccessmodification
-overloadaggressively

# Remove source file names and line numbers for additional obfuscation
# (Keep LineNumberTable for crash reporting, but rename source files)
-renamesourcefileattribute SourceFile

# OneSignal (keep required classes)
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Flutter Secure Storage (keep for encryption)
-keep class com.it_nomads.fluttersecurestorage.** { *; }
