package com.patrulha.xx

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val ACTION_INSTALL_COMPLETE = "com.patrulha.xx.INSTALL_COMPLETE"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal: FLAG_SECURE
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

        // Canal: partilha de ficheiros
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        try {
                            val path = call.argument<String>("path") ?: ""
                            val mime = call.argument<String>("type") ?: "*/*"
                            val file = File(path)
                            if (!file.exists()) {
                                result.error("NOT_FOUND", "File not found", null)
                                return@setMethodCallHandler
                            }
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

        // Canal: device ID + gateway IP
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/device_id")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "getAndroidId" -> {
                        val id = Settings.Secure.getString(
                            contentResolver, Settings.Secure.ANDROID_ID
                        )
                        result.success(id ?: "patrulha")
                    }
                    "getGatewayIp" -> {
                        try {
                            val gw = getGatewayIp()
                            if (gw != null) result.success(gw)
                            else result.error("NO_GATEWAY", "Gateway não disponível", null)
                        } catch (e: Exception) {
                            result.error("GATEWAY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

                // Canal: auto-update via PackageInstaller Session API
        // Instala o APK sobre si próprio sem diálogo do sistema,
        // desde que o APK novo esteja assinado com o mesmo certificado.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.patrulhaxx/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("INVALID_PATH", "Caminho do APK inválido", null)
                            return@setMethodCallHandler
                        }
                        val file = File(path)
                        if (!file.exists()) {
                            result.error("NOT_FOUND", "APK não encontrado: $path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApkSession(file, result)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApkSession(apkFile: File, result: MethodChannel.Result) {
        val packageInstaller = packageManager.packageInstaller

        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL
        ).apply {
            setAppPackageName(packageName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
            }
        }

        val sessionId = packageInstaller.createSession(params)
        val session = packageInstaller.openSession(sessionId)

        try {
            FileInputStream(apkFile).use { inputStream ->
                session.openWrite("package", 0, apkFile.length()).use { outputStream ->
                    inputStream.copyTo(outputStream, bufferSize = 65536)
                    session.fsync(outputStream)
                }
            }

            val receiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context, intent: Intent) {
                    ctx.unregisterReceiver(this)
                    val status = intent.getIntExtra(
                        PackageInstaller.EXTRA_STATUS,
                        PackageInstaller.STATUS_FAILURE
                    )
                    val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)

                    when (status) {
                        PackageInstaller.STATUS_SUCCESS ->
                            result.success("success")

                        PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                            // Android < 12: precisa de confirmação manual
                            val confirmIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                            if (confirmIntent != null) {
                                confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(confirmIntent)
                                result.success("pending_user_action")
                            } else {
                                result.error("INSTALL_ERROR", "Intent de confirmação nulo", null)
                            }
                        }

                        else ->
                            result.error(
                                "INSTALL_FAILED",
                                msg ?: "Falha na instalação (status=$status)",
                                null
                            )
                    }
                }
            }

            val intentFilter = IntentFilter(ACTION_INSTALL_COMPLETE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, intentFilter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(receiver, intentFilter)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                this,
                sessionId,
                Intent(ACTION_INSTALL_COMPLETE),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            session.commit(pendingIntent.intentSender)

        } catch (e: Exception) {
            session.abandon()
            throw e
        } finally {
            session.close()
        }
    }

    @Suppress("DEPRECATION")
    private fun getGatewayIp(): String? {
        return try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val ip = wm.dhcpInfo?.gateway ?: 0
            if (ip == 0) null
            else String.format(
                "%d.%d.%d.%d",
                ip and 0xff,
                ip shr 8 and 0xff,
                ip shr 16 and 0xff,
                ip shr 24 and 0xff
            )
        } catch (e: Exception) {
            null
        }
    }
}
