import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing — reads from android/key.properties ───────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties     = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace   = "com.pulsara.pulsara_kiosk"
    compileSdk  = flutter.compileSdkVersion
    ndkVersion  = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pulsara.pulsara_kiosk"
        // ML Kit + TFLite + camera2 all require API 21+
        minSdk = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName

        // TFLite — only include ABIs that have pre-built TFLite binaries
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // Prevent APK from compressing the TFLite model (required for mmap access)
    androidResources {
        noCompress += listOf("tflite", "lite")
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias     = keystoreProperties["keyAlias"] as String
                keyPassword  = keystoreProperties["keyPassword"] as String
                storeFile    = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled   = false
            isShrinkResources = false
        }
        release {
            // R8 / ProGuard — required for production APK size & obfuscation
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use release keystore if key.properties exists, else fall back to debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
