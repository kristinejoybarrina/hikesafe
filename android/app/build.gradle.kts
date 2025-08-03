plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must come last
}

android {
    namespace = "com.example.thesis"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // 🔧 Set explicitly to match plugin requirements

    defaultConfig {
        applicationId = "com.example.thesis"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" // ✅ Explicit JVM target for Kotlin
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
