plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")   // Firebase/Play-Services
    id("dev.flutter.flutter-gradle-plugin") // Flutter (must be last)
}

android {
    namespace = "com.example.homeconnect"
    compileSdk = flutter.compileSdkVersion

    // ─── NDK: use the higher version Firebase needs ───
    ndkVersion = "27.0.12077973"   // <-- CHANGED from flutter.ndkVersion
    // ───────────────────────────────────────────────────

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.example.homeconnect"

        // ─── minSdk must be ≥23 for latest Firebase ───
        minSdk = 23                // <-- CHANGED from flutter.minSdkVersion
        // ───────────────────────────────────────────────
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with debug keys for now so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))
    implementation("com.google.firebase:firebase-analytics")
    // add other Firebase dependencies here as needed (no versions with BoM)
}
