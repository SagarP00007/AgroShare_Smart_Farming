# News API Setup for AgroShare

## Overview
The AgroShare app now includes daily farming news updates in the Explore screen. The news is fetched from NewsAPI.org and provides farmers with relevant agricultural information.

## Setup Instructions

### 1. Get News API Key
1. Visit [NewsAPI.org](https://newsapi.org/)
2. Sign up for a free account
3. Get your API key from the dashboard

### 2. Configure API Key
Open `lib/services/news_service.dart` and replace the placeholder:

```dart
static const String _apiKey = 'YOUR_NEWS_API_KEY'; // Replace with actual API key
```

Replace `YOUR_NEWS_API_KEY` with your actual API key.

### 3. News Sources
The app searches for farming-related news using these keywords:
- agriculture India
- farming India  
- tractor India
- crops India
- monsoon agriculture
- farm equipment India

### 4. Features
- **Real-time Updates**: News is refreshed daily
- **Farmer-Friendly**: Content is filtered for agricultural relevance
- **Offline Support**: Fallback news available when API is unreachable
- **Multi-language Ready**: Translation keys prepared for Indian languages

### 5. Rate Limits
- Free tier: 1,000 requests per day
- News is cached to minimize API calls
- Automatic retry mechanism for failed requests

## Troubleshooting

### No News Showing
1. Check your API key is correctly set
2. Verify internet connection
3. Check API rate limits

### News Not Updating
1. Pull to refresh on the Explore screen
2. Check if API rate limit is exceeded
3. Restart the app to refresh the cache

## API Response Format
```dart
class NewsArticle {
  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String imageUrl;
  final String url;
}
```

## Localization
News-related strings are added to translation files:
- `daily_farming_news`: "Daily Farming News"
- `refresh_news`: "Refresh News"
- `failed_to_load_news`: "Failed to load news"
- `no_news_available`: "No news available"

## Privacy
- No personal data is sent to the news API
- Only public news sources are accessed
- All content is filtered for agricultural relevance
