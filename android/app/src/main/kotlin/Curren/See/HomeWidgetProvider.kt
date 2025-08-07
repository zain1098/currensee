package Curren.See

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.content.ComponentName
import android.widget.Toast
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.view.View
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.text.DecimalFormat
import java.util.*

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    internal fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.home_widget)
            
            // Get stored data from SharedPreferences
            val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
            val amount = prefs.getString("widget_amount", "1.00") ?: "1.00"
            val fromCode = prefs.getString("widget_fromCode", "USD") ?: "USD"
            val toCode = prefs.getString("widget_toCode", "PKR") ?: "PKR"
            val result = prefs.getString("widget_result", "0.00") ?: "0.00"
            val rateInfo = prefs.getString("widget_rate_info", "1 USD = 0.00 PKR") ?: "1 USD = 0.00 PKR"
            val lastUpdated = prefs.getString("widget_last_updated", "Just now") ?: "Just now"
            
            // Get currency symbols and flags
            val fromSymbol = getCurrencySymbol(fromCode)
            val toSymbol = getCurrencySymbol(toCode)
            val fromFlag = getCurrencyFlag(fromCode)
            val toFlag = getCurrencyFlag(toCode)
            
            // Update widget views with error handling
            try {
                views.setTextViewText(R.id.widget_amount_input, amount)
                views.setTextViewText(R.id.widget_currency_symbol, fromSymbol)
                views.setTextViewText(R.id.widget_from_currency, fromCode)
                views.setTextViewText(R.id.widget_to_currency, toCode)
                views.setTextViewText(R.id.widget_from_flag, fromFlag)
                views.setTextViewText(R.id.widget_to_flag, toFlag)
                views.setTextViewText(R.id.widget_result, "$result $toCode")
                views.setTextViewText(R.id.widget_rate_info, rateInfo)
                views.setTextViewText(R.id.widget_last_updated, "Updated: $lastUpdated")
                
                // Show/hide keypad based on preference
                val isKeypadVisible = prefs.getBoolean("keypad_visible", false)
                views.setInt(R.id.widget_keypad, "setVisibility", if (isKeypadVisible) View.VISIBLE else View.GONE)
                
                // Set click listeners for interactive elements
                setupClickListeners(context, views)
                
                // Update widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
                
                // Fetch latest exchange rate if internet is available
                if (isInternetAvailable(context)) {
                    FetchExchangeRateTask(context, appWidgetManager, appWidgetId).execute(fromCode, toCode, amount)
                } else {
                    // Show offline message
                    views.setTextViewText(R.id.widget_result, "No Internet")
                    views.setTextViewText(R.id.widget_rate_info, "Check connection")
                    views.setTextViewText(R.id.widget_last_updated, "Updated: Offline")
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            } catch (e: Exception) {
                // If there's an error with specific views, show a simple widget
                val simpleViews = RemoteViews(context.packageName, R.layout.home_widget)
                simpleViews.setTextViewText(R.id.widget_amount_input, "1.00")
                simpleViews.setTextViewText(R.id.widget_currency_symbol, "$")
                simpleViews.setTextViewText(R.id.widget_from_currency, "USD")
                simpleViews.setTextViewText(R.id.widget_to_currency, "PKR")
                simpleViews.setTextViewText(R.id.widget_from_flag, "🇺🇸")
                simpleViews.setTextViewText(R.id.widget_to_flag, "🇵🇰")
                simpleViews.setTextViewText(R.id.widget_result, "0.00 PKR")
                simpleViews.setTextViewText(R.id.widget_rate_info, "1 USD = 0.00 PKR")
                simpleViews.setTextViewText(R.id.widget_last_updated, "Updated: Just now")
                appWidgetManager.updateAppWidget(appWidgetId, simpleViews)
            }
        } catch (e: Exception) {
            // If there's a complete failure, try to show a basic widget
            try {
                val basicViews = RemoteViews(context.packageName, R.layout.home_widget)
                basicViews.setTextViewText(R.id.widget_amount_input, "1.00")
                basicViews.setTextViewText(R.id.widget_currency_symbol, "$")
                basicViews.setTextViewText(R.id.widget_from_currency, "USD")
                basicViews.setTextViewText(R.id.widget_to_currency, "PKR")
                basicViews.setTextViewText(R.id.widget_from_flag, "🇺🇸")
                basicViews.setTextViewText(R.id.widget_to_flag, "🇵🇰")
                basicViews.setTextViewText(R.id.widget_result, "0.00 PKR")
                basicViews.setTextViewText(R.id.widget_rate_info, "1 USD = 0.00 PKR")
                basicViews.setTextViewText(R.id.widget_last_updated, "Updated: Just now")
                appWidgetManager.updateAppWidget(appWidgetId, basicViews)
            } catch (finalException: Exception) {
                // If even the basic widget fails, log the error
                println("Widget update failed completely: ${finalException.message}")
            }
        }
    }

    private fun setupClickListeners(context: Context, views: RemoteViews) {
        // Set click listener for amount input to show keypad
        val amountIntent = Intent(context, HomeWidgetProvider::class.java)
        amountIntent.action = "SHOW_KEYPAD"
        val amountPendingIntent = PendingIntent.getBroadcast(
            context, 1, amountIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_amount_input, amountPendingIntent)
        
        // Set click listener for refresh button
        val refreshIntent = Intent(context, HomeWidgetProvider::class.java)
        refreshIntent.action = "REFRESH_WIDGET"
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, 5, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_refresh_btn, refreshPendingIntent)
        
        // Set click listeners for keypad buttons
        setupKeypadListeners(context, views)
        
        // Set click listener for swap functionality
        val swapIntent = Intent(context, HomeWidgetProvider::class.java)
        swapIntent.action = "SWAP_CURRENCIES"
        val swapPendingIntent = PendingIntent.getBroadcast(
            context, 2, swapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_swap_arrow, swapPendingIntent)
        
        // Set click listener for currency selection (from currency area)
        val fromCurrencyIntent = Intent(context, HomeWidgetProvider::class.java)
        fromCurrencyIntent.action = "CHANGE_FROM_CURRENCY"
        val fromCurrencyPendingIntent = PendingIntent.getBroadcast(
            context, 3, fromCurrencyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_from_currency_container, fromCurrencyPendingIntent)
        
        // Set click listener for currency selection (to currency area)
        val toCurrencyIntent = Intent(context, HomeWidgetProvider::class.java)
        toCurrencyIntent.action = "CHANGE_TO_CURRENCY"
        val toCurrencyPendingIntent = PendingIntent.getBroadcast(
            context, 4, toCurrencyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_to_currency_container, toCurrencyPendingIntent)
    }
    
    private fun setupKeypadListeners(context: Context, views: RemoteViews) {
        // Setup keypad button listeners
        val keypadActions = mapOf(
            R.id.btn_1 to "KEYPAD_1",
            R.id.btn_2 to "KEYPAD_2", 
            R.id.btn_3 to "KEYPAD_3",
            R.id.btn_4 to "KEYPAD_4",
            R.id.btn_5 to "KEYPAD_5",
            R.id.btn_6 to "KEYPAD_6",
            R.id.btn_7 to "KEYPAD_7",
            R.id.btn_8 to "KEYPAD_8",
            R.id.btn_9 to "KEYPAD_9",
            R.id.btn_0 to "KEYPAD_0",
            R.id.btn_dot to "KEYPAD_DOT",
            R.id.btn_clear to "KEYPAD_CLEAR",
            R.id.btn_done to "KEYPAD_DONE"
        )
        
        keypadActions.forEach { (buttonId, action) ->
            val intent = Intent(context, HomeWidgetProvider::class.java)
            intent.action = action
            val pendingIntent = PendingIntent.getBroadcast(
                context, buttonId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(buttonId, pendingIntent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "UPDATE_WIDGET" -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "SHOW_KEYPAD" -> {
                // Toggle keypad visibility
                val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
                val isKeypadVisible = prefs.getBoolean("keypad_visible", false)
                prefs.edit().putBoolean("keypad_visible", !isKeypadVisible).apply()
                
                // Update widget to show/hide keypad
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "REFRESH_WIDGET" -> {
                // Show a brief toast message
                Toast.makeText(context, "Refreshing exchange rate...", Toast.LENGTH_SHORT).show()
                
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "SWAP_CURRENCIES" -> {
                val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
                val fromCode = prefs.getString("widget_fromCode", "USD") ?: "USD"
                val toCode = prefs.getString("widget_toCode", "PKR") ?: "PKR"
                
                // Swap currencies
                prefs.edit().apply {
                    putString("widget_fromCode", toCode)
                    putString("widget_toCode", fromCode)
                    apply()
                }
                
                // Show feedback
                Toast.makeText(context, "Currencies swapped", Toast.LENGTH_SHORT).show()
                
                // Update widget with swapped currencies
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "CHANGE_FROM_CURRENCY" -> {
                // Cycle through popular currencies
                val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
                val currentFrom = prefs.getString("widget_fromCode", "USD") ?: "USD"
                val popularCurrencies = listOf("USD", "EUR", "GBP", "JPY", "INR", "PKR", "CNY", "AUD", "CAD", "CHF", "SGD", "NZD", "MXN", "BRL", "RUB", "KRW", "TRY", "ZAR", "SEK", "NOK")
                val currentIndex = popularCurrencies.indexOf(currentFrom)
                val nextIndex = (currentIndex + 1) % popularCurrencies.size
                val newFrom = popularCurrencies[nextIndex]
                prefs.edit().putString("widget_fromCode", newFrom).apply()
                Toast.makeText(context, "From: $newFrom", Toast.LENGTH_SHORT).show()
                
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            "CHANGE_TO_CURRENCY" -> {
                // Cycle through popular currencies
                val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
                val currentTo = prefs.getString("widget_toCode", "PKR") ?: "PKR"
                val popularCurrencies = listOf("PKR", "USD", "EUR", "GBP", "JPY", "INR", "CNY", "AUD", "CAD", "CHF", "SGD", "NZD", "MXN", "BRL", "RUB", "KRW", "TRY", "ZAR", "SEK", "NOK")
                val currentIndex = popularCurrencies.indexOf(currentTo)
                val nextIndex = (currentIndex + 1) % popularCurrencies.size
                val newTo = popularCurrencies[nextIndex]
                prefs.edit().putString("widget_toCode", newTo).apply()
                Toast.makeText(context, "To: $newTo", Toast.LENGTH_SHORT).show()
                
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                for (appWidgetId in appWidgetIds) {
                    updateWidget(context, appWidgetManager, appWidgetId)
                }
            }
            // Keypad actions
            "KEYPAD_1", "KEYPAD_2", "KEYPAD_3", "KEYPAD_4", "KEYPAD_5", "KEYPAD_6", 
            "KEYPAD_7", "KEYPAD_8", "KEYPAD_9", "KEYPAD_0", "KEYPAD_DOT", "KEYPAD_CLEAR", "KEYPAD_DONE" -> {
                handleKeypadAction(context, intent.action ?: "")
            }
        }
    }
    
    private fun handleKeypadAction(context: Context, action: String) {
        val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        var currentAmount = prefs.getString("widget_amount", "1.00") ?: "1.00"

        // Sanitize currentAmount: remove all non-digit and non-dot chars (in case of legacy data)
        currentAmount = currentAmount.replace(Regex("[^0-9.]"), "")
        // Prevent multiple dots
        val dotCount = currentAmount.count { it == '.' }
        if (dotCount > 1) {
            // Keep only the first dot
            val firstDot = currentAmount.indexOf('.')
            currentAmount = currentAmount.substring(0, firstDot + 1) +
                currentAmount.substring(firstDot + 1).replace(".", "")
        }

        when (action) {
            "KEYPAD_CLEAR" -> currentAmount = "0"
            "KEYPAD_DOT" -> if (!currentAmount.contains(".")) currentAmount += "."
            "KEYPAD_DONE" -> {
                // Hide keypad and save amount (format to remove leading zeros, trailing dot, etc.)
                currentAmount = formatAmountInput(currentAmount)
                prefs.edit().putBoolean("keypad_visible", false).apply()
                prefs.edit().putString("widget_amount", currentAmount).apply()
            }
            else -> {
                // Handle number buttons
                val digit = action.substring(6) // Remove "KEYPAD_" prefix
                if (currentAmount == "0") currentAmount = digit
                else currentAmount += digit
            }
        }

        // Format and sanitize amount before saving
        currentAmount = formatAmountInput(currentAmount)
        prefs.edit().putString("widget_amount", currentAmount).apply()

        // Update widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HomeWidgetProvider::class.java)
        )
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    // Helper to format amount input: remove leading zeros, trailing dot, and keep only valid number
    private fun formatAmountInput(input: String): String {
        var cleaned = input.replace(Regex("[^0-9.]"), "")
        // Remove leading zeros (but keep single zero if that's all)
        cleaned = cleaned.trimStart('0')
        if (cleaned.isEmpty() || cleaned.startsWith(".")) cleaned = "0$cleaned"
        // Prevent multiple dots
        val dotCount = cleaned.count { it == '.' }
        if (dotCount > 1) {
            val firstDot = cleaned.indexOf('.')
            cleaned = cleaned.substring(0, firstDot + 1) +
                cleaned.substring(firstDot + 1).replace(".", "")
        }
        // Remove trailing dot
        if (cleaned.endsWith(".")) cleaned = cleaned.dropLast(1)
        // If empty, default to 0
        if (cleaned.isEmpty()) cleaned = "0"
        return cleaned
    }

    private fun getCurrencySymbol(currencyCode: String): String {
        return when (currencyCode) {
            "USD" -> "$"
            "EUR" -> "€"
            "GBP" -> "£"
            "JPY" -> "¥"
            "INR" -> "₹"
            "PKR" -> "Rs"
            "CNY" -> "¥"
            "AUD" -> "A$"
            "CAD" -> "C$"
            "CHF" -> "Fr"
            "SGD" -> "S$"
            "NZD" -> "NZ$"
            "MXN" -> "$"
            "BRL" -> "R$"
            "RUB" -> "₽"
            "KRW" -> "₩"
            "TRY" -> "₺"
            "ZAR" -> "R"
            "SEK" -> "kr"
            "NOK" -> "kr"
            else -> currencyCode
        }
    }

    private fun getCurrencyFlag(currencyCode: String): String {
        return when (currencyCode) {
            "USD" -> "🇺🇸"
            "EUR" -> "🇪🇺"
            "GBP" -> "🇬🇧"
            "JPY" -> "🇯🇵"
            "INR" -> "🇮🇳"
            "PKR" -> "🇵🇰"
            "CNY" -> "🇨🇳"
            "AUD" -> "🇦🇺"
            "CAD" -> "🇨🇦"
            "CHF" -> "🇨🇭"
            "SGD" -> "🇸🇬"
            "NZD" -> "🇳🇿"
            "MXN" -> "🇲🇽"
            "BRL" -> "🇧🇷"
            "RUB" -> "🇷🇺"
            "KRW" -> "🇰🇷"
            "TRY" -> "🇹🇷"
            "ZAR" -> "🇿🇦"
            "SEK" -> "🇸🇪"
            "NOK" -> "🇳🇴"
            else -> "🌐"
        }
    }

    private fun numberToWords(number: Double): String {
        val integerPart = number.toInt()
        val decimalPart = ((number - integerPart) * 100).toInt()
        
        val words = StringBuilder()
        
        if (integerPart == 0) {
            words.append("Zero")
        } else {
            words.append(convertNumberToWords(integerPart))
        }
        
        if (decimalPart > 0) {
            words.append(" point ")
            words.append(convertNumberToWords(decimalPart))
        }
        
        return words.toString()
    }
    
    private fun convertNumberToWords(number: Int): String {
        if (number == 0) return ""
        
        val units = arrayOf("", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine")
        val teens = arrayOf("Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen")
        val tens = arrayOf("", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety")
        
        fun convertLessThanOneThousand(n: Int): String {
            if (n == 0) return ""
            if (n < 10) return units[n]
            if (n < 20) return teens[n - 10]
            if (n < 100) {
                return tens[n / 10] + (if (n % 10 != 0) " ${units[n % 10]}" else "")
            }
            return "${units[n / 100]} Hundred${if (n % 100 != 0) " ${convertLessThanOneThousand(n % 100)}" else ""}"
        }
        
        if (number < 1000) {
            return convertLessThanOneThousand(number)
        }
        if (number < 1000000) {
            return "${convertLessThanOneThousand(number / 1000)} Thousand${if (number % 1000 != 0) " ${convertNumberToWords(number % 1000)}" else ""}"
        }
        if (number < 1000000000) {
            return "${convertLessThanOneThousand(number / 1000)} Million${if (number % 1000000 != 0) " ${convertNumberToWords(number % 1000000)}" else ""}"
        }
        return "${convertLessThanOneThousand(number / 1000000000)} Billion${if (number % 1000000000 != 0) " ${convertNumberToWords(number % 1000000000)}" else ""}"
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
                ComponentName(context, HomeWidgetProvider::class.java)
            )
            
            for (appWidgetId in appWidgetIds) {
                val provider = HomeWidgetProvider()
                provider.updateWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}

class FetchExchangeRateTask(
    private val context: Context,
    private val appWidgetManager: AppWidgetManager,
    private val appWidgetId: Int
) : Thread() {
    
    private var fromCurrency: String = ""
    private var toCurrency: String = ""
    private var amount: String = ""
    
    fun execute(from: String, to: String, amt: String) {
        fromCurrency = from
        toCurrency = to
        amount = amt
        start()
    }
    
    override fun run() {
        try {
            val url = URL("https://open.er-api.com/v6/latest/$fromCurrency")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
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
                if (jsonResponse.getString("result") == "success") {
                    val rates = jsonResponse.getJSONObject("rates")
                    val fromRate = rates.getDouble(fromCurrency)
                    val toRate = rates.getDouble(toCurrency)
                    val exchangeRate = toRate / fromRate
                    val convertedAmount = amount.toDoubleOrNull() ?: 1.0
                    val result = convertedAmount * exchangeRate
                    
                    val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putString("widget_result", String.format("%.2f", result))
                        putString("widget_rate_info", "1 $fromCurrency = ${String.format("%.4f", exchangeRate)} $toCurrency")
                        putString("widget_from_rate", "1 $fromCurrency = 1.0000")
                        putString("widget_to_rate", "1 $toCurrency = ${String.format("%.4f", 1/exchangeRate)}")
                        putString("widget_last_updated", "Just now")
                        apply()
                    }
                    
                    // Update widget on main thread
                    val intent = Intent(context, HomeWidgetProvider::class.java)
                    intent.action = "UPDATE_WIDGET"
                    context.sendBroadcast(intent)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
} 