import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_text_field.dart';
import '../services/search_history_service.dart';
import '../models/organization_models.dart';

/// Enhanced search bar widget for organization chart with suggestions and history
/// 
/// Features:
/// - Debounced search (400ms delay)
/// - Search suggestions from employee names
/// - Search history with auto-complete
/// - Overlay suggestions list
class OrganizationChartSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int? resultCount;
  final List<Employee>? employees; // For suggestions

  const OrganizationChartSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.resultCount,
    this.employees,
  });

  @override
  State<OrganizationChartSearchBar> createState() =>
      _OrganizationChartSearchBarState();
}

class _OrganizationChartSearchBarState
    extends State<OrganizationChartSearchBar> {
  final FocusNode _focusNode = FocusNode();
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  void _onTextChanged() {
    setState(() {});
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
      _showSuggestionsOverlay();
    } else {
      // Remove overlay immediately when focus is lost
      _removeOverlay();
    }
  }

  void _updateSuggestions() {
    final query = widget.controller.text.toLowerCase();
    final suggestions = <String>[];

    // Add matching employees as suggestions
    if (widget.employees != null && query.isNotEmpty) {
      for (final employee in widget.employees!) {
        if (employee.username.toLowerCase().contains(query)) {
          suggestions.add(employee.username);
        }
      }
    }

    // Add matching history items
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(query) &&
          !suggestions.contains(historyItem)) {
        suggestions.add(historyItem);
      }
    }

    setState(() {
      _suggestions = suggestions.take(5).toList();
      _showSuggestions = query.isNotEmpty || _searchHistory.isNotEmpty;
    });
  }

  void _showSuggestionsOverlay() {
    if (!_showSuggestions || (_suggestions.isEmpty && _searchHistory.isEmpty)) {
      return;
    }

    _removeOverlay();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final items = <Widget>[];

    // Add suggestions from current query
    if (widget.controller.text.isNotEmpty && _suggestions.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'اقتراحات',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
      for (final suggestion in _suggestions) {
        items.add(_buildSuggestionItem(suggestion, isHistory: false));
      }
    }

    // Add history items
    if (widget.controller.text.isEmpty && _searchHistory.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سجل البحث',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await SearchHistoryService.clearHistory();
                  _loadSearchHistory();
                  _updateSuggestions();
                },
                child: Text(
                  'مسح',
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
      for (final historyItem in _searchHistory.take(5)) {
        items.add(_buildSuggestionItem(historyItem, isHistory: true));
      }
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: items,
    );
  }

  Widget _buildSuggestionItem(String text, {required bool isHistory}) {
    return InkWell(
      onTap: () {
        widget.controller.text = text;
        widget.onChanged(text);
        // Unfocus and remove overlay immediately
        _focusNode.unfocus();
        _removeOverlay();
        if (!isHistory) {
          SearchHistoryService.addToHistory(text);
          _loadSearchHistory();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isHistory ? Icons.history_rounded : Icons.search_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isHistory)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () async {
                  await SearchHistoryService.removeFromHistory(text);
                  _loadSearchHistory();
                  _updateSuggestions();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            label: 'بحث',
            placeholder: 'ابحث بالاسم...',
            prefixIcon: Icons.search_rounded,
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      _focusNode.unfocus(); // Unfocus when clearing
                      _updateSuggestions();
                    },
                  )
                : null,
            onChanged: (value) {
              setState(() {}); // Update to show/hide clear button
              
              // Cancel previous timer
              _debounceTimer?.cancel();
              
              // Clear search immediately when empty
              if (value.isEmpty) {
                widget.onChanged('');
                _updateSuggestions();
                return;
              }
              
              // Debounce search for 400ms
              _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                widget.onChanged(value);
              });
              
              // Update suggestions immediately for better UX
              _updateSuggestions();
            },
            onSubmitted: (value) {
              _focusNode.unfocus();
              if (value.isNotEmpty) {
                SearchHistoryService.addToHistory(value);
                _loadSearchHistory();
              }
            },
          ),
          // Search results counter
          if (widget.resultCount != null && widget.controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${widget.resultCount} نتيجة',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
