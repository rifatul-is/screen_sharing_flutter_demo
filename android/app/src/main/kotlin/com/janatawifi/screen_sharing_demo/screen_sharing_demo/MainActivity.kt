package com.janatawifi.screen_sharing_demo.screen_sharing_demo

import ScreenSharingService
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.com.janatawifi.screen_sharing_demo.screen_sharing_demo/services"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "startScreenCaptureService") {
                Log.d("TAG", "configureFlutterEngine: method called")
                val intent = Intent(this, ScreenCaptureService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Log.d("TAG", "configureFlutterEngine: Grater then o")
                    startForegroundService(intent)
                    //ContextCompat.startForegroundService(this, intent);
                    Log.d("TAG", "configureFlutterEngine: startForegroundService executed")
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
