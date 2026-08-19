import 'recommendation_service.dart';

/// Parsed voice query result.
class VoiceQueryResult {
  const VoiceQueryResult({
    required this.transcript,
    required this.extractedQuery,
    required this.criteria,
    required this.languageCode,
  });

  final String transcript;
  final String extractedQuery;
  final RecommendationCriteria criteria;
  final String languageCode;
}

/// Service for handling multilingual voice inputs and regional phrase parsing.
class VoiceSearchService {
  VoiceSearchService._();
  static final VoiceSearchService instance = VoiceSearchService._();

  /// Language code to regional name and sample phrases map.
  static const Map<String, ({String name, String code, List<String> samples})> regionalVoiceConfig = {
    'en': (
      name: 'English',
      code: 'en_IN',
      samples: [
        'Tractor for plowing 5 acres',
        'Water pump for irrigation under 300 rupees',
        'Mini harvester for rice harvesting',
        'Seed drill machine nearby'
      ],
    ),
    'hi': (
      name: 'Hindi (हिंदी)',
      code: 'hi_IN',
      samples: [
        'जुताई के लिए ट्रैक्टर चाहिए 5 एकड़',
        'सिंचाई के लिए पानी का पंप',
        'धान कटाई के लिए हार्वेस्टर',
        'बीज बोने की मशीन'
      ],
    ),
    'kn': (
      name: 'Kannada (ಕನ್ನಡ)',
      code: 'kn_IN',
      samples: [
        'ಉಳುಮೆಗೆ ಟ್ರಾಕ್ಟರ್ ಬೇಕು',
        'ನೀರಾವರಿಗೆ ಪಂಪ್ ಸೆಟ್',
        'ಭತ್ತ ಕೊಯ್ಲಿಗೆ ಹಾರ್ವೆಸ್ಟರ್',
        'ಬಿತ್ತನೆ ಯಂತ್ರ'
      ],
    ),
    'te': (
      name: 'Telugu (తెలుగు)',
      code: 'te_IN',
      samples: [
        'దుక్కికి ట్రాక్టర్ కావాలి',
        'నీటి పంపు సెట్',
        'వరి కోత మిషన్',
        'విత్తనాల మిషన్'
      ],
    ),
    'ta': (
      name: 'Tamil (தமிழ்)',
      code: 'ta_IN',
      samples: [
        'உழவு செய்ய டிராக்டர்',
        'பாசன நீர்ப்பம்ப்',
        'நெல் அறுவடை எந்திரம்',
        'விதை தெளிக்கும் எந்திரம்'
      ],
    ),
    'mr': (
      name: 'Marathi (मराठी)',
      code: 'mr_IN',
      samples: [
        'नांगरणीसाठी ट्रॅक्टर पाहिजे',
        'सिंचनासाठी पाणी पंप',
        'भात कापणी मशीन',
        'पेरणी यंत्र'
      ],
    ),
    'bn': (
      name: 'Bengali (বাংলা)',
      code: 'bn_IN',
      samples: [
        'চাষের জন্য ট্র্যাক্টর চাই',
        'সেচের জল পাম্প',
        'ধান কাটার হারভেস্টার',
        'বীজ বোনার মেশিন'
      ],
    ),
    'gu': (
      name: 'Gujarati (ગુજરાતી)',
      code: 'gu_IN',
      samples: [
        'ખેડાણ માટે ટ્રેક્ટર જોઈએ',
        'સિંચાઈ માટે વોટર પંપ',
        'પાક લણણી માટે હાર્વેસ્ટર',
        'વાવણી મશીન'
      ],
    ),
    'ml': (
      name: 'Malayalam (മലയാളം)',
      code: 'ml_IN',
      samples: [
        'ഉഴുതുമറിക്കാൻ ട്രാക്ടർ',
        'നനയ്ക്കാൻ വാട്ടർ പമ്പ്',
        'കൊയ്ത്തു യന്ത്രം',
        'വിത്തു വിതയ്ക്കുന്ന യന്ത്രം'
      ],
    ),
    'pa': (
      name: 'Punjabi (ਪੰਜਾਬੀ)',
      code: 'pa_IN',
      samples: [
        'ਵਾਹੀ ਲਈ ਟਰੈਕਟਰ ਚਾਹੀਦਾ',
        'ਸਿੰਚਾਈ ਲਈ ਪਾਣੀ ਦਾ ਪੰਪ',
        'ਝੋਨੇ ਦੀ ਵਾਢੀ ਲਈ ਹਾਰਵੈਸਟਰ',
        'ਬੀਜ ਬੀਜਣ ਵਾਲੀ ਮਸ਼ੀਨ'
      ],
    ),
    'or': (
      name: 'Odia (ଓଡ଼ିଆ)',
      code: 'or_IN',
      samples: [
        'ଚାଷ ପାଇଁ ଟ୍ରାକ୍ଟର',
        'ଜଳସେଚନ ପମ୍ପ',
        'ଧାନ କଟା ମେସିନ୍',
        'ମଞ୍ଜି ବୁଣା ମେସିନ୍'
      ],
    ),
    'ur': (
      name: 'Urdu (اردو)',
      code: 'ur_IN',
      samples: [
        'ہل چلانے کے لیے ٹریکٹر',
        'سپلائی پانی پمپ',
        'فصل کٹائی ہارویسٹر',
        'بیج بونے کی مشین'
      ],
    ),
  };

  /// Parses voice transcript (in any supported regional language) into structured criteria.
  VoiceQueryResult parseVoiceInput(String transcript, String languageCode) {
    final clean = transcript.trim();
    final lower = clean.toLowerCase();

    String? detectedTask;
    String? detectedCrop;
    double? detectedBudget;
    double? detectedLand;
    String extractedQuery = clean;

    // 1. Task recognition (Regional Multilingual Map)
    if (_containsAny(lower, ['plow', 'plough', 'tilling', 'tractor', 'जुताई', 'ट्रैक्टर', 'नांगरणी', 'ఉಳುಮೆ', 'దుక్కి', 'உழவு', 'ખેડાણ', 'ਵਾਹੀ', 'ଚାଷ'])) {
      detectedTask = 'Plowing';
      extractedQuery = 'tractor';
    } else if (_containsAny(lower, ['harvest', 'harvester', 'thresher', 'कटाई', 'हार्वेस्टर', 'ಕೊಯ್ಲು', 'కోత', 'அறுவடை', 'कापणी', 'কাটার', 'લણણી', 'ਵਾਢੀ', 'କଟା'])) {
      detectedTask = 'Harvesting';
      extractedQuery = 'harvester';
    } else if (_containsAny(lower, ['irrigation', 'pump', 'water', 'पंप', 'सिंचाई', 'ನೀರಾವರಿ', 'పంపు', 'பாசனம்', 'સિંચાઈ', 'সেচ', 'ਸਿੰਚਾਈ', 'ଜଳସେଚନ'])) {
      detectedTask = 'Irrigation';
      extractedQuery = 'pump';
    } else if (_containsAny(lower, ['seed', 'drill', 'sow', 'planting', 'बीज', 'बोने', 'ಬಿತ್ತನೆ', 'విత్తనాలు', 'விதை', 'पेरणी', 'বীজ', 'વાવણી', 'ਬੀਜ', 'ମଞ୍ଜି'])) {
      detectedTask = 'Seeding';
      extractedQuery = 'seed drill';
    } else if (_containsAny(lower, ['spray', 'sprayer', 'स्प्रे', 'छिड़काव'])) {
      detectedTask = 'Spraying';
      extractedQuery = 'sprayer';
    }

    // 2. Crop recognition
    if (_containsAny(lower, ['rice', 'paddy', 'धान', 'चावल', 'భరి', 'நெல்', 'भात', 'ধান', 'ਝੋਨਾ', 'ଧାନ'])) {
      detectedCrop = 'Rice';
    } else if (_containsAny(lower, ['wheat', 'गेहूं', 'ਗੋਹੂ', 'ଗହମ'])) {
      detectedCrop = 'Wheat';
    } else if (_containsAny(lower, ['sugarcane', 'गन्ना', 'കരിമ്പ്', 'చెరకు'])) {
      detectedCrop = 'Sugarcane';
    } else if (_containsAny(lower, ['vegetables', 'सब्जी', 'ತರಕಾರಿ', 'కూరగాయలు', 'શાકભાજી'])) {
      detectedCrop = 'Vegetables';
    }

    // 3. Extract numeric values for budget (e.g. "500", "300 rupees", "रु 400")
    final budgetMatch = RegExp(r'(?:under|below|budget|₹|rs|रु|руб|వరకు|வரை|માટે)?\s*(\d{3,5})').firstMatch(lower);
    if (budgetMatch != null) {
      detectedBudget = double.tryParse(budgetMatch.group(1) ?? '');
    }

    // 4. Extract numeric values for land size (e.g. "5 acres", "2 एकड़", "3 ಎಕರೆ")
    final landMatch = RegExp(r'(\d{1,2})\s*(?:acre|acres|एकड़|એકર|എക്കർ|ਏਕੜ|ଏକର|ఎకరాలు|ஏக்கர்)').firstMatch(lower);
    if (landMatch != null) {
      detectedLand = double.tryParse(landMatch.group(1) ?? '');
    }

    final criteria = RecommendationCriteria(
      crop: detectedCrop,
      task: detectedTask,
      landSizeAcres: detectedLand,
      maxBudgetPerHour: detectedBudget,
      searchQuery: extractedQuery,
    );

    return VoiceQueryResult(
      transcript: clean,
      extractedQuery: extractedQuery,
      criteria: criteria,
      languageCode: languageCode,
    );
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }
}
