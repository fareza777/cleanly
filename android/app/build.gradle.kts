import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Private release signing stays optional: without it the release APK is
// debug-signed so it remains installable for local testing. Play Console
// uploads always need the real keystore.
val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties()
if (releaseKeyPropertiesFile.exists()) {
    releaseKeyPropertiesFile.inputStream().use { releaseKeyProperties.load(it) }
}
val releaseSigningFields = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasReleaseSigning = releaseKeyPropertiesFile.exists() &&
    releaseSigningFields.all { !releaseKeyProperties.getProperty(it).isNullOrBlank() }

// Flutter forwards --dart-define-from-file as base64-encoded key/value pairs.
// Keep the native AdMob resource aligned with the private Dart configuration.
val dartDefines = (project.findProperty("dart-defines") as? String)
    .orEmpty().split(",").filter { it.isNotBlank() }.mapNotNull { encoded ->
        runCatching { String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) }
            .getOrNull()?.let { entry ->
                if (entry.contains("=")) entry.substringBefore("=") to entry.substringAfter("=")
                else null
            }
    }.toMap()
val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val configuredAdMobAppId = dartDefines["ADMOB_APP_ID"].orEmpty()
val releaseAdMobAppId =
    if (Regex("ca-app-pub-[0-9]{16}~[0-9]{10}").matches(configuredAdMobAppId) &&
        configuredAdMobAppId != testAdMobAppId
    ) configuredAdMobAppId else testAdMobAppId

/// Package id default adalah milik aplikasi Arunika yang sudah live, karena
/// Cleanly dikirim sebagai update listing yang sama.
///
/// Untuk mencoba APK berdampingan TANPA menyentuh instalasi Arunika (dan tanpa
/// risiko kehilangan data jurnalnya), beri suffix .dev lewat dart-define:
///   flutter build apk --release \
///     --dart-define=CLEANLY_APPLICATION_ID=id.arunika.arunika_growth.dev
val liveApplicationId = "id.arunika.arunika_growth"
val applicationIdOverride = dartDefines["CLEANLY_APPLICATION_ID"].orEmpty()
val resolvedApplicationId =
    if (applicationIdOverride.isNotBlank()) applicationIdOverride else liveApplicationId

android {
    buildFeatures {
        resValues = true
    }
    namespace = "id.arunika.arunika_growth"
    compileSdk = maxOf(36, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Diwajibkan oleh flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = resolvedApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = releaseKeyProperties["keyAlias"] as String
                keyPassword = releaseKeyProperties["keyPassword"] as String
                storeFile = rootProject.file(releaseKeyProperties["storeFile"] as String)
                storePassword = releaseKeyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        configureEach {
            if (name != "release") resValue("string", "admob_app_id", testAdMobAppId)
        }
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            resValue("string", "admob_app_id", releaseAdMobAppId)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
