package com.patrulha.xx

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        // Canal: screenshots / FLAG_SECURE
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/secure")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val enable = call.argument<Boolean>("enable") ?: true
                        if (enable) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal: partilha de ficheiros (share sheet nativo)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        try {
                            val path = call.argument<String>("path") ?: ""
                            val mime = call.argument<String>("type") ?: "*/*"
                            val file = File(path)
                            if (!file.exists()) { result.error("NOT_FOUND", "File not found", null); return@setMethodCallHandler }
                            val uri: Uri = FileProvider.getUriForFile(
                                this,
                                "${applicationContext.packageName}.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mime
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, "Partilhar"))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SHARE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal: device ID + gateway IP (usado pelo TransferService)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/device_id")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidId" -> {
                        val id = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        result.success(id ?: "patrulha")
                    }
                    "getGatewayIp" -> {
                        try {
                            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            val ip = wm.dhcpInfo.gateway
                            if (ip == 0) {
                                result.error("NO_GATEWAY", "Gateway não disponível", null)
                            } else {
                                val gw = String.format(
                                    "%d.%d.%d.%d",
                                    ip and 0xff,
                                    ip shr 8 and 0xff,
                                    ip shr 16 and 0xff,
                                    ip shr 24 and 0xff
                                )
                                result.success(gw)
                            }
                        } catch (e: Exception) {
                            result.error("GATEWAY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
