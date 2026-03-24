package com.pickcab.partner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.*
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {

    private val CHANNEL = "otp_retriever"
    private var smsReceiver: BroadcastReceiver? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSmsListener" -> {
                    startSmsRetriever()
                    result.success(true)
                }
                "getAppHash" -> {
                    result.success(getAppHash())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    // ==========================
    // 🔥 GENERATE APP HASH
    // ==========================

   private fun getAppHash(): String? {
    return try {

        val packageName = applicationContext.packageName

        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES
            )
        } else {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
        }

        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.signingInfo?.apkContentsSigners
        } else {
            packageInfo.signatures
        }

        if (signatures.isNullOrEmpty()) {
            return null
        }

        val signature = signatures[0]

        val appInfo = "$packageName ${signature.toCharsString()}"

        val messageDigest = MessageDigest.getInstance("SHA-256")
        messageDigest.update(appInfo.toByteArray())

        android.util.Base64.encodeToString(
            messageDigest.digest(),
            android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
        ).substring(0, 11)

    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

    // ==========================
    // OTP RETRIEVER
    // ==========================

    private fun startSmsRetriever() {
        try {
            val client = SmsRetriever.getClient(this)
            val task = client.startSmsRetriever()

            task.addOnSuccessListener {
                registerSmsReceiver()
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun registerSmsReceiver() {

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {

                if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {

                    val extras = intent.extras
                    val status = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

                    when (status?.statusCode) {

                        CommonStatusCodes.SUCCESS -> {
                            val message =
                                extras.get(SmsRetriever.EXTRA_SMS_MESSAGE) as? String

                            message?.let { extractAndSendOtp(it) }
                        }

                        CommonStatusCodes.TIMEOUT -> {
                            startSmsRetriever()
                        }
                    }
                }
            }
        }

        val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(smsReceiver, filter)
        }
    }

    private fun extractAndSendOtp(message: String) {

        val pattern = Pattern.compile("(\\d{6})")
        val matcher = pattern.matcher(message)

        if (matcher.find()) {
            val otp = matcher.group(0)
            channel?.invokeMethod("onOtpReceived", otp)
        }
    }

    // ==========================
    // NOTIFICATION CHANNELS
    // ==========================

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val rideChannel = NotificationChannel(
                "pickcab-partners",
                "Ride Alerts",
                NotificationManager.IMPORTANCE_HIGH
            )

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            notificationManager.createNotificationChannel(rideChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            smsReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
