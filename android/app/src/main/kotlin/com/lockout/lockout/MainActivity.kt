package com.lockout.lockout

import android.content.Intent
import com.lockout.lockout.platform.LockoutPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var platform: LockoutPlatform? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platform = LockoutPlatform(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        platform?.handleNewIntent(intent)
    }

    override fun onDestroy() {
        platform?.dispose()
        platform = null
        super.onDestroy()
    }
}
