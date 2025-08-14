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

class ConverterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateConverterWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateConverterWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.converter_widget)
        val prefs = context.getSharedPreferences("ConverterWidgetPrefs", Context.MODE_PRIVATE)
        
        // Get user's currency pair (default to USD/PKR)
        val fromCurrency = prefs.getString("converter_from_currency", "USD") ?: "USD"
        val toCurrency = prefs.getString("converter_to_currency", "PKR") ?: "PKR"
        
        // Initialize default values if first time
        initializeDefaultConverterValues(prefs)
        
        // Check internet connectivity
        if (isInternetAvailable(context)) {
            // Fetch real-time data
            FetchConverterDataTask(context, appWidgetManager, appWidgetId, views, prefs).start()
        } else {
            // Show offline data
            showOfflineData(context, views, prefs)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        // Setup click listeners for currency selection
        setupClickListeners(context, views, appWidgetId)
    }

    private fun showOfflineData(context: Context, views: RemoteViews, prefs: android.content.SharedPreferences) {
        val fromCurrency = prefs.getString("converter_from_currency", "USD") ?: "USD"
        val toCurrency = prefs.getString("converter_to_currency", "PKR") ?: "PKR"
        val lastUpdated = prefs.getString("converter_last_updated", "No data") ?: "No data"
        val lastRate = prefs.getString("converter_last_rate", "280.50") ?: "280.50"
        
        // Update UI with last known data
        views.setTextViewText(R.id.source_currency, fromCurrency)
        views.setTextViewText(R.id.target_currency, toCurrency)
        views.setTextViewText(R.id.target_amount, lastRate)
        views.setTextViewText(R.id.exchange_rate, prefs.getString("converter_rate", "1 $fromCurrency = $lastRate $toCurrency") ?: "1 $fromCurrency = $lastRate $toCurrency")
        views.setTextViewText(R.id.last_updated, "Last: $lastUpdated")
        views.setTextViewText(R.id.internet_status, "OFFLINE")
        views.setInt(R.id.internet_status, "setVisibility", View.VISIBLE)
    }

    private fun initializeDefaultConverterValues(prefs: android.content.SharedPreferences) {
        // Set default values for first time
        if (!prefs.contains("converter_from_currency")) {
            prefs.edit()
                .putString("converter_from_currency", "USD")
                .putString("converter_to_currency", "PKR")
                .putFloat("USD_PKR_previous", 280.50f)
                .putString("converter_rate", "1 USD = 280.50 PKR")
                .putString("converter_last_updated", "Just now")
                .apply()
            println("Initialized default converter values")
        }
    }

    private fun setupClickListeners(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Currency change button click
        val changeIntent = Intent(context, ConverterWidgetProvider::class.java).apply {
            action = "CHANGE_CURRENCIES"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val changePendingIntent = PendingIntent.getBroadcast(
            context, appWidgetId, changeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Set click listener for currency change button only
        views.setOnClickPendingIntent(R.id.change_currencies_btn, changePendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "REFRESH_CONVERTER" -> {
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    updateConverterWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "CHANGE_CURRENCIES" -> {
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    changeCurrencies(context, appWidgetId)
                }
            }
        }
    }

    private fun changeCurrencies(context: Context, appWidgetId: Int) {
        val prefs = context.getSharedPreferences("ConverterWidgetPrefs", Context.MODE_PRIVATE)
        val currentFrom = prefs.getString("converter_from_currency", "USD") ?: "USD"
        val currentTo = prefs.getString("converter_to_currency", "PKR") ?: "PKR"
        
        // Cycle through popular currency pairs
        val currencyPairs = listOf(
            "USD" to "PKR",
            "EUR" to "PKR", 
            "GBP" to "PKR",
            "USD" to "EUR",
            "EUR" to "USD",
            "USD" to "GBP",
            "GBP" to "USD"
        )
        
        // Find current pair and move to next
        val currentIndex = currencyPairs.indexOfFirst { it.first == currentFrom && it.second == currentTo }
        val nextIndex = (currentIndex + 1) % currencyPairs.size
        val (newFrom, newTo) = currencyPairs[nextIndex]
        
        // Save new currencies
        prefs.edit()
            .putString("converter_from_currency", newFrom)
            .putString("converter_to_currency", newTo)
            .apply()
        
        println("Changed currencies from $currentFrom/$currentTo to $newFrom/$newTo")
        
        // Update widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        updateConverterWidget(context, appWidgetManager, appWidgetId)
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

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, ConverterWidgetProvider::class.java)
            )
            if (appWidgetIds.isNotEmpty()) {
                val intent = Intent(context, ConverterWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    private inner class FetchConverterDataTask(
        private val context: Context,
        private val appWidgetManager: AppWidgetManager,
        private val appWidgetId: Int,
        private val views: RemoteViews,
        private val prefs: android.content.SharedPreferences
    ) : Thread() {

        override fun run() {
            try {
                val fromCurrency = prefs.getString("converter_from_currency", "USD") ?: "USD"
                val toCurrency = prefs.getString("converter_to_currency", "PKR") ?: "PKR"
                
                val result = fetchCurrencyRate(fromCurrency, toCurrency)
                
                // Update UI on main thread
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    updateConverterUI(views, result, prefs)
                    setupClickListeners(context, views, appWidgetId)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
                
            } catch (e: Exception) {
                e.printStackTrace()
                // Show error state
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    showOfflineData(context, views, prefs)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            }
        }

        private fun fetchCurrencyRate(from: String, to: String): Map<String, Any> {
            val url = URL("https://api.exchangerate-api.com/v4/latest/$from")
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "GET"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            return try {
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
                    val rates = jsonResponse.getJSONObject("rates")
                    val rate = rates.getDouble(to)
                    
                    // Get previous rate for comparison
                    val previousRate = prefs.getFloat("${from}_${to}_previous", rate.toFloat()).toDouble()
                    
                    // Calculate change percentage
                    val change = ((rate - previousRate) / previousRate) * 100
                    
                    mapOf(
                        "current" to rate,
                        "previous" to previousRate,
                        "change" to change,
                        "lastUpdated" to SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
                    )
                } else {
                    mapOf("error" to "HTTP $responseCode")
                }
            } finally {
                connection.disconnect()
            }
        }

        private fun updateConverterUI(views: RemoteViews, result: Map<String, Any>, prefs: android.content.SharedPreferences) {
            if (result.containsKey("error")) {
                showOfflineData(context, views, prefs)
                return
            }
            
            val fromCurrency = prefs.getString("converter_from_currency", "USD") ?: "USD"
            val toCurrency = prefs.getString("converter_to_currency", "PKR") ?: "PKR"
            val currentRate = result["current"] as Double
            val previousRate = result["previous"] as Double
            val change = result["change"] as Double
            val lastUpdated = result["lastUpdated"] as String
            
            val formatter = DecimalFormat("#.####")
            val changeFormatter = DecimalFormat("+#.##%;-#.##%")
            
            // Update UI with new layout
            views.setTextViewText(R.id.source_currency, fromCurrency)
            views.setTextViewText(R.id.target_currency, toCurrency)
            views.setTextViewText(R.id.target_amount, formatter.format(currentRate))
            views.setTextViewText(R.id.exchange_rate, "1 $fromCurrency = ${formatter.format(currentRate)} $toCurrency")
            views.setTextViewText(R.id.last_updated, "Updated: $lastUpdated")
            views.setInt(R.id.internet_status, "setVisibility", View.GONE)
            
            // Save data for offline use
            val editor = prefs.edit()
            editor.putFloat("${fromCurrency}_${toCurrency}_previous", currentRate.toFloat())
            editor.putString("converter_rate", "1 $fromCurrency = ${formatter.format(currentRate)} $toCurrency")
            editor.putString("converter_last_updated", lastUpdated)
            editor.apply()
        }
    }
}
