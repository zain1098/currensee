package Curren.See

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import Curren.See.HomeWidgetProvider


class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "currensee_widget_channel"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    HomeWidgetProvider.updateAllWidgets(this)
                    result.success("Widget updated")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
} 