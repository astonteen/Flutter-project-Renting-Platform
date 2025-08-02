import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class SearchFilterWidget extends StatefulWidget {
  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters initialFilters;

  const SearchFilterWidget({
    super.key,
    required this.onFiltersChanged,
    required this.initialFilters,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late SearchFilters _filters;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _minPriceController.text = _filters.minPrice?.toString() ?? '';
    _maxPriceController.text = _filters.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Range
          _buildPriceRangeSection(),
          const SizedBox(height: 24),

          // Distance
          _buildDistanceSection(),
          const SizedBox(height: 24),

          // Availability
          _buildAvailabilitySection(),
          const SizedBox(height: 24),

          // Item Condition
          _buildConditionSection(),
          const SizedBox(height: 24),

          // Rating
          _buildRatingSection(),
          const SizedBox(height: 24),

          // Sort By
          _buildSortBySection(),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (per day)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  _filters = _filters.copyWith(
                    minPrice: double.tryParse(value),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  _filters = _filters.copyWith(
                    maxPrice: double.tryParse(value),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick price presets
        Wrap(
          spacing: 8,
          children: [
            _buildPricePreset('Under \$10', 0, 10),
            _buildPricePreset('\$10-\$25', 10, 25),
            _buildPricePreset('\$25-\$50', 25, 50),
            _buildPricePreset('\$50+', 50, null),
          ],
        ),
      ],
    );
  }

  Widget _buildPricePreset(String label, double min, double? max) {
    final isSelected = _filters.minPrice == min && _filters.maxPrice == max;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filters = _filters.copyWith(minPrice: min, maxPrice: max);
            _minPriceController.text = min.toString();
            _maxPriceController.text = max?.toString() ?? '';
          });
        }
      },
      selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: ColorConstants.primaryColor,
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Within ${_filters.radiusKm.round()} km',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _filters.radiusKm,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: ColorConstants.primaryColor,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(radiusKm: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _filters.availableFrom != null
                            ? _formatDate(_filters.availableFrom!)
                            : 'Select date',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _filters.availableTo != null
                            ? _formatDate(_filters.availableTo!)
                            : 'Select date',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Condition',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ItemCondition.values.map((condition) {
            final isSelected = _filters.conditions.contains(condition);
            return FilterChip(
              label: Text(condition.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters = _filters.copyWith(
                      conditions: [..._filters.conditions, condition],
                    );
                  } else {
                    _filters = _filters.copyWith(
                      conditions: _filters.conditions
                          .where((c) => c != condition)
                          .toList(),
                    );
                  }
                });
              },
              selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: ColorConstants.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _filters.minRating >= rating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _filters = _filters.copyWith(
                    minRating: rating.toDouble(),
                  );
                });
              },
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: isSelected ? Colors.amber : Colors.grey,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSortBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: SortBy.values.map((sortBy) {
            final isSelected = _filters.sortBy == sortBy;
            return FilterChip(
              label: Text(sortBy.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _filters = _filters.copyWith(sortBy: sortBy);
                  });
                }
              },
              selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: ColorConstants.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? _filters.availableFrom ?? DateTime.now()
          : _filters.availableTo ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _filters = _filters.copyWith(availableFrom: picked);
        } else {
          _filters = _filters.copyWith(availableTo: picked);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _filters = SearchFilters();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }
}

// Search Filters Model
class SearchFilters {
  final double? minPrice;
  final double? maxPrice;
  final double radiusKm;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final List<ItemCondition> conditions;
  final double minRating;
  final SortBy sortBy;

  SearchFilters({
    this.minPrice,
    this.maxPrice,
    this.radiusKm = 10.0,
    this.availableFrom,
    this.availableTo,
    this.conditions = const [],
    this.minRating = 0.0,
    this.sortBy = SortBy.relevance,
  });

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? radiusKm,
    DateTime? availableFrom,
    DateTime? availableTo,
    List<ItemCondition>? conditions,
    double? minRating,
    SortBy? sortBy,
  }) {
    return SearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      radiusKm: radiusKm ?? this.radiusKm,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      conditions: conditions ?? this.conditions,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return minPrice != null ||
        maxPrice != null ||
        radiusKm != 10.0 ||
        availableFrom != null ||
        availableTo != null ||
        conditions.isNotEmpty ||
        minRating > 0.0 ||
        sortBy != SortBy.relevance;
  }
}

// Enums
enum ItemCondition {
  excellent,
  good,
  fair,
  poor;

  String get displayName {
    switch (this) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}

enum SortBy {
  relevance,
  priceAsc,
  priceDesc,
  rating,
  distance,
  newest;

  String get displayName {
    switch (this) {
      case SortBy.relevance:
        return 'Relevance';
      case SortBy.priceAsc:
        return 'Price: Low to High';
      case SortBy.priceDesc:
        return 'Price: High to Low';
      case SortBy.rating:
        return 'Rating';
      case SortBy.distance:
        return 'Distance';
      case SortBy.newest:
        return 'Newest';
    }
  }
}
