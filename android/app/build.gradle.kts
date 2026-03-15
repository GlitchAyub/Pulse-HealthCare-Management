import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val bundledReleaseKeystore = rootProject.file("app/upload-keystore.jks")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun signingValue(propertyName: String, envName: String): String {
    val propertyValue = keystoreProperties.getProperty(propertyName)?.trim().orEmpty()
    if (propertyValue.isNotEmpty()) {
        return propertyValue
    }
    return System.getenv(envName)?.trim().orEmpty()
}

val releaseStoreFile = signingValue("storeFile", "ANDROID_SIGNING_STORE_FILE").ifEmpty {
    if (bundledReleaseKeystore.exists()) "upload-keystore.jks" else ""
}
val releaseStorePassword = signingValue("storePassword", "ANDROID_SIGNING_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_SIGNING_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_SIGNING_KEY_PASSWORD")

val releaseSigningConfigured =
    releaseStoreFile.isNotEmpty() &&
        releaseStorePassword.isNotEmpty() &&
        releaseKeyAlias.isNotEmpty() &&
        releaseKeyPassword.isNotEmpty()

val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

if (releaseTaskRequested && !releaseSigningConfigured) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties from " +
            "android/key.properties.example or set ANDROID_SIGNING_STORE_FILE, " +
            "ANDROID_SIGNING_STORE_PASSWORD, ANDROID_SIGNING_KEY_ALIAS, and " +
            "ANDROID_SIGNING_KEY_PASSWORD.",
    )
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.healthreach.mobileapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.healthreach.mobileapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
