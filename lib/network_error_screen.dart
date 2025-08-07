// network_error_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NetworkErrorScreen extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onContinueOffline;
  final bool isChecking;

  const NetworkErrorScreen({
    super.key,
    this.onRetry,
    this.onContinueOffline,
    this.isChecking = false,
  });

  @override
  State<NetworkErrorScreen> createState() => _NetworkErrorScreenState();
}

class _NetworkErrorScreenState extends State<NetworkErrorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/net_disconnect.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      'Lottie Error: $error',
                    ); // Debug print to see what error is
                    return const SizedBox.shrink(); // Return empty widget instead of icon
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  'Connection Lost',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "We can't connect to the internet. Please check your network connection and try again.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                // Retry Button with conditional loading
                ElevatedButton(
                  onPressed: widget.isChecking ? null : widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child:
                      widget.isChecking
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Retry Connection'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: widget.onContinueOffline,
                  child: Text(
                    'Continue Offline',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
