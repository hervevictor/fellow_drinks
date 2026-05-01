import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Charge key.properties si présent (absent sur CI → on utilise les secrets d'env)
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties().apply {
    if (keyPropsFile.exists()) load(keyPropsFile.inputStream())
}

android {
    namespace = "com.fellowdrink.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // Priorité : variables d'environnement (CI) puis key.properties (local)
            storeFile = (System.getenv("KEYSTORE_PATH") ?: keyProps["storeFile"] as String?)
                ?.let { file(it) }
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: keyProps["storePassword"] as String?
            keyAlias     = System.getenv("KEY_ALIAS")          ?: keyProps["keyAlias"]     as String?
            keyPassword  = System.getenv("KEY_PASSWORD")       ?: keyProps["keyPassword"]  as String?
        }
    }

    defaultConfig {
        applicationId = "com.fellowdrink.app"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig    = signingConfigs.getByName("release")
            isMinifyEnabled  = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
