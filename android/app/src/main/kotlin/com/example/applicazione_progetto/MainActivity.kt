package com.example.buzzed_buddy

import android.content.Intent
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "buzzedbuddy/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendSmsViaDefaultApp") {
                    val number = call.argument<String>("number") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    try {
                        // Intento SMS verso un numero, con il testo già pronto.
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number"))
                        intent.putExtra("sms_body", body)
                        // Lo puntiamo ESPLICITAMENTE all'app SMS predefinita:
                        // così Android non mostra alcun selettore (niente WhatsApp).
                        val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(this)
                        if (defaultSmsPackage != null) {
                            intent.setPackage(defaultSmsPackage)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
