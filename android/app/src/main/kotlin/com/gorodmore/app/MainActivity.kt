package com.gorodmore.app

import android.content.Context
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL_NAME = "flutter_method_channel"
        private const val LOG_TAG = "MainActivity"
        private val TOKEN_KEYS = listOf("device_token", "push_token", "fcm_token", "token")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getToken" -> result.success(readCachedToken())
                    else -> result.notImplemented()
                }
            }
    }

    private fun readCachedToken(): String? {
        val sharedPrefsCandidates = listOf(
            getSharedPreferences("m_club_native", Context.MODE_PRIVATE),
            getSharedPreferences("${packageName}_preferences", Context.MODE_PRIVATE),
            getSharedPreferences(packageName, Context.MODE_PRIVATE)
        )

        for (prefs in sharedPrefsCandidates) {
            for (key in TOKEN_KEYS) {
                val token = prefs.getString(key, null)
                if (!token.isNullOrEmpty()) {
                    return token
                }
            }
        }

        Log.w(LOG_TAG, "No cached push token found on Android side")
        return null
    }
}
