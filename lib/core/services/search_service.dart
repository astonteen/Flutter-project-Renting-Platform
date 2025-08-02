import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static const String _searchHistoryKey = 'search_history';
  static const String _popularSearchesKey = 'popular_searches';
  static const int _maxHistoryItems = 20;
  static const int _maxSuggestions = 10;

  List<String> _searchHistory = [];
  List<String> _popularSearches = [];
  final Map<String, int> _searchFrequency = {};
  Timer? _debounceTimer;

  // Common search terms and categories
  final List<String> _commonTerms = [
    'camera',
    'laptop',
    'bike',
    'car',
    'tools',
    'furniture',
    'electronics',
    'sports equipment',
    'books',
    'games',
    'phone',
    'tablet',
    'headphones',
    'guitar',
    'keyboard',
    'monitor',
    'printer',
    'projector',
    'speaker',
    'microphone',
    'drone',
    'gaming chair',
    'desk',
    'tent',
    'backpack',
    'suitcase',
    'power tools',
    'garden tools',
    'kitchen appliances',
    'vacuum cleaner',
    'washing machine',
    'refrigerator',
    'air conditioner'
  ];

  final List<String> _categories = [
    'Electronics',
    'Vehicles',
    'Tools & Equipment',
    'Furniture',
    'Sports',
    'Books & Media',
    'Kitchen & Appliances',
    'Garden & Outdoor',
    'Fashion',
    'Health & Beauty',
    'Toys & Games',
    'Music & Instruments',
    'Office',
    'Travel & Luggage',
    'Home & Living',
    'Art & Crafts',
    'Photography',
    'Fitness',
    'Camping',
    'Baby & Kids'
  ];

  // Initialize search service
  Future<void> initialize() async {
    await _loadSearchHistory();
    await _loadPopularSearches();
  }

  // Load search history from local storage
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  // Load popular searches from local storage
  Future<void> _loadPopularSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _popularSearches = prefs.getStringList(_popularSearchesKey) ?? [];
    } catch (e) {
      debugPrint('Error loading popular searches: $e');
    }
  }

  // Save search history to local storage
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  // Save popular searches to local storage
  Future<void> _savePopularSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_popularSearchesKey, _popularSearches);
    } catch (e) {
      debugPrint('Error saving popular searches: $e');
    }
  }

  // Add search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim().toLowerCase();

    // Remove if already exists
    _searchHistory.removeWhere((item) => item.toLowerCase() == trimmedQuery);

    // Add to beginning
    _searchHistory.insert(0, trimmedQuery);

    // Limit history size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }

    // Update frequency
    _searchFrequency[trimmedQuery] = (_searchFrequency[trimmedQuery] ?? 0) + 1;

    // Update popular searches
    _updatePopularSearches();

    await _saveSearchHistory();
  }

  // Update popular searches based on frequency
  void _updatePopularSearches() {
    final sortedEntries = _searchFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _popularSearches =
        sortedEntries.take(10).map((entry) => entry.key).toList();

    _savePopularSearches();
  }

  // Generate search suggestions with debouncing
  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      return _getDefaultSuggestions();
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    final completer = Completer<List<SearchSuggestion>>();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final suggestions = _generateSuggestions(query);
      completer.complete(suggestions);
    });

    return completer.future;
  }

  // Generate suggestions based on query
  List<SearchSuggestion> _generateSuggestions(String query) {
    final suggestions = <SearchSuggestion>[];
    final queryLower = query.toLowerCase().trim();

    // 1. Exact matches from history
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().startsWith(queryLower)) {
        suggestions.add(SearchSuggestion(
          text: historyItem,
          type: SuggestionType.history,
          confidence: 1.0,
        ));
      }
    }

    // 2. Fuzzy matches from history
    for (final historyItem in _searchHistory) {
      if (!historyItem.toLowerCase().startsWith(queryLower) &&
          _fuzzyMatch(historyItem.toLowerCase(), queryLower)) {
        suggestions.add(SearchSuggestion(
          text: historyItem,
          type: SuggestionType.history,
          confidence:
              _calculateSimilarity(historyItem.toLowerCase(), queryLower),
        ));
      }
    }

    // 3. Common terms matches
    for (final term in _commonTerms) {
      if (term.toLowerCase().contains(queryLower)) {
        suggestions.add(SearchSuggestion(
          text: term,
          type: SuggestionType.common,
          confidence: term.toLowerCase().startsWith(queryLower) ? 0.9 : 0.7,
        ));
      }
    }

    // 4. Category matches
    for (final category in _categories) {
      if (category.toLowerCase().contains(queryLower)) {
        suggestions.add(SearchSuggestion(
          text: category,
          type: SuggestionType.category,
          confidence: category.toLowerCase().startsWith(queryLower) ? 0.8 : 0.6,
        ));
      }
    }

    // 5. Typo correction suggestions
    final typoSuggestions = _getTypoCorrections(queryLower);
    suggestions.addAll(typoSuggestions);

    // Sort by confidence and remove duplicates
    final uniqueSuggestions = <String, SearchSuggestion>{};
    for (final suggestion in suggestions) {
      final key = suggestion.text.toLowerCase();
      if (!uniqueSuggestions.containsKey(key) ||
          uniqueSuggestions[key]!.confidence < suggestion.confidence) {
        uniqueSuggestions[key] = suggestion;
      }
    }

    final sortedSuggestions = uniqueSuggestions.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return sortedSuggestions.take(_maxSuggestions).toList();
  }

  // Get default suggestions when no query
  List<SearchSuggestion> _getDefaultSuggestions() {
    final suggestions = <SearchSuggestion>[];

    // Recent searches
    for (final item in _searchHistory.take(5)) {
      suggestions.add(SearchSuggestion(
        text: item,
        type: SuggestionType.history,
        confidence: 1.0,
      ));
    }

    // Popular searches
    for (final item in _popularSearches.take(3)) {
      if (!_searchHistory.contains(item)) {
        suggestions.add(SearchSuggestion(
          text: item,
          type: SuggestionType.popular,
          confidence: 0.9,
        ));
      }
    }

    // Trending categories
    final trendingCategories = [
      'Electronics',
      'Tools & Equipment',
      'Furniture'
    ];
    for (final category in trendingCategories) {
      suggestions.add(SearchSuggestion(
        text: category,
        type: SuggestionType.trending,
        confidence: 0.8,
      ));
    }

    return suggestions;
  }

  // Fuzzy matching algorithm
  bool _fuzzyMatch(String text, String query) {
    if (query.length < 2) return false;

    final similarity = _calculateSimilarity(text, query);
    return similarity > 0.5;
  }

  // Calculate similarity between two strings
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;

    if (longer.isEmpty) return 1.0;

    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  // Levenshtein distance algorithm
  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  // Get typo correction suggestions
  List<SearchSuggestion> _getTypoCorrections(String query) {
    final suggestions = <SearchSuggestion>[];

    // Common typos and corrections
    final typoMap = {
      'camra': 'camera',
      'laptap': 'laptop',
      'bycicle': 'bicycle',
      'furnitue': 'furniture',
      'electroncs': 'electronics',
      'equipmnt': 'equipment',
      'phon': 'phone',
      'computr': 'computer',
    };

    if (typoMap.containsKey(query)) {
      suggestions.add(SearchSuggestion(
        text: typoMap[query]!,
        type: SuggestionType.correction,
        confidence: 0.95,
        originalQuery: query,
      ));
    }

    return suggestions;
  }

  // Clear search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    _searchFrequency.clear();
    await _saveSearchHistory();
  }

  // Get search history
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  // Get popular searches
  List<String> get popularSearches => List.unmodifiable(_popularSearches);

  // Get trending searches (mock data for demo)
  List<String> getTrendingSearches() {
    return [
      'iPhone 14',
      'MacBook Pro',
      'Gaming Chair',
      'Power Tools',
      'DSLR Camera',
      'Electric Bike',
      'Camping Tent',
      'Kitchen Mixer',
    ];
  }

  // Voice search result processing
  String processVoiceSearchResult(String voiceResult) {
    // Clean up voice recognition result
    String processed = voiceResult.toLowerCase().trim();

    // Remove common voice recognition artifacts
    processed = processed.replaceAll(RegExp(r'\b(um|uh|er)\b'), '');
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    // Auto-correct common voice recognition errors
    final voiceCorrections = {
      'i phone': 'iPhone',
      'mac book': 'MacBook',
      'play station': 'PlayStation',
      'x box': 'Xbox',
      'lap top': 'laptop',
      'head phones': 'headphones',
    };

    for (final correction in voiceCorrections.entries) {
      processed = processed.replaceAll(correction.key, correction.value);
    }

    return processed;
  }
}

// Search suggestion model
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final double confidence;
  final String? originalQuery;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.confidence,
    this.originalQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}

// Suggestion types
enum SuggestionType {
  history,
  popular,
  common,
  category,
  trending,
  correction,
}

// Search suggestion extensions
extension SuggestionTypeExtension on SuggestionType {
  String get displayName {
    switch (this) {
      case SuggestionType.history:
        return 'Recent';
      case SuggestionType.popular:
        return 'Popular';
      case SuggestionType.common:
        return 'Suggested';
      case SuggestionType.category:
        return 'Category';
      case SuggestionType.trending:
        return 'Trending';
      case SuggestionType.correction:
        return 'Did you mean';
    }
  }

  IconData get icon {
    switch (this) {
      case SuggestionType.history:
        return Icons.history;
      case SuggestionType.popular:
        return Icons.trending_up;
      case SuggestionType.common:
        return Icons.search;
      case SuggestionType.category:
        return Icons.category;
      case SuggestionType.trending:
        return Icons.whatshot;
      case SuggestionType.correction:
        return Icons.spellcheck;
    }
  }
}
