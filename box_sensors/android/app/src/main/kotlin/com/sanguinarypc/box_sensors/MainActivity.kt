// android/app/src/main/kotlin/com/sanguinarypc/box_sensors/MainActivity.kt
package com.sanguinarypc.box_sensors

import android.os.Build
import android.os.Bundle
import android.graphics.Color
import androidx.annotation.NonNull
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "app.exit.channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Edge-to-edge χωρίς deprecated set*Color calls.
        // Το SystemBarStyle.auto διαλέγει μόνο του light/dark icons
        // και κάνει διάφανες τις μπάρες (χωρίς να «βάφουμε» με παλιό API).
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(
                /* lightScrim = */ Color.TRANSPARENT,
                /* darkScrim  = */ Color.TRANSPARENT
            ),
            navigationBarStyle = SystemBarStyle.auto(
                /* lightScrim = */ Color.TRANSPARENT,
                /* darkScrim  = */ Color.TRANSPARENT
            )
        )
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "minimizeApp"     -> { moveTaskToBack(true); result.success(null) }
                    "minimizeAppNoBT" -> { finishAffinity();      result.success(null) }
                    "exitApp"         -> { doExit();              result.success(null) }
                    else              -> result.notImplemented()
                }
            }
    }

    private fun doExit() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finishAffinity()
        }
    }
}