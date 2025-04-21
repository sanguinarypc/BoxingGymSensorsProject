# flutter_blue_plus 1.35.3
-keep class com.lib.flutter_blue_plus.* { *; }

# Keep your app's classes (adjust the package name as needed)
-keep class com.sanguinarypc.box_sensors2.** { *; }
-dontwarn com.sanguinarypc.box_sensors2.**

# Optionally keep Sentry classes if you use sentry_flutter
-keep class io.sentry.** { *; }

# (Optional) Keep Flutter engine classes if needed (often not required with recent Flutter versions)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**


-keep public class * extends android.app.Service
-keep public class * extends android.app.Activity
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.Application



# Keep Flutter reactive BLE classes (for flutter_reactive_ble)
# -keep class com.lib.flutter_reactive_ble.* { *; }
# -keep class com.signify.hue.** { *; }

# -keep class com.polidea.rxandroidble.** { *; }
# -dontwarn com.polidea.rxandroidble.**
