import 'package:flutter/material.dart';
import 'package:rent_ease/core/services/search_service.dart';

class AdvancedSearchBar extends StatefulWidget {
  final String? initialQuery;
  final Function(String) onSearchSubmitted;
  final Function(String)? onSearchChanged;
  final Function(SearchSuggestion)? onSuggestionSelected;
  final bool enableVoiceSearch;
  final bool enableVisualSearch;
  final bool showSuggestions;
  final String? hintText;
  final Widget? leading;
  final List<Widget>? actions;

  const AdvancedSearchBar({
    super.key,
    this.initialQuery,
    required this.onSearchSubmitted,
    this.onSearchChanged,
    this.onSuggestionSelected,
    this.enableVoiceSearch = false, // Disabled until speech_to_text is added
    this.enableVisualSearch = true,
    this.showSuggestions = true,
    this.hintText,
    this.leading,
    this.actions,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchService _searchService = SearchService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<SearchSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialQuery ?? '';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);

    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadInitialSuggestions() async {
    if (widget.showSuggestions) {
      final suggestions = await _searchService.getSuggestions('');
      setState(() {
        _suggestions = suggestions;
      });
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.showSuggestions) {
      setState(() {
        _showSuggestions = true;
      });
      _animationController.forward();
    } else {
      setState(() {
        _showSuggestions = false;
      });
      _animationController.reverse();
    }
  }

  void _onTextChanged() async {
    final query = _controller.text;

    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(query);
    }

    if (widget.showSuggestions) {
      setState(() {
        _isLoading = true;
      });

      final suggestions = await _searchService.getSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchSubmitted() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _searchService.addToHistory(query);
      widget.onSearchSubmitted(query);
      _hideSuggestions();
    }
  }

  void _onSuggestionTapped(SearchSuggestion suggestion) {
    _controller.text = suggestion.text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.text.length),
    );

    if (widget.onSuggestionSelected != null) {
      widget.onSuggestionSelected!(suggestion);
    }

    _searchService.addToHistory(suggestion.text);
    widget.onSearchSubmitted(suggestion.text);
    _hideSuggestions();
  }

  void _hideSuggestions() {
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    _animationController.reverse();
  }

  void _startVoiceSearch() {
    // Voice search placeholder - would require speech_to_text package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice search requires speech_to_text package'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startVisualSearch() {
    // Visual search placeholder - would require camera and ML integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visual search coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_showSuggestions) _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onSubmitted: (_) => _onSearchSubmitted(),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search for items...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: widget.leading ??
              Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 24,
              ),
          suffixIcon: _buildSuffixActions(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget? _buildSuffixActions() {
    final actions = <Widget>[];

    // Clear button
    if (_controller.text.isNotEmpty) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () {
            _controller.clear();
            _onTextChanged();
          },
          color: Colors.grey[600],
        ),
      );
    }

    // Voice search button
    if (widget.enableVoiceSearch) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.mic_none,
            size: 20,
            color: Colors.grey[600],
          ),
          onPressed: _startVoiceSearch,
        ),
      );
    }

    // Visual search button
    if (widget.enableVisualSearch) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.camera_alt,
            size: 20,
            color: Colors.grey[600],
          ),
          onPressed: _startVisualSearch,
        ),
      );
    }

    // Custom actions
    if (widget.actions != null) {
      actions.addAll(widget.actions!);
    }

    if (actions.isEmpty) return null;

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildSuggestionsList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? _buildLoadingSuggestions()
                  : _buildSuggestionItems(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSuggestions() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSuggestionItems() {
    if (_suggestions.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No suggestions found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _buildSuggestionItem(suggestion);
        },
      ),
    );
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return InkWell(
      onTap: () => _onSuggestionTapped(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              suggestion.type.icon,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (suggestion.originalQuery != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Did you mean "${suggestion.text}"?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              suggestion.type.displayName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.call_made,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
