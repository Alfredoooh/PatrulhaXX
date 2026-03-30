import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin que gera automaticamente o ecrã "Licenças de software"
    // com todas as licenças das dependências Maven/Gradle
    id("com.google.android.gms.oss-licenses-plugin")
}

android {
    namespace = "com.patrulha.xx"
    compileSdk = flutter.compileSdkVersion
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
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
            pickFirsts += setOf(
                "**/libflutter.so",
                "**/libc++_shared.so",
            )
        }
        resources {
            excludes += setOf(
                // NOTA: META-INF/LICENSE e NOTICE foram removidos daqui
                // para permitir que o oss-licenses-plugin os leia
                // e gere o ecrã de licenças correctamente.
                "META-INF/*.kotlin_module",
                "META-INF/DEPENDENCIES",
                "META-INF/MANIFEST.MF",
                "DebugProbesKt.bin",
                "kotlin-tooling-metadata.json",
                "**/kotlin/**",
                "**/*.proto",
                "**/*.bin",
            )
        }
    }

    signingConfigs {
        create("release") {
            storeFile     = file("debug.keystore")
            storePassword = "android"
            keyAlias      = "androiddebugkey"
            keyPassword   = "android"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled    = true
            isShrinkResources  = true
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
    // Biblioteca que mostra o ecrã de licenças dentro da app
    implementation("com.google.android.gms:play-services-oss-licenses:17.1.0")
}

flutter {
    source = "../.."
}
