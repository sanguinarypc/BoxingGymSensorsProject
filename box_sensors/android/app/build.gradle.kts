import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sanguinarypc.box_sensors"
    compileSdk = flutter.compileSdkVersion   // 35
    ndkVersion = "27.0.12077973" // flutter.ndkVersion
    //ndkVersion = "26.1.10909125" // Βάλτε την έκδοση που εγκαταστήσατε
    

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_17  // JavaVersion.VERSION_11
        
    }

    kotlinOptions {
        // jvmTarget = "17"  // jvmTarget = "11"
        jvmTarget = JavaVersion.VERSION_17.toString()  // JavaVersion.VERSION_11.toString()
    }


    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sanguinarypc.box_sensors"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // 28
        targetSdk = flutter.targetSdkVersion  // 35
        versionCode =  flutter.versionCode  // 2
        versionName =  flutter.versionName  // "1.0.1"
    }

//    signingConfigs {
//        create("release") {
//            keyAlias = keystoreProperties["keyAlias"] as String
//            keyPassword = keystoreProperties["keyPassword"] as String
//            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
//            storePassword = keystoreProperties["storePassword"] as String
//        }
//    }

     signingConfigs {
        create("release") {
            // Ensure your key.properties file has these entries
            // Use null-safe access and provide defaults or handle missing properties gracefully
            keyAlias = keystoreProperties["keyAlias"] as? String ?: ""
            keyPassword = keystoreProperties["keyPassword"] as? String ?: ""
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) } // Use rootProject.file for consistency
            storePassword = keystoreProperties["storePassword"] as? String ?: ""

            // It's recommended to check if the storeFile exists before assigning
            // if (storeFile?.exists() == false) {
            //     throw GradleException("Keystore file not found: ${storeFile?.absolutePath}")
            // }
        }
    }


    buildTypes {
    getByName("release") {
        // Enable code shrinking, obfuscation, etc.
        isMinifyEnabled = true
        isShrinkResources = true
        // proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")

        proguardFiles(
                // Includes the default ProGuard rules files that are packaged with
                // the Android Gradle plugin. To learn more, go to the section about
                // R8 configuration files.
                getDefaultProguardFile("proguard-android-optimize.txt"),

                // Includes a local, custom Proguard rules file
                "proguard-rules.pro"
            )
  
        // signingConfig = signingConfigs.getByName("debug")   // the debug one
        signingConfig = signingConfigs.getByName("release")


        // Configure NDK options within the release build type
        ndk {
            // Workaround: Use string literal instead of enum reference
            debugSymbolLevel = "full"   // "FULL"  "NONE" "SYMBOL_TABLE"
            // abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86"))

        }

        // You can configure other build types like debug here if needed
        getByName("debug") {
             // Debug specific settings
        }


    }
}

}

flutter {
    source = "../.."
}


// Force Java 11 for all JavaCompile tasks and enable unchecked warnings
//tasks.withType<JavaCompile> {
//    sourceCompatibility = "17"  // sourceCompatibility = "11"
//    targetCompatibility = "17"  // targetCompatibility = "11"
//    options.compilerArgs.add("-Xlint:unchecked")
//    options.compilerArgs.add("-Xlint:-options")
//    options.compilerArgs.add("-Xlint:-deprecation")
//}

// Add the following block to enable -Xlint:unchecked warnings for Java compile tasks
// tasks.withType(JavaCompile) {
//    options.compilerArgs << "-Xlint:unchecked"
// }