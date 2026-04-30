import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// local.properties — Kakao Native App Key 주입
// 빌드 전 android/local.properties 에 다음 추가 (gitignored):
//   kakao.native.app.key=YOUR_KAKAO_NATIVE_APP_KEY
// 미설정 시 "PLACEHOLDER" 로 fallback (debug 빌드는 가능, 카카오 로그인 실패).
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) {
        FileInputStream(f).use { load(it) }
    }
}
val kakaoNativeAppKey: String =
    localProps.getProperty("kakao.native.app.key", "PLACEHOLDER")

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// key.properties — 출시용 keystore 정보
// 빌드 전 android/key.properties 에 다음 추가 (gitignored):
//   storeFile=../upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// 미설정 시 release 빌드도 debug keystore 로 서명 (Play Store 업로드 불가).
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        FileInputStream(f).use { load(it) }
    }
}
val hasReleaseKey = keyProps.getProperty("storeFile") != null

android {
    namespace = "com.example.rok_us_alliance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: OWNER_SETUP 9단계에서 출시용 Application ID 로 변경.
        applicationId = "com.example.rok_us_alliance_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AndroidManifest.xml 의 ${KAKAO_NATIVE_APP_KEY} 자리에 치환.
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoNativeAppKey
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // key.properties 미설정 시 debug 키로 임시 서명 — `flutter run --release` 만 가능.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
