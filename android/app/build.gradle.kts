import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

fun resolveSigningValue(propertyName: String, envName: String): String? {
    val fromProps = keystoreProperties.getProperty(propertyName)?.trim()
    if (!fromProps.isNullOrEmpty()) return fromProps
    val fromEnv = System.getenv(envName)?.trim()
    return if (fromEnv.isNullOrEmpty()) null else fromEnv
}

val releaseStoreFile = resolveSigningValue("storeFile", "RELEASE_STORE_FILE")
val releaseStorePassword =
    resolveSigningValue("storePassword", "RELEASE_STORE_PASSWORD")
val releaseKeyAlias = resolveSigningValue("keyAlias", "RELEASE_KEY_ALIAS")
val releaseKeyPassword =
    resolveSigningValue("keyPassword", "RELEASE_KEY_PASSWORD")

val releaseSigningReady =
    listOf(
        releaseStoreFile,
        releaseStorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    ).all { !it.isNullOrEmpty() }

val isReleaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true) ||
        taskName.contains("bundle", ignoreCase = true)
}

android {
    namespace = "com.bgirginn.journal_app"
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

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bgirginn.journal_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningReady) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            ndk {
                // Ensure native symbol tables are generated for Play Console and Flutter's AAB validation.
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

afterEvaluate {
    if (isReleaseTaskRequested && !releaseSigningReady) {
        throw GradleException(
            "Release signing is not configured. Provide key.properties " +
                "(storeFile/storePassword/keyAlias/keyPassword) or CI env vars " +
                "(RELEASE_STORE_FILE, RELEASE_STORE_PASSWORD, RELEASE_KEY_ALIAS, RELEASE_KEY_PASSWORD).",
        )
    }
}
