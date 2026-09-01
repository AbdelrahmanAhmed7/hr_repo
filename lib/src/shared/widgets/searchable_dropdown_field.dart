import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SearchableDropdownItem<T> {
  final T value;
  final String label;

  const SearchableDropdownItem({required this.value, required this.label});
}

class SearchableDropdownField<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final String searchHintText;
  final String? hintText;
  final List<SearchableDropdownItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final EdgeInsetsGeometry contentPadding;
  final bool isDense;

  const SearchableDropdownField({
    super.key,
    required this.value,
    this.labelText,
    required this.searchHintText,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = items
        .where((item) => item.value == value)
        .map((item) => item.label)
        .firstOrNull;

    return InkWell(
      onTap: () => _showOptionsSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: contentPadding,
          isDense: isDense,
          suffixIcon: const Icon(Icons.search_rounded),
        ),
        child: Text(
          selectedLabel ?? hintText ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selectedLabel == null
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SearchableDropdownSheet<T>(
          title: labelText ?? hintText ?? searchHintText,
          searchHintText: searchHintText,
          value: value,
          items: items,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  final String title;
  final String searchHintText;
  final T? value;
  final List<SearchableDropdownItem<T?>> items;
  final ValueChanged<T?> onChanged;

  const _SearchableDropdownSheet({
    required this.title,
    required this.searchHintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredItems = normalizedQuery.isEmpty
        ? widget.items
        : widget.items
              .where(
                (item) => item.label.toLowerCase().contains(normalizedQuery),
              )
              .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.searchHintText,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'مسح البحث',
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: filteredItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('لا توجد نتائج'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = item.value == widget.value;

                            return ListTile(
                              title: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () {
                                widget.onChanged(item.value);
                                Navigator.of(context).pop();
                              },
                            );
                          },
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
