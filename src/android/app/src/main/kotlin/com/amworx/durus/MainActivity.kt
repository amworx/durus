package com.amworx.durus

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app updater channel:
        //   getDownloadDir()     -> app-private cache/updates path (FileProvider
        //                           <cache-path> covered; writing to Directory.systemTemp
        //                           is unreliable across devices and NOT covered).
        //   installApk(path)     -> try FileProvider ACTION_VIEW install; on failure
        //                           export to a user-visible Downloads location and
        //                           return where it went.
        //   openDownloadsFolder() -> open the system Files/Downloads app so the user
        //                           can find an exported APK manually.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "durus/installer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDownloadDir" -> {
                        try {
                            val dir = File(cacheDir, "updates")
                            if (!dir.exists()) dir.mkdirs()
                            result.success(dir.absolutePath)
                        } catch (e: Exception) {
                            result.error("dir_failed", e.message, null)
                        }
                    }

                    "installApk" -> {
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
                        // Primary: hand the cached APK to the package installer via
                        // a FileProvider URI (works because cache/updates is inside
                        // the FileProvider <cache-path>).
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
                            result.success(mapOf("status" to "installed"))
                        } catch (e: Exception) {
                            // Fallback: copy the APK somewhere the user can reach and
                            // tell them where (the app cache is invisible to file
                            // managers — the original bug).
                            try {
                                val displayName = apk.name
                                val destInfo = exportApkToDownloads(apk, displayName)
                                result.success(
                                    mapOf(
                                        "status" to "exported",
                                        "displayName" to displayName,
                                        "message" to destInfo,
                                    )
                                )
                            } catch (e2: Exception) {
                                result.success(
                                    mapOf(
                                        "status" to "failed",
                                        "message" to e2.message,
                                    )
                                )
                            }
                        }
                    }

                    "openDownloadsFolder" -> {
                        try {
                            // Opens the Downloads collection (or internal storage root
                            // on older devices) in the system Files/Downloads app.
                            val uri =
                                if (Build.VERSION.SDK_INT >= 29) {
                                    Uri.parse("content://com.android.externalstorage.documents/root/downloads")
                                } else {
                                    Uri.parse("content://com.android.externalstorage.documents/root/primary")
                                }
                            startActivity(
                                Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "vnd.android.document/directory")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_failed", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /// Copies [apk] to a user-visible Downloads location. On Android 10+ the
    /// file lands in the real "Downloads" collection (visible in Files/Downloads);
    /// on older devices it goes to the app's external Download dir (browsable by
    /// file managers on those versions). Returns a short human-readable location.
    private fun exportApkToDownloads(apk: File, displayName: String): String {
        if (Build.VERSION.SDK_INT >= 29) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                put(MediaStore.Downloads.MIME_TYPE, "application/vnd.android.package-archive")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values)
                ?: throw Exception("MediaStore insert failed")
            resolver.openOutputStream(uri)?.use { out ->
                apk.inputStream().use { it.copyTo(out) }
            } ?: throw Exception("MediaStore write failed")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Downloads/$displayName"
        }
        val extDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw Exception("no external dir")
        val dest = File(extDir, displayName)
        apk.copyTo(dest, overwrite = true)
        return "${Environment.DIRECTORY_DOWNLOADS}/$displayName"
    }
}