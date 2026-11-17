package com.example.calmattack

import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "calm_attack/wallpaper")
            .setMethodCallHandler { call, result ->
                if (call.method == "openPreview") {
                    result.success(openWallpaperPreview())
                } else {
                    result.notImplemented()
                }
            }
    }

    /** Opens Android's preview screen for the Calm Attack live wallpaper. */
    private fun openWallpaperPreview(): Boolean {
        val preview = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).putExtra(
            WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
            ComponentName(this, CalmWallpaperService::class.java),
        )
        return try {
            startActivity(preview)
            true
        } catch (_: ActivityNotFoundException) {
            // Some phones don't support the direct preview; show the
            // general live wallpaper list instead.
            try {
                startActivity(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
                true
            } catch (_: ActivityNotFoundException) {
                false
            }
        }
    }
}
