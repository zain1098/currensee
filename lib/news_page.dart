import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // For CustomAppBar
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'world_clock.dart';
import 'multi_currency_page.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_form_screen.dart';
import 'services/news_service.dart';

// ... (Keep the existing MyApp, MainNavigationScreen and CurrencyConverterScreen code)

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<NewsArticle> articles = [];
  List<NewsArticle> filteredArticles = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'business';
  List<NewsCategory> categories = [];
  Map<String, dynamic> newsConfig = {};

  @override
  void initState() {
    super.initState();
    _loadNewsData();
  }

  Future<void> _loadNewsData() async {
    try {
      // Load categories and configuration
      final loadedCategories = await NewsService.loadNewsCategories();
      final config = await NewsService.getNewsConfiguration();

      setState(() {
        categories = loadedCategories;
        newsConfig = config;
        if (categories.isNotEmpty) {
          selectedCategory = categories.first.id;
        }
      });

      // Fetch news after loading categories
      fetchNews();
    } catch (e) {
      print('Error loading news data: $e');
      // Fallback to default behavior
      fetchNews();
    }
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  Future<void> fetchNews() async {
    if (categories.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Find the selected category
      final selectedCat = categories.firstWhere(
        (cat) => cat.id == selectedCategory,
        orElse: () => categories.first,
      );

      // Check if category is inactive
      if (selectedCat.status == 'inactive') {
        setState(() {
          errorMessage =
              '${selectedCat.name} category is temporarily blocked by admin';
          isLoading = false;
        });
        return;
      }

      // Build API URL with configuration
      final apiKey = newsConfig['apiKey'] ?? 'b2254f48318f9db55c21821b24d057bd';
      final baseUrl =
          newsConfig['baseUrl'] ?? 'https://gnews.io/api/v4/top-headlines';
      final language = newsConfig['defaultLanguage'] ?? 'en';
      final country = newsConfig['defaultCountry'] ?? 'us';
      final maxArticles = selectedCat.maxArticles;

      final url =
          '$baseUrl?category=${selectedCat.apiCategory}&lang=$language&country=$country&max=$maxArticles&apikey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['totalArticles'] > 0) {
          List<dynamic> articlesJson = data['articles'];
          setState(() {
            articles =
                articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
            filteredArticles = articles;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No articles found in this category';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load news. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void filterArticles(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredArticles = articles;
      } else {
        filteredArticles =
            articles.where((article) {
              return article.title.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  article.description.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  article.sourceName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (article.content?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false);
            }).toList();
      }
    });
  }

  void changeCategory(String categoryId) {
    // Check if the category is inactive
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => categories.first,
    );

    if (category.status == 'inactive') {
      // Show a message that category is blocked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.name} category is temporarily blocked by admin',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      selectedCategory = categoryId;
      isLoading = true;
      _searchController.clear();
    });
    fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'News',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Professional Drawer Header
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
                          child: const Text(
                            'Version 2.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
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
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
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
                    () => _navigateAndClose(context, const ContactFormScreen()),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar and Categories (moved below AppBar)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A6CD1), Color(0xFF8A4ED2)],
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: filterArticles,
                    decoration: InputDecoration(
                      hintText: 'Search financial news...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                // Categories
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == selectedCategory;
                      final isInactive = category.status == 'inactive';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Stack(
                          children: [
                            ChoiceChip(
                              label: Text(
                                category.name.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : isInactive
                                          ? Colors.grey[500]
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      isInactive
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                              ),
                              selected: isSelected && !isInactive,
                              selectedColor: const Color(0xFF4A6CD1),
                              backgroundColor:
                                  isInactive
                                      ? Colors.grey[300]
                                      : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                              onSelected:
                                  isInactive
                                      ? null
                                      : (selected) =>
                                          changeCategory(category.id),
                              disabledColor: Colors.grey[300],
                            ),
                            if (isInactive)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // News List
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    )
                    : filteredArticles.isEmpty
                    ? const Center(
                      child: Text(
                        'No articles found. Try another category or search term.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchNews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredArticles.length,
                        itemBuilder: (context, index) {
                          final article = filteredArticles[index];
                          return _buildNewsCard(article);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            article.imageUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 180,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 180,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                  ),
                )
                : Container(
                  height: 180,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.article,
                    size: 60,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                  ),
                ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.sourceName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(article.publishedAt),
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    article.description,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Read More
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Read Full Article',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A6CD1), Color(0xFF8A4ED2)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            article.imageUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              Text('Image not available'),
                            ],
                          ),
                        ),
                  ),
                )
                : Container(
                  height: 250,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.article,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.sourceName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(article.publishedAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content
                  Text(
                    article.content ?? article.description,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),

                  const SizedBox(height: 32),

                  // Full Article Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(article.url),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CD1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.launch),
                      label: const Text(
                        'Read Full Article on Website',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final String sourceName;
  final String? content;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.sourceName,
    this.content,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? 'No description',
      url: json['url'] ?? '',
      imageUrl: json['image'] ?? '',
      publishedAt: DateTime.parse(
        json['publishedAt'] ?? DateTime.now().toString(),
      ),
      sourceName: json['source']['name'] ?? 'Unknown source',
      content: json['content'],
    );
  }
}
