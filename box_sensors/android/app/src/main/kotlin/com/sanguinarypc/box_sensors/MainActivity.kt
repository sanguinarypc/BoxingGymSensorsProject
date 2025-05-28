package com.sanguinarypc.box_sensors

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "app.exit.channel"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "minimizeApp" -> {
            moveTaskToBack(true)   // <— just background the Activity
            result.success(null)
          }
          "minimizeAppNoBT" -> {
            finishAffinity() // <— just background the Activity without BT            
            result.success(null)
          }
          "exitApp" -> {
            doExit()               // your existing finishAndRemoveTask()
            result.success(null)
          }
          else -> result.notImplemented()
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



/*
class MainActivity: FlutterActivity() {
  private val CHANNEL = "app.exit.channel"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method == "exitApp") {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          // removes task from Recent Apps as well
          finishAndRemoveTask()
        } else {
          finishAffinity()
        }
        result.success(null)
      } else {
        result.notImplemented()
      }
    }
  }
}

*/ 

// package com.sanguinarypc.box_sensors

// import io.flutter.embedding.android.FlutterActivity

// class MainActivity : FlutterActivity()