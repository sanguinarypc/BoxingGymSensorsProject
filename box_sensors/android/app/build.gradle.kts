// --- imports ---
import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// Προαιρετικό: αν θες να χρησιμοποιήσεις enum αντί για string στο ndk.debugSymbolLevel
// import com.android.build.api.dsl.DebugSymbolLevel

plugins { // (χωρίς version στο plugins block εδώ)
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin") // Το Flutter plugin ΜΕΤΑ τα Android/Kotlin plugins
    // id("org.jetbrains.kotlin.android") // Μπορεί clsνα μείνει έτσι. Εναλλακτικά: id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sanguinarypc.box_sensors"

    // Χρησιμοποιούμε τα versions που δίνει το Flutter plugin (καλό για συντήρηση)
    compileSdk = 37 // flutter.compileSdkVersion // π.χ.  36  35
    // (when Android 16/API 36 is finalized) // compileSdk = 36

    // Σταθερό NDK: χρησιμοποίησε αυτό που έχεις εγκατεστημένο.
    // Αν το 29.0.14206865 δεν είναι εγκατεστημένο, προτείνεται το 28.2.13676358
    ndkVersion = flutter.ndkVersion // "29.0.14206865" // ή "26.3.11579264"

    compileOptions {
        // AGP 8+ συνιστά JDK 17
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ ADD THIS block to include Kotlin sources in src/main/kotlin mostly not realy need in vs code
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/java", "src/main/kotlin")
        }
    }    

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sanguinarypc.box_sensors"

        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // 28
        targetSdk = 36 // flutter.targetSdkVersion  // 35
        versionCode = flutter.versionCode // 2
        versionName = flutter.versionName // "1.0.1"
    }

    signingConfigs {
        create("release") {
            // Ensure your key.properties file has these entries
            // Use null-safe access and provide defaults or handle missing properties gracefully
            keyAlias = keystoreProperties["keyAlias"] as? String ?: ""
            keyPassword = keystoreProperties["keyPassword"] as? String ?: ""
            storeFile =
                keystoreProperties["storeFile"]?.let { rootProject.file(it) } // Use rootProject.file for consistency
            storePassword = keystoreProperties["storePassword"] as? String ?: ""

            // Αν θέλεις αυστηρό έλεγχο:
            // It's recommended to check if the storeFile exists before assigning
            // if (storeFile?.exists() == false) {
            //     throw GradleException("Keystore file not found: ${storeFile?.absolutePath}")
            // }
        }
    }

    buildTypes {
        getByName("release") {
            // ✅ Σύγχρονος τρόπος (R8): shrink/obfuscate/optimize  Enable code shrinking, obfuscation, etc.
            isMinifyEnabled = true
            isShrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")

            proguardFiles(
                // Includes the default ProGuard rules files that are packaged with
                // the Android Gradle plugin. To learn more, go to the section about
                // R8 configuration files.
                getDefaultProguardFile("proguard-android-optimize.txt"),

                // Includes a local, custom Proguard rules file
                "proguard-rules.pro",
            )

            // signingConfig = signingConfigs.getByName("debug")   // the debug one
            signingConfig = signingConfigs.getByName("release")

            // Configure NDK options within the release build type
            ndk {
                // Προτεινόμενο με enum (πιο «καθαρό» για Kotlin DSL)   // Workaround: Use string literal instead of enum reference
                // debugSymbolLevel = DebugSymbolLevel.FULL
                // Αν για οποιονδήποτε λόγο «γκρινιάξει» το enum, γύρνα στο string:
                debugSymbolLevel = "full" // "FULL" | "SYMBOL_TABLE" | "NONE"

                // Προαιρετικό: περιορισμός σε συγκεκριμένα ABIs για μείωση μεγέθους APK/AAB
                // abiFilters.addAll(listOf("arm64-v8a","armeabi-v7a"))
                // abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86"))
            }
        }

        // You can configure other build types like debug here if needed
        getByName("debug") {
            // Debug specific settings
            isDebuggable = true
            applicationIdSuffix = ".debug"

            // (optional) If you really want to override the default debug keystore:
            // signingConfig = signingConfigs.getByName("debug") // αν θες ρητά
        }
    }
}

// ✅ ΝΕΟ block – έξω από το android{}, πριν/μετά το flutter{}, όπως προτιμάς.
kotlin {
    // Χρησιμοποιεί JDK 17 εργαλεία
    jvmToolchain(17)

    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// ⬇️⬇️  ΕΔΩ βάζεις τις βιβλιοθήκες για edge-to-edge helpers  ⬇️⬇️
dependencies {
    // ⬇️ ADD this line (the class-based API lives here)
    // ✅ ΑΥΤΟ ΛΕΙΠΕΙ
    // implementation("androidx.activity:activity:1.9.2")  // μόνο αν θες την class-based API ρητά
    // (προαιρετικό αλλά χρήσιμο)
    // ➜ ΝΕΟ: δήλωσε ρητά τη νεότερη ConstraintLayout

    implementation("androidx.activity:activity-ktx:1.11.0")
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
}
