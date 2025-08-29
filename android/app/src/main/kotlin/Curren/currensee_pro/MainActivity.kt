package Curren.currensee_pro

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
// import Curren.currensee_pro.HomeWidgetProvider
// import Curren.currensee_pro.WatchlistWidgetProvider
// import Curren.currensee_pro.ConverterWidgetProvider
// import Curren.currensee_pro.RedListWidgetProvider


class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "currensee_widget_channel"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // HomeWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "updateWatchlistWidget" -> {
                    // WatchlistWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "updateConverterWidget" -> {
                    // ConverterWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "updateRedListWidget" -> {
                    // RedListWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
