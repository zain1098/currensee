package Curren.See

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import Curren.See.HomeWidgetProvider
import Curren.See.WatchlistWidgetProvider
import Curren.See.ConverterWidgetProvider
import Curren.See.MiniChartWidgetProvider
import Curren.See.RedListWidgetProvider


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
                "updateWatchlistWidget" -> {
                    WatchlistWidgetProvider.updateAllWidgets(this)
                    result.success("Watchlist widget updated")
                }
                "updateConverterWidget" -> {
                    ConverterWidgetProvider.updateAllWidgets(this)
                    result.success("Converter widget updated")
                }
                "updateMiniChartWidget" -> {
                    MiniChartWidgetProvider.updateAllWidgets(this)
                    result.success("Mini Chart widget updated")
                }
                "updateRedListWidget" -> {
                    RedListWidgetProvider.updateAllWidgets(this)
                    result.success("Red List widget updated")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
} 