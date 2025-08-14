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

class RedListWidgetProvider : AppWidgetProvider() {

    companion object {
        private var lastUpdateTime = 0L
        
        fun updateAllWidgets(context: Context) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastUpdateTime < 1000) {
                println("Skipping redlist widget update - too soon since last update")
                return
            }
            lastUpdateTime = currentTime
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, RedListWidgetProvider::class.java)
            )
            println("Updating ${appWidgetIds.size} redlist widgets")
            for (appWidgetId in appWidgetIds) {
                val provider = RedListWidgetProvider()
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
        
        println("onUpdate called for ${appWidgetIds.size} redlist widgets")
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            println("=== REDLIST WIDGET UPDATE STARTED ===")
            val views = RemoteViews(context.packageName, R.layout.redlist_widget)
            
            // Check internet connectivity
            if (isInternetAvailable(context)) {
                // Fetch latest rates
                FetchRedListRatesTask(context, appWidgetManager, appWidgetId).execute()
            } else {
                // Show offline data
                showOfflineData(context, views)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
            
            // Set click listeners
            setupClickListeners(context, views, appWidgetId)
            
        } catch (e: Exception) {
            println("Error updating redlist widget: $e")
            // Show error state
            val views = RemoteViews(context.packageName, R.layout.redlist_widget)
            showErrorState(context, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun showOfflineData(context: Context, views: RemoteViews) {
        val prefs = context.getSharedPreferences("RedListWidgetPrefs", Context.MODE_PRIVATE)
        val lastUpdated = prefs.getString("redlist_last_updated", "No data") ?: "No data"
        
        // Show cached data
        for (i in 1..6) {
            val country = prefs.getString("country_$i", "") ?: ""
            val rate = prefs.getString("rate_$i", "0.0000") ?: "0.0000"
            
            when (i) {
                1 -> {
                    views.setTextViewText(R.id.country_1, country)
                    views.setTextViewText(R.id.rate_1, rate)
                }
                2 -> {
                    views.setTextViewText(R.id.country_2, country)
                    views.setTextViewText(R.id.rate_2, rate)
                }
                3 -> {
                    views.setTextViewText(R.id.country_3, country)
                    views.setTextViewText(R.id.rate_3, rate)
                }
                4 -> {
                    views.setTextViewText(R.id.country_4, country)
                    views.setTextViewText(R.id.rate_4, rate)
                }
                5 -> {
                    views.setTextViewText(R.id.country_5, country)
                    views.setTextViewText(R.id.rate_5, rate)
                }
                6 -> {
                    views.setTextViewText(R.id.country_6, country)
                    views.setTextViewText(R.id.rate_6, rate)
                }
            }
        }
        
        views.setTextViewText(R.id.last_updated, "Last: $lastUpdated")
        views.setTextViewText(R.id.internet_status, "OFFLINE")
        views.setInt(R.id.internet_status, "setVisibility", View.VISIBLE)
    }

    private fun showErrorState(context: Context, views: RemoteViews) {
        // Show error message
        views.setTextViewText(R.id.last_updated, "Error loading data")
        views.setTextViewText(R.id.internet_status, "ERROR")
        views.setInt(R.id.internet_status, "setVisibility", View.VISIBLE)
        
        // Show default data
        val defaultData = listOf(
            "United States" to "1.0000",
            "Eurozone" to "0.8500",
            "Japan" to "150.25",
            "United Kingdom" to "0.7500",
            "Pakistan" to "280.50",
            "India" to "83.25"
        )
        
        for (i in defaultData.indices) {
            val (country, rate) = defaultData[i]
            when (i) {
                0 -> {
                    views.setTextViewText(R.id.country_1, country)
                    views.setTextViewText(R.id.rate_1, rate)
                }
                1 -> {
                    views.setTextViewText(R.id.country_2, country)
                    views.setTextViewText(R.id.rate_2, rate)
                }
                2 -> {
                    views.setTextViewText(R.id.country_3, country)
                    views.setTextViewText(R.id.rate_3, rate)
                }
                3 -> {
                    views.setTextViewText(R.id.country_4, country)
                    views.setTextViewText(R.id.rate_4, rate)
                }
                4 -> {
                    views.setTextViewText(R.id.country_5, country)
                    views.setTextViewText(R.id.rate_5, rate)
                }
                5 -> {
                    views.setTextViewText(R.id.country_6, country)
                    views.setTextViewText(R.id.rate_6, rate)
                }
            }
        }
    }

    private fun setupClickListeners(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Refresh button click
        val refreshIntent = Intent(context, RedListWidgetProvider::class.java).apply {
            action = "REFRESH_REDLIST"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, appWidgetId, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.redlist_refresh_btn, refreshPendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "REFRESH_REDLIST" -> {
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

    private inner class FetchRedListRatesTask(
        private val context: Context,
        private val appWidgetManager: AppWidgetManager,
        private val appWidgetId: Int
    ) : Thread() {
        
        fun execute() {
            start()
        }
        
        override fun run() {
            try {
                val views = RemoteViews(context.packageName, R.layout.redlist_widget)
                val prefs = context.getSharedPreferences("RedListWidgetPrefs", Context.MODE_PRIVATE)
                val editor = prefs.edit()
                
                // Define currencies to fetch (base currency is USD)
                val currencies = listOf(
                    "EUR" to "Eurozone",
                    "JPY" to "Japan", 
                    "GBP" to "United Kingdom",
                    "PKR" to "Pakistan",
                    "INR" to "India",
                    "CNY" to "China"
                )
                
                val results = mutableListOf<Pair<String, Map<String, Any>>>()
                
                // Try multiple API endpoints for better reliability
                val apiUrls = listOf(
                    "https://open.er-api.com/v6/latest/USD",
                    "https://api.exchangerate-api.com/v4/latest/USD",
                    "https://api.exchangerate.host/latest?base=USD"
                )
                
                var success = false
                for (apiUrl in apiUrls) {
                    try {
                        val result = fetchCurrencyRates(apiUrl, currencies)
                        if (result.isNotEmpty()) {
                            results.addAll(result)
                            success = true
                            break
                        }
                    } catch (e: Exception) {
                        println("Failed to fetch from $apiUrl: $e")
                        continue
                    }
                }
                
                if (!success) {
                    throw Exception("All API endpoints failed")
                }
                
                // Update UI on main thread
                context.mainExecutor.execute {
                    updateWidgetUI(views, results, editor)
                    setupClickListeners(context, views, appWidgetId)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
                
            } catch (e: Exception) {
                println("Error fetching redlist rates: $e")
                context.mainExecutor.execute {
                    val views = RemoteViews(context.packageName, R.layout.redlist_widget)
                    showErrorState(context, views)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            }
        }
        
        private fun fetchCurrencyRates(apiUrl: String, currencies: List<Pair<String, String>>): List<Pair<String, Map<String, Any>>> {
            val results = mutableListOf<Pair<String, Map<String, Any>>>()
            
            try {
                val url = URL(apiUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                connection.setRequestProperty("User-Agent", "CurrenSee-RedList/1.0")
                
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
                    
                    for ((currency, country) in currencies) {
                        try {
                            if (rates.has(currency)) {
                                val rate = rates.getDouble(currency)
                                results.add(Pair(currency, mapOf(
                                    "currency" to currency,
                                    "country" to country,
                                    "rate" to rate,
                                    "lastUpdated" to lastUpdated
                                )))
                            }
                        } catch (e: Exception) {
                            println("Error parsing rate for $currency: $e")
                        }
                    }
                }
            } catch (e: Exception) {
                println("Error fetching rates from $apiUrl: $e")
            }
            
            return results
        }
        
        private fun updateWidgetUI(views: RemoteViews, results: List<Pair<String, Map<String, Any>>>, editor: android.content.SharedPreferences.Editor) {
            val formatter = DecimalFormat("#.####")
            
            // Update with actual data
            for (i in results.indices) {
                val (currency, data) = results[i]
                
                if (data.containsKey("error")) {
                    continue
                }
                
                val country = data["country"] as String
                val rate = data["rate"] as Double
                val lastUpdated = data["lastUpdated"] as String
                
                // Save data for offline use
                editor.putString("country_${i + 1}", country)
                editor.putString("rate_${i + 1}", formatter.format(rate))
                
                // Update UI based on index
                when (i) {
                    0 -> {
                        views.setTextViewText(R.id.country_1, country)
                        views.setTextViewText(R.id.rate_1, formatter.format(rate))
                    }
                    1 -> {
                        views.setTextViewText(R.id.country_2, country)
                        views.setTextViewText(R.id.rate_2, formatter.format(rate))
                    }
                    2 -> {
                        views.setTextViewText(R.id.country_3, country)
                        views.setTextViewText(R.id.rate_3, formatter.format(rate))
                    }
                    3 -> {
                        views.setTextViewText(R.id.country_4, country)
                        views.setTextViewText(R.id.rate_4, formatter.format(rate))
                    }
                    4 -> {
                        views.setTextViewText(R.id.country_5, country)
                        views.setTextViewText(R.id.rate_5, formatter.format(rate))
                    }
                    5 -> {
                        views.setTextViewText(R.id.country_6, country)
                        views.setTextViewText(R.id.rate_6, formatter.format(rate))
                    }
                }
            }
            
            // Update last updated time
            val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            views.setTextViewText(R.id.last_updated, "Updated: $currentTime")
            views.setInt(R.id.internet_status, "setVisibility", View.GONE)
            
            // Save last updated time
            editor.putString("redlist_last_updated", currentTime)
            editor.apply()
            
            println("RedList widget UI updated successfully with ${results.size} currencies")
        }
    }
}
