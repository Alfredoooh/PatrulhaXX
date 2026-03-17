# ── Flutter core ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── InAppWebView ──────────────────────────────────────────────────────────────
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# ── flutter_p2p_connection ────────────────────────────────────────────────────
# Usa reflexão interna para WifiP2pManager — sem esta regra crasha em release
-keep class dev.polek.** { *; }
-keep class com.example.flutter_p2p_connection.** { *; }
-dontwarn dev.polek.**
-dontwarn com.example.flutter_p2p_connection.**

# ── mobile_scanner / CameraX ─────────────────────────────────────────────────
-keep class com.journeyapps.barcodescanner.** { *; }
-keep class com.google.zxing.** { *; }
-dontwarn com.journeyapps.barcodescanner.**
-dontwarn com.google.zxing.**
# CameraX — crítico em Android 11 com câmeras antigas
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ── permission_handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── video_player / ExoPlayer ──────────────────────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# ── chewie ────────────────────────────────────────────────────────────────────
-keep class com.github.brianegan.** { *; }
-dontwarn com.github.brianegan.**

# ── path_provider ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ── shared_preferences ────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ── cached_network_image / Glide ──────────────────────────────────────────────
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
    <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-dontwarn com.bumptech.glide.**

# ── Dio / OkHttp / Okio ───────────────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**
-keep class kotlin.Metadata { *; }

# ── Coroutines — crash em Android 11 sem esta regra ──────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# ── AndroidX ──────────────────────────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class androidx.multidex.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ── XML parser ────────────────────────────────────────────────────────────────
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# ── Anotações de compilação — não existem em runtime ─────────────────────────
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn afu.org.checkerframework.**
-dontwarn java.lang.ClassValue

# ── Google Tink (usado internamente por alguns plugins) ───────────────────────
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
