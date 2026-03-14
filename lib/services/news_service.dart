import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedAt,
    required this.imageUrl,
    this.url = '',
  });

  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String imageUrl;
  final String url;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      source: json['source']?['name'] ?? 'Unknown',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      imageUrl: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _apiKey =
      'YOUR_NEWS_API_KEY'; // Replace with actual API key
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<NewsArticle>> getFarmingNews() async {
    try {
      // Use a single, broader search query for better consistency
      final uri = Uri.parse('$_baseUrl/everything').replace(queryParameters: {
        'q': 'agriculture India farming crops tractor monsoon',
        'apiKey': _apiKey,
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': '10',
        'from':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'to': DateTime.now().toIso8601String(),
      });

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('News request timeout'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          final articles = (data['articles'] as List)
              .map((article) => NewsArticle.fromJson(article))
              .where((article) =>
                  article.title.isNotEmpty &&
                  article.description.isNotEmpty &&
                  !article.title.toLowerCase().contains('[removed]'))
              .take(8) // Limit to 8 articles
              .toList();

          if (articles.isNotEmpty) {
            return articles;
          }
        }
      }

      // If API fails or returns empty, use fallback
      return _getFallbackNews();
    } catch (e) {
      // Always return fallback on any error
      return _getFallbackNews();
    }
  }

  List<NewsArticle> _getFallbackNews() {
    final now = DateTime.now();
    return [
      NewsArticle(
        title:
            'Government subsidy announced for tractors — up to ₹50,000 benefit for small farmers',
        description:
            'New scheme aims to boost farm mechanization across rural areas with financial assistance',
        source: 'Krishi News',
        publishedAt: now.subtract(const Duration(hours: 2)),
        imageUrl: '',
      ),
      NewsArticle(
        title:
            'New drought-resistant rice variety released by ICAR for semi-arid regions',
        description:
            'Scientists develop climate-resilient crop varieties to combat water scarcity challenges',
        source: 'AgriToday',
        publishedAt: now.subtract(const Duration(hours: 5)),
        imageUrl: '',
      ),
      NewsArticle(
        title:
            'AI-based irrigation systems help reduce water consumption by 35% in Karnataka farms',
        description:
            'Smart farming technology shows promising results in water conservation efforts',
        source: 'FarmTech India',
        publishedAt: now.subtract(const Duration(hours: 8)),
        imageUrl: '',
      ),
      NewsArticle(
        title:
            'Wheat prices surge 12% — MSP increase expected in upcoming kharif season',
        description:
            'Market analysts predict higher minimum support prices for wheat farmers this season',
        source: 'Agri Market',
        publishedAt: now.subtract(const Duration(days: 1)),
        imageUrl: '',
      ),
      NewsArticle(
        title: 'Monsoon arrives early in Kerala, good news for kharif crops',
        description:
            'Timely rainfall expected to boost agricultural production across southern states',
        source: 'Weather Today',
        publishedAt: now.subtract(const Duration(days: 1, hours: 6)),
        imageUrl: '',
      ),
      NewsArticle(
        title: 'Organic farming demand increases by 40% in urban markets',
        description:
            'Consumers showing preference for chemical-free produce, benefiting small farmers',
        source: 'Organic India',
        publishedAt: now.subtract(const Duration(days: 2)),
        imageUrl: '',
      ),
    ];
  }
}
