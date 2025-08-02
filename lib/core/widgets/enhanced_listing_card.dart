import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';

class EnhancedListingCard extends StatefulWidget {
  final ListingModel listing;
  final Function(bool)? onStatusChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onViewAnalytics;
  final bool showBulkSelection;
  final bool isSelected;
  final Function(bool)? onSelectionChanged;

  const EnhancedListingCard({
    super.key,
    required this.listing,
    this.onStatusChanged,
    this.onEdit,
    this.onDuplicate,
    this.onViewAnalytics,
    this.showBulkSelection = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<EnhancedListingCard> createState() => _EnhancedListingCardState();
}

class _EnhancedListingCardState extends State<EnhancedListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _isActive = widget.listing.isAvailable;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: () => _handleCardTap(),
            onLongPress: widget.showBulkSelection ? null : _showOptionsMenu,
            child: Card(
              elevation: widget.isSelected ? 8 : 2,
              shadowColor: widget.isSelected
                  ? ColorConstants.primaryColor.withAlpha(100)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: widget.isSelected
                    ? const BorderSide(
                        color: ColorConstants.primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  _buildContentSection(),
                  _buildActionSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: widget.listing.imageUrls.isNotEmpty
                ? Image.network(
                    widget.listing.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
        ),

        // Top overlay with status and selection
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bulk selection checkbox
              if (widget.showBulkSelection)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: widget.onSelectionChanged != null
                        ? (bool? value) =>
                            widget.onSelectionChanged!(value ?? false)
                        : null,
                    activeColor: ColorConstants.primaryColor,
                  ),
                ),

              const Spacer(),

              // Active/Inactive Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isActive ? Colors.white : Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isActive ? Icons.visibility : Icons.visibility_off,
                      size: 14,
                      color: _isActive
                          ? ColorConstants.successColor
                          : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: _isActive,
                      onChanged: _handleStatusChange,
                      activeColor: ColorConstants.successColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Image count indicator
        if (widget.listing.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.listing.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: ColorConstants.lightGrey,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: ColorConstants.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: ColorConstants.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.listing.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.listing.categoryName ?? 'Uncategorized',
                      style: const TextStyle(
                        color: ColorConstants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${widget.listing.pricePerDay.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.textColor,
                        ),
                  ),
                  const Text(
                    'per day',
                    style: TextStyle(
                      color: ColorConstants.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Metrics Row
          _buildMetricsRow(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    // Mock metrics - in real app these would come from the listing model or API
    const utilizationRate = 78; // Mock utilization percentage
    const rating = 4.8; // Mock rating
    const monthlyEarnings = 340; // Mock monthly earnings

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              icon: Icons.donut_small,
              label: 'Utilization',
              value: '$utilizationRate%',
              color: _getUtilizationColor(utilizationRate),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withAlpha(50),
          ),
          Expanded(
            child: _buildMetricItem(
              icon: Icons.star,
              label: 'Rating',
              value: rating.toString(),
              color: ColorConstants.warningColor,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withAlpha(50),
          ),
          Expanded(
            child: _buildMetricItem(
              icon: Icons.attach_money,
              label: 'This Month',
              value: '\$$monthlyEarnings',
              color: ColorConstants.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ColorConstants.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onEdit ??
                  () => context.go('/edit-listing/${widget.listing.id}'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                side: const BorderSide(color: ColorConstants.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onDuplicate ?? _handleDuplicate,
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Duplicate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.grey,
                side: BorderSide(color: ColorConstants.grey.withAlpha(150)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUtilizationColor(int utilization) {
    if (utilization >= 80) return ColorConstants.successColor;
    if (utilization >= 60) return ColorConstants.warningColor;
    return ColorConstants.errorColor;
  }

  void _handleCardTap() {
    if (widget.showBulkSelection) {
      widget.onSelectionChanged?.call(!widget.isSelected);
    } else {
      context.go('/listing/${widget.listing.id}');
    }
  }

  void _handleStatusChange(bool value) {
    setState(() {
      _isActive = value;
    });
    widget.onStatusChanged?.call(value);
  }

  void _handleDuplicate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating "${widget.listing.name}"...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () =>
              context.go('/create-listing?duplicate=${widget.listing.id}'),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Listing'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) {
                  widget.onEdit!();
                } else {
                  context.go('/edit-listing/${widget.listing.id}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handleDuplicate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onViewAnalytics != null) {
                  widget.onViewAnalytics!();
                }
              },
            ),
            ListTile(
              leading: Icon(
                _isActive ? Icons.visibility_off : Icons.visibility,
                color: _isActive
                    ? ColorConstants.errorColor
                    : ColorConstants.successColor,
              ),
              title: Text(_isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handleStatusChange(!_isActive);
              },
            ),
          ],
        ),
      ),
    );
  }
}
