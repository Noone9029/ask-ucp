plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.askucp.ask_ucp_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Kotlin DSL uses "isCoreLibraryDesugaringEnabled"
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.askucp.ask_ucp_flutter"
        minSdk = 24              // ✅ Kotlin DSL
        targetSdk = 34           // ✅ Kotlin DSL
        multiDexEnabled = true
        versionName = flutter.versionName
        versionCode = flutter.versionCode
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // your other deps…
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
    
flutter {
    source = "../.."
}
