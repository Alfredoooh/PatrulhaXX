# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# InAppWebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# XML parser
-keep class org.xmlpull.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
