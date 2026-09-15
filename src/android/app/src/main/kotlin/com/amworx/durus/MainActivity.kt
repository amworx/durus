package com.amworx.durus

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app updater: hands a downloaded APK (cache/updates/) to the
        // system package installer via a FileProvider URI.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "durus/installer")
            .setMethodCallHandler { call, result ->
                if (call.method == "installApk") {
                    val path = call.argument<String>("path")
                    val apk = path?.let { File(it) }
                    if (apk == null) {
                        result.error("bad_args", "missing path", null)
                        return@setMethodCallHandler
                    }
                    if (!apk.exists()) {
                        result.error("not_found", "apk not found", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val authority = "$packageName.fileprovider"
                        val uri: Uri = FileProvider.getUriForFile(this, authority, apk)
                        startActivity(
                            Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("install_failed", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}