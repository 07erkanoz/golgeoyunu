import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kalıcı imza anahtarı: CI'da ortam değişkenlerinden, yerelde
// android/key.properties dosyasından okunur. İkisi de yoksa debug anahtarı.
// Aynı anahtarla imzalanan sürümler birbirinin üstüne kurulur; kayıtlar
// ve ayarlar silinmez.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

fun signing(name: String, env: String): String? =
    System.getenv(env)?.takeIf { it.isNotEmpty() } ?: keyProps.getProperty(name)

val releaseStore = signing("storeFile", "ANDROID_KEYSTORE_PATH")

// Android çizicisi: Impeller (varsayılan). GOLGE_RENDERER=skia ile Skia'lı
// karşılaştırma derlemesi alınabilir; aynı uygulama, kayıtlar korunur.
// Skia'da Kandilci feneri ilk görüşte ve ekranda kaldıkça takılıyordu
// (RedMagic 8 Pro); Impeller'la düzeldi.
val impeller = System.getenv("GOLGE_RENDERER") != "skia"

android {
    namespace = "com.erkanoz.golge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.erkanoz.golge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["impeller"] = impeller.toString()
    }

    signingConfigs {
        if (releaseStore != null) {
            create("release") {
                storeFile = file(releaseStore)
                storePassword = signing("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signing("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signing("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStore != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
