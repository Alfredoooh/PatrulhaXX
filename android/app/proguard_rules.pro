# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── InAppWebView ──────────────────────────────────────────────────────────────
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# ── Secure Storage / Google Tink ─────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Tink usa anotações do errorprone e javax que não existem em runtime
# São apenas anotações de compilação — seguro ignorar
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.**
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# Tink em geral
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ── Dio / OkHttp ──────────────────────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# ── XML parser ────────────────────────────────────────────────────────────────
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# ── Multidex ──────────────────────────────────────────────────────────────────
-keep class androidx.multidex.** { *; }

# ── Suprimir warnings gerais de anotações ────────────────────────────────────
-dontwarn java.lang.ClassValue
-dontwarn org.checkerframework.**
-dontwarn afu.org.checkerframework.**
