plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.khoroch"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // or flutter.ndkVersion if you prefer

    defaultConfig {
        applicationId = "com.example.khoroch"
        minSdk = flutter.minSdkVersion          // ✅ Kotlin DSL syntax
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17   // ✅
        targetCompatibility = JavaVersion.VERSION_17   // ✅
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }                 // ✅

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    packaging {
        resources {
            excludes += setOf("META-INF/AL2.0", "META-INF/LGPL2.1")
        }
    }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    // Firebase BoM (optional):
    // implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-analytics")
}
