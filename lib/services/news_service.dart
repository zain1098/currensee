import 'package:cloud_firestore/cloud_firestore.dart';

class NewsCategory {
  final String id;
  final String name;
  final String apiCategory;
  final String status; // 'active' or 'inactive'
  final int maxArticles;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsCategory({
    required this.id,
    required this.name,
    required this.apiCategory,
    required this.status,
    required this.maxArticles,
    required this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json, String id) {
    return NewsCategory(
      id: id,
      name: json['name'] ?? '',
      apiCategory: json['apiCategory'] ?? '',
      status: json['status'] ?? 'active',
      maxArticles: json['maxArticles'] ?? 20,
      description: json['description'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt:
          json['updatedAt'] != null
              ? (json['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'apiCategory': apiCategory,
      'status': status,
      'maxArticles': maxArticles,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class NewsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load news categories from Firebase
  static Future<List<NewsCategory>> loadNewsCategories() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('news_categories')
              .orderBy('createdAt', descending: false)
              .get();

      List<NewsCategory> categories = [];
      for (var doc in querySnapshot.docs) {
        final category = NewsCategory.fromJson(doc.data(), doc.id);
        // Load all categories (both active and inactive)
        categories.add(category);
      }

      // If no categories found in database, return default categories
      if (categories.isEmpty) {
        return _getDefaultCategories();
      }

      return categories;
    } catch (e) {
      print('Error loading news categories: $e');
      return _getDefaultCategories();
    }
  }

  // Get default categories (fallback)
  static List<NewsCategory> _getDefaultCategories() {
    return [
      NewsCategory(
        id: 'business',
        name: 'Business',
        apiCategory: 'business',
        status: 'active',
        maxArticles: 20,
        description: 'Latest business news and updates',
        createdAt: DateTime.now(),
      ),
      NewsCategory(
        id: 'economy',
        name: 'Economy',
        apiCategory: 'economy',
        status: 'active',
        maxArticles: 20,
        description: 'Economic news and financial updates',
        createdAt: DateTime.now(),
      ),
      NewsCategory(
        id: 'finance',
        name: 'Finance',
        apiCategory: 'finance',
        status: 'active',
        maxArticles: 20,
        description: 'Financial markets and investment news',
        createdAt: DateTime.now(),
      ),
      NewsCategory(
        id: 'technology',
        name: 'Technology',
        apiCategory: 'technology',
        status: 'active',
        maxArticles: 20,
        description: 'Technology and innovation news',
        createdAt: DateTime.now(),
      ),
      NewsCategory(
        id: 'world',
        name: 'World',
        apiCategory: 'world',
        status: 'active',
        maxArticles: 20,
        description: 'International news and global updates',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Initialize default categories in database
  static Future<void> initializeDefaultCategories() async {
    try {
      final defaultCategories = _getDefaultCategories();

      for (var category in defaultCategories) {
        await _firestore
            .collection('news_categories')
            .doc(category.id)
            .set(category.toJson());
      }

      print('Default news categories initialized successfully');
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }

  // Add new category
  static Future<void> addCategory(NewsCategory category) async {
    try {
      await _firestore
          .collection('news_categories')
          .doc(category.id)
          .set(category.toJson());
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // Update category
  static Future<void> updateCategory(NewsCategory category) async {
    try {
      final updatedData = category.toJson();
      updatedData['updatedAt'] = Timestamp.now();

      await _firestore
          .collection('news_categories')
          .doc(category.id)
          .update(updatedData);
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('news_categories').doc(categoryId).delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Block/Unblock category
  static Future<void> toggleCategoryStatus(
    String categoryId,
    String status,
  ) async {
    try {
      await _firestore.collection('news_categories').doc(categoryId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error toggling category status: $e');
      rethrow;
    }
  }

  // Get category by ID
  static Future<NewsCategory?> getCategoryById(String categoryId) async {
    try {
      final doc =
          await _firestore.collection('news_categories').doc(categoryId).get();

      if (doc.exists) {
        return NewsCategory.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  // Get news configuration
  static Future<Map<String, dynamic>> getNewsConfiguration() async {
    try {
      final doc =
          await _firestore.collection('app_config').doc('news_settings').get();

      if (doc.exists) {
        return doc.data()!;
      }

      // Return default configuration
      return {
        'apiKey': 'b2254f48318f9db55c21821b24d057bd',
        'baseUrl': 'https://gnews.io/api/v4/top-headlines',
        'defaultLanguage': 'en',
        'defaultCountry': 'us',
        'maxArticlesPerCategory': 20,
        'refreshInterval': 300, // 5 minutes
        'enableCaching': true,
        'cacheDuration': 600, // 10 minutes
      };
    } catch (e) {
      print('Error getting news configuration: $e');
      return {
        'apiKey': 'b2254f48318f9db55c21821b24d057bd',
        'baseUrl': 'https://gnews.io/api/v4/top-headlines',
        'defaultLanguage': 'en',
        'defaultCountry': 'us',
        'maxArticlesPerCategory': 20,
        'refreshInterval': 300,
        'enableCaching': true,
        'cacheDuration': 600,
      };
    }
  }

  // Update news configuration
  static Future<void> updateNewsConfiguration(
    Map<String, dynamic> config,
  ) async {
    try {
      await _firestore
          .collection('app_config')
          .doc('news_settings')
          .set(config);
    } catch (e) {
      print('Error updating news configuration: $e');
      rethrow;
    }
  }

  // Initialize all news categories in database (one-time setup)
  static Future<void> initializeAllNewsCategories() async {
    try {
      final allCategories = [
        {
          'id': 'business',
          'name': 'Business',
          'apiCategory': 'business',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Latest business news and updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'economy',
          'name': 'Economy',
          'apiCategory': 'economy',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Economic news and financial updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'finance',
          'name': 'Finance',
          'apiCategory': 'finance',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Financial markets and investment news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'technology',
          'name': 'Technology',
          'apiCategory': 'technology',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Technology and innovation news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'world',
          'name': 'World',
          'apiCategory': 'world',
          'status': 'active',
          'maxArticles': 20,
          'description': 'International news and global updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'cryptocurrency',
          'name': 'Cryptocurrency',
          'apiCategory': 'cryptocurrency',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Cryptocurrency and blockchain technology news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'stock-market',
          'name': 'Stock Market',
          'apiCategory': 'stock market',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Stock market updates and trading news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'real-estate',
          'name': 'Real Estate',
          'apiCategory': 'real estate',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Real estate market and property news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'healthcare',
          'name': 'Healthcare',
          'apiCategory': 'health',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Healthcare and pharmaceutical industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'energy',
          'name': 'Energy',
          'apiCategory': 'energy',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Energy sector and oil market updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'automotive',
          'name': 'Automotive',
          'apiCategory': 'automotive',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Automotive industry and car market news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'entertainment',
          'name': 'Entertainment',
          'apiCategory': 'entertainment',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Entertainment and media industry updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'sports-business',
          'name': 'Sports Business',
          'apiCategory': 'sports',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Sports business and industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'politics',
          'name': 'Politics',
          'apiCategory': 'politics',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Political news affecting business and economy',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'science',
          'name': 'Science',
          'apiCategory': 'science',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Scientific research and innovation news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'education',
          'name': 'Education',
          'apiCategory': 'education',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Education sector and EdTech industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'travel',
          'name': 'Travel',
          'apiCategory': 'travel',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Travel industry and tourism business news',
          'createdAt': Timestamp.now(),
        },
      ];

      // Use batch write for better performance
      final batch = _firestore.batch();

      for (var category in allCategories) {
        final docRef = _firestore
            .collection('news_categories')
            .doc(category['id'] as String);
        batch.set(docRef, category);
      }

      await batch.commit();
      print('✅ All news categories initialized successfully!');
      print('📊 Total categories added: ${allCategories.length}');
    } catch (e) {
      print('❌ Error initializing news categories: $e');
      rethrow;
    }
  }

  // Quick setup function - call this to add all categories
  static Future<void> quickSetup() async {
    print('🚀 Starting quick setup for news categories...');
    await initializeAllNewsCategories();
    print('🎉 Quick setup completed!');
  }

  // Simple function to add one category for testing
  static Future<void> addSingleCategory(
    String id,
    String name,
    String apiCategory,
  ) async {
    try {
      final category = {
        'id': id,
        'name': name,
        'apiCategory': apiCategory,
        'status': 'active',
        'maxArticles': 20,
        'description': 'Test category: $name',
        'createdAt': Timestamp.now(),
      };

      await _firestore.collection('news_categories').doc(id).set(category);

      print('✅ Added category: $name');
    } catch (e) {
      print('❌ Error adding category $name: $e');
      rethrow;
    }
  }

  // Direct database insertion for all categories (no Firebase Functions needed)
  static Future<void> insertAllCategoriesDirectly() async {
    try {
      print('🚀 Starting direct database insertion...');

      final allCategories = [
        {
          'id': 'business',
          'name': 'Business',
          'apiCategory': 'business',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Latest business news and updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'economy',
          'name': 'Economy',
          'apiCategory': 'economy',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Economic news and financial updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'finance',
          'name': 'Finance',
          'apiCategory': 'finance',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Financial markets and investment news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'technology',
          'name': 'Technology',
          'apiCategory': 'technology',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Technology and innovation news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'world',
          'name': 'World',
          'apiCategory': 'world',
          'status': 'active',
          'maxArticles': 20,
          'description': 'International news and global updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'cryptocurrency',
          'name': 'Cryptocurrency',
          'apiCategory': 'cryptocurrency',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Cryptocurrency and blockchain technology news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'stock-market',
          'name': 'Stock Market',
          'apiCategory': 'stock market',
          'status': 'active',
          'maxArticles': 20,
          'description': 'Stock market updates and trading news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'real-estate',
          'name': 'Real Estate',
          'apiCategory': 'real estate',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Real estate market and property news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'healthcare',
          'name': 'Healthcare',
          'apiCategory': 'health',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Healthcare and pharmaceutical industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'energy',
          'name': 'Energy',
          'apiCategory': 'energy',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Energy sector and oil market updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'automotive',
          'name': 'Automotive',
          'apiCategory': 'automotive',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Automotive industry and car market news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'entertainment',
          'name': 'Entertainment',
          'apiCategory': 'entertainment',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Entertainment and media industry updates',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'sports-business',
          'name': 'Sports Business',
          'apiCategory': 'sports',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Sports business and industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'politics',
          'name': 'Politics',
          'apiCategory': 'politics',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Political news affecting business and economy',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'science',
          'name': 'Science',
          'apiCategory': 'science',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Scientific research and innovation news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'education',
          'name': 'Education',
          'apiCategory': 'education',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Education sector and EdTech industry news',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'travel',
          'name': 'Travel',
          'apiCategory': 'travel',
          'status': 'active',
          'maxArticles': 15,
          'description': 'Travel industry and tourism business news',
          'createdAt': Timestamp.now(),
        },
      ];

      final batch = _firestore.batch();

      for (var category in allCategories) {
        final docRef = _firestore
            .collection('news_categories')
            .doc(category['id'] as String);
        batch.set(docRef, category);
      }

      await batch.commit();

      print(
        '✅ All ${allCategories.length} news categories inserted successfully!',
      );
      print('📊 Total categories added: ${allCategories.length}');
    } catch (e) {
      print('❌ Error inserting categories: $e');
      rethrow;
    }
  }
}
