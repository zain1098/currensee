package Curren.See

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.view.View
import android.widget.RemoteViews
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONObject

class MiniChartWidgetProvider : AppWidgetProvider() {

    companion object {
        private var lastUpdateTime = 0L
        
        fun updateAllWidgets(context: Context) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastUpdateTime < 1000) {
                println("Skipping minichart widget update - too soon since last update")
                return
            }
            lastUpdateTime = currentTime
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, MiniChartWidgetProvider::class.java)
            )
            println("Updating ${appWidgetIds.size} minichart widgets")
            for (appWidgetId in appWidgetIds) {
                val provider = MiniChartWidgetProvider()
                provider.updateWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastUpdateTime < 1000) {
            println("Skipping onUpdate - too soon since last update")
            return
        }
        lastUpdateTime = currentTime
        
        println("onUpdate called for ${appWidgetIds.size} minichart widgets")
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            println("=== MINI CHART WIDGET UPDATE STARTED ===")
            val views = RemoteViews(context.packageName, R.layout.mini_chart_widget)
            
            // Check internet connectivity
            if (isInternetAvailable(context)) {
                // Fetch latest rates and chart data
                FetchMiniChartDataTask(context, appWidgetManager, appWidgetId).execute()
            } else {
                // Show offline data
                showOfflineData(context, views)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
            
        } catch (e: Exception) {
            println("Error updating minichart widget: $e")
            // Show error state
            val views = RemoteViews(context.packageName, R.layout.mini_chart_widget)
            showErrorState(context, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun showOfflineData(context: Context, views: RemoteViews) {
        val prefs = context.getSharedPreferences("MiniChartWidgetPrefs", Context.MODE_PRIVATE)
        val lastUpdated = prefs.getString("minichart_last_updated", "No data") ?: "No data"
        val lastRate = prefs.getString("minichart_last_rate", "276.50") ?: "276.50"
        val lastChange = prefs.getString("minichart_last_change", "+0.42%") ?: "+0.42%"
        
        // Show cached data
        views.setTextViewText(R.id.current_rate_top, lastRate)
        views.setTextViewText(R.id.current_rate_bottom, lastRate)
        views.setTextViewText(R.id.percentage_change, lastChange)
        views.setTextViewText(R.id.last_updated, "Last: $lastUpdated")
    }

    private fun showErrorState(context: Context, views: RemoteViews) {
        // Show error message
        views.setTextViewText(R.id.last_updated, "Error loading data")
        
        // Show default data
        views.setTextViewText(R.id.current_rate_top, "276.50")
        views.setTextViewText(R.id.current_rate_bottom, "276.50")
        views.setTextViewText(R.id.percentage_change, "+0.42%")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "REFRESH_MINICHART" -> {
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }

    private fun isInternetAvailable(context: Context): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val activeNetwork = connectivityManager.getNetworkCapabilities(network) ?: return false
        
        return when {
            activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> true
            activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> true
            else -> false
        }
    }

    private inner class FetchMiniChartDataTask(
        private val context: Context,
        private val appWidgetManager: AppWidgetManager,
        private val appWidgetId: Int
    ) : Thread() {
        
        fun execute() {
            start()
        }
        
        override fun run() {
            try {
                val views = RemoteViews(context.packageName, R.layout.mini_chart_widget)
                val prefs = context.getSharedPreferences("MiniChartWidgetPrefs", Context.MODE_PRIVATE)
                val editor = prefs.edit()
                
                // Try multiple API endpoints for better reliability
                val apiUrls = listOf(
                    "https://open.er-api.com/v6/latest/USD",
                    "https://api.exchangerate-api.com/v4/latest/USD",
                    "https://api.exchangerate.host/latest?base=USD"
                )
                
                var result: Map<String, Any>? = null
                for (apiUrl in apiUrls) {
                    try {
                        result = fetchCurrentRate(apiUrl)
                        if (!result.containsKey("error")) {
                            break
                        }
                    } catch (e: Exception) {
                        println("Failed to fetch from $apiUrl: $e")
                        continue
                    }
                }
                
                if (result == null || result.containsKey("error")) {
                    throw Exception("All API endpoints failed")
                }
                
                // Generate chart data points
                val chartData = generateChartData(result["currentRate"] as Double)
                
                // Update UI on main thread
                context.mainExecutor.execute {
                    updateWidgetUI(views, result, chartData, editor)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
                
            } catch (e: Exception) {
                println("Error fetching minichart data: $e")
                context.mainExecutor.execute {
                    val views = RemoteViews(context.packageName, R.layout.mini_chart_widget)
                    showErrorState(context, views)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            }
        }
        
        private fun fetchCurrentRate(apiUrl: String): Map<String, Any> {
            try {
                val url = URL(apiUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                connection.setRequestProperty("User-Agent", "CurrenSee-MiniChart/1.0")
                
                val responseCode = connection.responseCode
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val reader = BufferedReader(InputStreamReader(connection.inputStream))
                    val response = StringBuilder()
                    var line: String?
                    
                    while (reader.readLine().also { line = it } != null) {
                        response.append(line)
                    }
                    reader.close()
                    
                    val jsonResponse = JSONObject(response.toString())
                    
                    // Handle different API response formats
                    val rates = when {
                        jsonResponse.has("rates") -> jsonResponse.getJSONObject("rates")
                        jsonResponse.has("conversion_rates") -> jsonResponse.getJSONObject("conversion_rates")
                        else -> throw Exception("Invalid API response format")
                    }
                    
                    val lastUpdated = when {
                        jsonResponse.has("date") -> jsonResponse.getString("date")
                        jsonResponse.has("time_last_update_utc") -> jsonResponse.getString("time_last_update_utc")
                        else -> SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                    }
                    
                    val currentRate = rates.getDouble("PKR")
                    
                    // Get previous rate for percentage calculation
                    val prefs = context.getSharedPreferences("MiniChartWidgetPrefs", Context.MODE_PRIVATE)
                    val previousRate = prefs.getFloat("minichart_previous_rate", currentRate.toFloat()).toDouble()
                    val percentageChange = ((currentRate - previousRate) / previousRate) * 100
                    
                    return mapOf(
                        "currentRate" to currentRate,
                        "previousRate" to previousRate,
                        "percentageChange" to percentageChange,
                        "lastUpdated" to lastUpdated
                    )
                }
            } catch (e: Exception) {
                println("Error fetching rate from $apiUrl: $e")
            }
            
            return mapOf("error" to "Failed to fetch rate")
        }
        
        private fun generateChartData(currentRate: Double): List<Double> {
            // Generate 5 data points for the chart with realistic variations
            val baseRate = currentRate
            val variation = baseRate * 0.015 // 1.5% variation
            
            return listOf(
                baseRate - variation * 0.3,  // Point 1: Slightly lower
                baseRate - variation * 0.1,  // Point 2: Lower
                baseRate - variation * 0.6,  // Point 3: Dip (red point)
                baseRate + variation * 0.2,  // Point 4: Higher
                baseRate + variation * 0.4   // Point 5: Highest
            )
        }
        
        private fun updateWidgetUI(views: RemoteViews, result: Map<String, Any>, chartData: List<Double>, editor: android.content.SharedPreferences.Editor) {
            if (result.containsKey("error")) {
                showErrorState(context, views)
                return
            }
            
            val currentRate = result["currentRate"] as Double
            val percentageChange = result["percentageChange"] as Double
            val lastUpdated = result["lastUpdated"] as String
            
            val formatter = DecimalFormat("#.##")
            val changeFormatter = DecimalFormat("+#.##%;-#.##%")
            
            // Update rates
            val formattedRate = formatter.format(currentRate)
            views.setTextViewText(R.id.current_rate_top, formattedRate)
            views.setTextViewText(R.id.current_rate_bottom, formattedRate)
            
            // Update percentage change
            val formattedChange = changeFormatter.format(percentageChange / 100)
            views.setTextViewText(R.id.percentage_change, formattedChange)
            
            // Update last updated time
            val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            views.setTextViewText(R.id.last_updated, "Updated: $currentTime")
            
            // Save data for offline use
            editor.putFloat("minichart_previous_rate", currentRate.toFloat())
            editor.putString("minichart_last_rate", formattedRate)
            editor.putString("minichart_last_change", formattedChange)
            editor.putString("minichart_last_updated", currentTime)
            editor.apply()
            
            println("MiniChart widget UI updated successfully")
            println("Current Rate: $formattedRate")
            println("Percentage Change: $formattedChange")
            println("Chart Data Points: $chartData")
        }
    }
}
