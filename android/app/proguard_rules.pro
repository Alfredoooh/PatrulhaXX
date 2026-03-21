# ── Flutter core ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── InAppWebView ──────────────────────────────────────────────────────────────
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# ── AndroidX ──────────────────────────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class androidx.multidex.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.**

# ── permission_handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── video_player / ExoPlayer / Media3 ────────────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
-dontwarn io.flutter.plugins.videoplayer.**

# ── mobile_scanner / ZXing ───────────────────────────────────────────────────
-keep class com.journeyapps.barcodescanner.** { *; }
-keep class com.google.zxing.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn com.journeyapps.barcodescanner.**
-dontwarn com.google.zxing.**
-dontwarn androidx.camera.**

# ── OkHttp / Okio ─────────────────────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Shared prefs / path_provider ─────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
-dontwarn io.flutter.plugins.pathprovider.**

# ── XML / misc ────────────────────────────────────────────────────────────────
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn java.lang.ClassValue
