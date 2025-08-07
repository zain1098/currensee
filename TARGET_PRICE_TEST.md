# Target Price Notification Test Guide

## Problem Description
Target price notifications were not working properly - alerts were not being triggered when conditions were met, and notifications were not being sent on time.

## Changes Made
1. **Reduced Check Interval**: Changed from 5 minutes to 2 minutes for more responsive alerts
2. **Added Immediate Check**: When alert is set, it's checked immediately
3. **Enhanced Debug Logging**: Added comprehensive logging to track alert checking process
4. **Added Manual Check**: Added refresh button to manually check alerts
5. **Improved User Feedback**: Better loading indicators and success/error messages

## Test Scenarios

### Test 1: Immediate Alert Trigger
1. Check current PKR rate (e.g., 285)
2. Set alert for PKR at 280 (above) - this should trigger immediately
3. **Expected Result**: Notification should appear immediately

### Test 2: Background Monitoring
1. Set alert for PKR at 290 (above) when current rate is 285
2. Wait for rate to change or manually trigger check
3. **Expected Result**: Notification should appear when rate reaches 290

### Test 3: Manual Check
1. Set alert for any currency
2. Click refresh button in alerts section
3. **Expected Result**: Alerts should be checked manually

### Test 4: Multiple Alerts
1. Set multiple alerts for different currencies
2. **Expected Result**: All alerts should be monitored independently

## Debug Logs to Check
Look for these log messages in the console:

```
AlertService initialized successfully
Background monitoring started - checking every 2 minutes
Checking alerts in background...
Fetching latest rates for USD...
API Response status: 200
Successfully fetched 170 rates for USD
Sample rates: [USD=1.0, EUR=0.85, PKR=285.5, ...]
Checking alert: PKR - Target: 280.0 (above), Current: 285.5
Alert triggered! PKR rate is above target
Alert notification triggered: Currency Rate Alert!
```

## Troubleshooting

### If alerts are not triggering:
1. Check console logs for API errors
2. Verify alert conditions are correct
3. Check if base currency matches
4. Use manual check button to test

### If notifications are not appearing:
1. Check device notification settings
2. Verify notification sound is set
3. Check if app has notification permissions

### If API calls are failing:
1. Check internet connection
2. Verify API endpoint is accessible
3. Check for rate limiting

## Key Code Changes

### AlertService Improvements:
```dart
// Reduced check interval
_alertCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
  _checkAlertsInBackground();
});

// Immediate check when alert is added
await _checkSpecificAlert(newAlert);

// Enhanced logging
debugPrint('Checking alert: ${alert.targetCurrency} - Target: ${alert.targetRate}');
```

### Rate List Page Improvements:
```dart
// Manual check button
IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: () => _manualCheckAlerts(),
  tooltip: 'Check alerts manually',
);

// Better user feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Alert set for $targetCurrency when rate is ${isAbove ? 'above' : 'below'} ${targetRate.toStringAsFixed(4)}'),
    backgroundColor: Colors.green,
  ),
);
```

## Testing Steps

### Step 1: Check Current Rates
1. Open rate list page
2. Note current PKR rate (e.g., 285.5)

### Step 2: Set Test Alert
1. Click on PKR row
2. Set alert for 280 (above current rate)
3. Should trigger immediately

### Step 3: Set Future Alert
1. Set alert for 290 (above current rate)
2. Should not trigger immediately
3. Wait for rate to change or use manual check

### Step 4: Monitor Logs
1. Check console for debug messages
2. Verify API calls are successful
3. Check alert checking process

## Expected Behavior After Fix
- Alerts should trigger immediately when conditions are met
- Background monitoring should check every 2 minutes
- Manual check button should work
- Better user feedback with loading indicators
- Comprehensive debug logging for troubleshooting
- Notifications should appear with proper sound

## Common Issues and Solutions

### Issue: Alert not triggering immediately
**Solution**: Check if current rate already meets condition when alert is set

### Issue: Background monitoring not working
**Solution**: Check console logs for timer initialization and API errors

### Issue: Notifications not appearing
**Solution**: Check device notification settings and app permissions

### Issue: API calls failing
**Solution**: Check internet connection and API endpoint accessibility 