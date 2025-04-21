plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sanguinarypc.box_sensors2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // flutter.ndkVersion
    

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_17  // JavaVersion.VERSION_11
        
    }

    kotlinOptions {
        jvmTarget = "17"  // jvmTarget = "11"
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()  // JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sanguinarypc.box_sensors2"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
  
        signingConfig = signingConfigs.getByName("debug")
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