import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConverterCurrencySelection extends StatefulWidget {
  const ConverterCurrencySelection({super.key});

  @override
  State<ConverterCurrencySelection> createState() => _ConverterCurrencySelectionState();
}

class _ConverterCurrencySelectionState extends State<ConverterCurrencySelection> {
  String selectedFromCurrency = 'USD';
  String selectedToCurrency = 'PKR';
  final List<String> popularCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'PKR', 'INR', 'CNY', 'CAD', 'AUD', 'CHF',
    'NZD', 'SGD', 'HKD', 'KRW', 'THB', 'MYR', 'IDR', 'PHP', 'VND', 'BDT'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFromCurrency = prefs.getString('converter_from_currency') ?? 'USD';
      selectedToCurrency = prefs.getString('converter_to_currency') ?? 'PKR';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('converter_from_currency', selectedFromCurrency);
    await prefs.setString('converter_to_currency', selectedToCurrency);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Converter widget settings saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter Widget Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select currencies for your converter widget:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // From Currency
            const Text('From Currency:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFromCurrency,
                  isExpanded: true,
                  items: popularCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFromCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // To Currency
            const Text('To Currency:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedToCurrency,
                  isExpanded: true,
                  items: popularCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedToCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 How to use:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Add converter widget to your home screen'),
                  Text('• Tap on the widget to open this settings page'),
                  Text('• Select your preferred currency pair'),
                  Text('• Widget will show real-time conversion rates'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
