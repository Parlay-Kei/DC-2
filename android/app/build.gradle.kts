import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties file for release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.directcuts.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Disable native debug symbol stripping to avoid cmdline-tools requirement
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        // Required for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Signing configurations
    signingConfigs {
        // Release signing config - uses key.properties file
        // Create this file using: scripts/mobile/create_keystore.sh
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.directcuts.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required for Stripe SDK and multidex
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Enable ProGuard/R8 for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use release signing config if available, otherwise fall back to debug
            // For production builds, always use release signing config
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // WARNING: Debug signing is only for development!
                // Run scripts/mobile/create_keystore.sh to create production keystore
                signingConfigs.getByName("debug")
            }

            // Disable debug logging in release builds
            buildConfigField("boolean", "ENABLE_DEBUG_LOGGING", "false")
        }
        debug {
            isMinifyEnabled = false

            // Enable debug logging in debug builds
            buildConfigField("boolean", "ENABLE_DEBUG_LOGGING", "true")
        }
    }

    // Enable BuildConfig generation
    buildFeatures {
        buildConfig = true
    }
}

dependencies {
    // Required for flutter_local_notifications scheduled notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
