plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
    id("com.google.gms.google-services") // Firebase / Play Services
    id("com.google.firebase.crashlytics") // ✅ Correct place
=======
    id("com.google.gms.google-services") // Firebase plugin
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1
    id("dev.flutter.flutter-gradle-plugin") // Flutter (must be last)
}

android {
    namespace = "com.company.homeconnect"
<<<<<<< HEAD
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Required by some Firebase components
=======
    compileSdk = 35

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1

    defaultConfig {
        applicationId = "com.company.homeconnect"
        minSdk = 23
<<<<<<< HEAD
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
=======
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1
    }

    buildTypes {
        release {
<<<<<<< HEAD
            signingConfig = signingConfigs.getByName("debug")

            // 🔧 Disable shrinking for now to fix release crashes
            isMinifyEnabled = false // ✅ Kotlin DSL syntax
            isShrinkResources = false
            // Optional: enable later
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
=======
            signingConfig = signingConfigs.getByName("debug") // for testing release builds
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
<<<<<<< HEAD
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ Firebase BoM manages versions
=======
    // Firebase BoM to manage versions automatically
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // ✅ Add Firebase libraries
    implementation("com.google.firebase:firebase-analytics")
<<<<<<< HEAD
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-crashlytics")
=======
    // Add other Firebase dependencies here if needed
>>>>>>> 7f3b570ed12086c563afa17345c95caf77e538f1
}

// ❌ REMOVE this, it's invalid in KTS:
// apply plugin: "com.google.firebase.crashlytics"

// ✅ DO NOT MOVE THIS LINE (still needed)
apply(plugin = "dev.flutter.flutter-gradle-plugin")
