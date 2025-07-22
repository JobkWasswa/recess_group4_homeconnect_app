plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Firebase / Play Services
    id("com.google.firebase.crashlytics") // ✅ Correct place
    id("dev.flutter.flutter-gradle-plugin") // Flutter (must be last)
}

android {
    namespace = "com.company.homeconnect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Required by some Firebase components

    defaultConfig {
        applicationId = "com.company.homeconnect"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true // ✅ For large Flutter + Firebase apps
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // 🔧 Disable shrinking for now to fix release crashes
            isMinifyEnabled = false // ✅ Kotlin DSL syntax
            isShrinkResources = false
            // Optional: enable later
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ Firebase BoM manages versions
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // ✅ Add Firebase libraries
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-crashlytics")
}

// ❌ REMOVE this, it's invalid in KTS:
// apply plugin: "com.google.firebase.crashlytics"

// ✅ DO NOT MOVE THIS LINE (still needed)
apply(plugin = "dev.flutter.flutter-gradle-plugin")
