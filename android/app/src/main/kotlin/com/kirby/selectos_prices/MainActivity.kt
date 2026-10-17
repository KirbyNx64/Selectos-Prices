package com.kirby.selectos_prices

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kirby.selectos_prices/platform_version",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getPlatformInfo") {
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                result.success(
                    mapOf(
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "appVersion" to packageInfo.versionName,
                        "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
