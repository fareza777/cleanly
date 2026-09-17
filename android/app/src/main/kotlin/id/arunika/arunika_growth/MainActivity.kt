// Package id disamakan dengan aplikasi Arunika yang sudah live di Play Console
// supaya Cleanly dikirim sebagai update dari listing yang sama.
package id.arunika.arunika_growth

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "id.arunika.arunika_growth/device_timezone"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimezone" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
    }
}
