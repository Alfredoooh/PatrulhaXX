import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Keystore ──────────────────────────────────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.patrulha.xx"
    compileSdk = flutter.compileSdkVersion
    // NDK fixo — evita mismatch de versão entre plugins nativos
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.patrulha.xx"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // Inclui armeabi-v7a (32-bit) e arm64-v8a (64-bit)
        // Evita crash em MediaTek e Snapdragon que só suportam uma das ABIs
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    packaging {
        jniLibs {
            // Evita crash de libs nativas duplicadas entre flutter_p2p_connection,
            // mobile_scanner, flutter_inappwebview e video_player
            useLegacyPackaging = true
            pickFirsts += setOf(
                "**/libflutter.so",
                "**/libc++_shared.so",
            )
        }
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
            )
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias     = keystoreProperties["keyAlias"] as String
                keyPassword  = keystoreProperties["keyPassword"] as String
                storeFile    = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (keystorePropertiesFile.exists()) "release" else "debug"
            )
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
