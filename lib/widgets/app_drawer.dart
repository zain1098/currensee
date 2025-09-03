import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../news_page.dart';
import '../multi_currency_page.dart';
import '../trend_chart.dart';
import '../world_clock.dart';
import '../rate_list_page.dart';
import '../calculator_page.dart';
import '../task_screen.dart';
import '../setting_page.dart';
import '../support_help_screen.dart';
import '../services/app_version_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Professional Drawer Header
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      Theme.of(context).brightness == Brightness.dark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF2563EB),
                          ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon with subtle animation
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Lottie.asset(
                        'assets/Menu Icon.json', // Your app icon animation
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name
                  const Text(
                    'CurrenSee Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  // Version text with fade-in animation
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: FutureBuilder<String>(
                          future: AppVersionService.getAppVersion(),
                          builder: (context, snapshot) {
                            return Text(
                              'Version ${snapshot.data ?? '1.0.6'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Menu Items
            _buildDrawerItem(
              context,
              icon: Icons.currency_exchange,
              title: 'Currency Converter',
              onTap: () => _navigateAndClose(context, const MainScreen()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.newspaper,
              title: 'Market News',
              onTap: () => _navigateAndClose(context, const NewsScreen()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calculate,
              title: 'Multi-Currency',
              onTap:
                  () => _navigateAndClose(
                    context,
                    const MultiCurrencyConverter(),
                  ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.trending_up,
              title: 'Trend Analysis',
              onTap:
                  () => _navigateAndClose(context, const CurrencyChartPage()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.timer,
              title: 'World Clock',
              onTap: () => _navigateAndClose(context, const WorldClockPage()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.list_alt,
              title: 'Rate List',
              onTap: () => _navigateAndClose(context, const RateListPage()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calculate_outlined,
              title: 'Calculator',
              onTap:
                  () => _navigateAndClose(context, const CalculatorsScreen()),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.task_alt,
              title: 'Currency Tasks',
              onTap: () => _navigateAndClose(context, const TaskScreen()),
            ),
           
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            const SizedBox(height: 16),
            // Settings Section
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap:
                  () => _navigateAndClose(
                    context,
                    SettingsPage(
                      onThemeChanged: (isDark) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setDarkMode(isDark);
                      },
                      onDecimalChanged: (decimalPlaces) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setDecimalPlaces(decimalPlaces);
                      },
                      onBaseCurrencyChanged: (currency) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setBaseCurrency(currency);
                      },
                      onAutoUpdateChanged: (autoUpdate) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setAutoUpdateRates(autoUpdate);
                      },
                      onBiometricChanged: (useBiometric) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setBiometricAuth(useBiometric);
                      },
                      onVibrationChanged: (vibration) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setHapticFeedback(vibration);
                      },
                      onCalculatorChanged: (showCalculator) {
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setShowCalculator(showCalculator);
                      },
                    ),
                  ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.help_center,
              title: 'Help & Support',
              onTap:
                  () => _navigateAndClose(context, const SupportHelpScreen()),
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            const SizedBox(height: 16),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.white;
    final chevronColor = isDark ? Colors.white70 : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
          highlightColor:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: chevronColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}