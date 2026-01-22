import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aya"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // NDK r27 (r28 peut être installé plus tard si nécessaire)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.uborasoftware.aya"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support pour les pages mémoire de 16 KB - alignement ELF requis
        ndk {
            // NDK r28+ supporte l'alignement 16 KB par défaut
        }
    }
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                    ?: throw GradleException("keyAlias not found in key.properties")
                keyPassword = keystoreProperties["keyPassword"] as String?
                    ?: throw GradleException("keyPassword not found in key.properties")
                val storeFileProp = keystoreProperties["storeFile"] as String?
                    ?: throw GradleException("storeFile not found in key.properties")
                storeFile = file(storeFileProp)
                storePassword = keystoreProperties["storePassword"] as String?
                    ?: throw GradleException("storePassword not found in key.properties")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        // signingConfig = signingConfigs.getByName("debug")
    }
    
    // Support pour les pages mémoire de 16 KB (exigence Google Play depuis nov. 2025)
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}