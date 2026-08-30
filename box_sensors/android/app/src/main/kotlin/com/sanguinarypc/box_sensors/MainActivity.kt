// android/app/src/main/kotlin/com/sanguinarypc/box_sensors/MainActivity.kt
package com.sanguinarypc.box_sensors

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.graphics.Color
import android.provider.DocumentsContract
import androidx.annotation.NonNull
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "app.exit.channel"
    private val DATABASE_EXPORT_CHANNEL = "app.database.export.channel"
    private val exportExecutor = Executors.newSingleThreadExecutor()
    private var pendingExportResult: MethodChannel.Result? = null
    private var pendingExportSource: File? = null

    private val createDocumentLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
            val methodResult = pendingExportResult
                ?: return@registerForActivityResult
            val sourceFile = pendingExportSource
            val targetUri = activityResult.data?.data

            if (activityResult.resultCode != Activity.RESULT_OK || targetUri == null) {
                clearPendingExport()
                methodResult.success(null)
                return@registerForActivityResult
            }

            if (sourceFile == null) {
                clearPendingExport()
                methodResult.error(
                    "EXPORT_SOURCE_MISSING",
                    "The temporary database file is unavailable.",
                    null
                )
                return@registerForActivityResult
            }

            exportExecutor.execute {
                streamDatabaseToUri(sourceFile, targetUri, methodResult)
            }
        }

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATABASE_EXPORT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportDatabase" -> startDatabaseExport(
                        call.argument<String>("sourcePath"),
                        call.argument<String>("fileName"),
                        result
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun startDatabaseExport(
        sourcePath: String?,
        fileName: String?,
        result: MethodChannel.Result
    ) {
        if (pendingExportResult != null) {
            result.error("EXPORT_IN_PROGRESS", "A database export is already in progress.", null)
            return
        }

        if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
            result.error("INVALID_EXPORT_ARGUMENTS", "Export path or file name is missing.", null)
            return
        }

        val sourceFile = File(sourcePath)
        if (!sourceFile.isFile || !sourceFile.canRead()) {
            result.error(
                "EXPORT_SOURCE_MISSING",
                "The temporary database file cannot be read.",
                null
            )
            return
        }

        pendingExportResult = result
        pendingExportSource = sourceFile

        val createDocumentIntent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        try {
            createDocumentLauncher.launch(createDocumentIntent)
        } catch (error: Exception) {
            clearPendingExport()
            result.error("EXPORT_PICKER_FAILED", error.message, null)
        }
    }

    private fun streamDatabaseToUri(
        sourceFile: File,
        targetUri: Uri,
        result: MethodChannel.Result
    ) {
        try {
            FileInputStream(sourceFile).use { input ->
                val output = contentResolver.openOutputStream(targetUri, "w")
                    ?: throw IOException("Unable to open the selected destination.")

                output.use {
                    val buffer = ByteArray(EXPORT_BUFFER_SIZE)
                    while (true) {
                        val bytesRead = input.read(buffer)
                        if (bytesRead < 0) break
                        it.write(buffer, 0, bytesRead)
                    }
                    it.flush()
                }
            }

            runOnUiThread {
                clearPendingExport()
                result.success(targetUri.toString())
            }
        } catch (error: Exception) {
            try {
                DocumentsContract.deleteDocument(contentResolver, targetUri)
            } catch (_: Exception) {
                // Some document providers do not allow deletion of a partial file.
            }

            runOnUiThread {
                clearPendingExport()
                result.error("EXPORT_WRITE_FAILED", error.message, null)
            }
        }
    }

    private fun clearPendingExport() {
        pendingExportResult = null
        pendingExportSource = null
    }

    private fun doExit() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finishAffinity()
        }
    }

    companion object {
        private const val EXPORT_BUFFER_SIZE = 64 * 1024
    }
}
