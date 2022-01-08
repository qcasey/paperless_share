package com.quinncasey.paperless_share

import android.content.ContentResolver
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream


private const val CHANNEL = "app.channel.shared.data"
private const val LOG_TAG = "MAIN_ACTIVITY"

class MainActivity : FlutterActivity() {
    var tmpFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleFileViewIntent()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                    if (call.method!!.contentEquals("getFilePath")) {
                        result.success(tmpFilePath)
                        tmpFilePath = null
                    }
                }
    }

    private fun handleFileViewIntent() {
        if (Intent.ACTION_VIEW == intent.action && intent.type != null) {
            tmpFilePath = handleSendText(intent)
        }
    }


    private fun handleSendText(intent: Intent): String? {
        val fileName = when (intent.scheme) {
            ContentResolver.SCHEME_CONTENT -> getContentName(intent.data!!)
            ContentResolver.SCHEME_FILE -> intent.data!!.lastPathSegment
            else -> null
        }
        return fileName?.let {
            val stream = contentResolver.openInputStream(intent.data!!)!!
            val cacheDir = context.cacheDir
            val tempFile = File(cacheDir, it)
            writeStreamToFile(tempFile, stream)
            tempFile.absolutePath
        }
    }

    private fun writeStreamToFile(tempFile: File, stream: InputStream) {
        val out = FileOutputStream(tempFile)

        try {
            val buffer = ByteArray(8 * 1024)
            var bytesRead: Int
            while (stream.read(buffer).also { bytesRead = it } != -1) {
                out.write(buffer, 0, bytesRead)
            }

        } catch (ex: Exception) {
            Log.e(LOG_TAG, "Error writing or reading file from intent", ex)
        }
    }

    private fun getContentName(uri: Uri): String? {
        val cursor: Cursor? = contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)!!
        if (cursor != null) {
            cursor.moveToFirst()
            val nameIndex: Int = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
            if (nameIndex >= 0) {
                val result = cursor.getString(nameIndex)
                cursor.close()
                return result
            }
            cursor.close()
        }
        return null
    }
}
