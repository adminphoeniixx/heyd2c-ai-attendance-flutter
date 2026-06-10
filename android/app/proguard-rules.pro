# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ── TFLite (tflite_flutter) ───────────────────────────────────────────────────
# Models must not be compressed — set in build.gradle.kts via aaptOptions
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.**

# ── Google ML Kit ─────────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# ── WorkManager ───────────────────────────────────────────────────────────────
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-dontwarn androidx.work.**

# ── Camera ────────────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# ── Hive (pure Dart — no Java rules needed, but keep generated adapters) ─────
-keep class com.hive.** { *; }
-dontwarn com.hive.**

# ── Workmanager Flutter plugin ────────────────────────────────────────────────
-keep class be.tramckrijte.workmanager.** { *; }
-dontwarn be.tramckrijte.workmanager.**

# ── Connectivity Plus ─────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ── General ───────────────────────────────────────────────────────────────────
# Keep native method names (JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}
# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
# Keep enum members used via reflection
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
# Suppress common 3rd-party warnings
-dontwarn javax.annotation.**
-dontwarn kotlin.reflect.**
