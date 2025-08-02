import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class StarRatingWidget extends StatefulWidget {
  final double rating;
  final int maxStars;
  final double size;
  final bool allowRating;
  final Function(int)? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final MainAxisAlignment alignment;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 24.0,
    this.allowRating = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  void _onStarTapped(int index) {
    if (!widget.allowRating) return;

    setState(() {
      _currentRating = (index + 1).toDouble();
    });

    widget.onRatingChanged?.call(index + 1);
  }

  Widget _buildStar(int index) {
    final starValue = index + 1;
    final difference = _currentRating - starValue;

    IconData icon;
    Color color;

    if (difference >= 0) {
      // Full star
      icon = Icons.star;
      color = widget.activeColor ?? ColorConstants.warningColor;
    } else if (difference > -1) {
      // Half star
      icon = Icons.star_half;
      color = widget.activeColor ?? ColorConstants.warningColor;
    } else {
      // Empty star
      icon = Icons.star_border;
      color = widget.inactiveColor ?? Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: widget.allowRating ? () => _onStarTapped(index) : null,
      child: Icon(
        icon,
        size: widget.size,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.maxStars,
        (index) => _buildStar(index),
      ),
    );
  }
}

// Widget for displaying rating with text
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final double fontSize;
  final Color? textColor;
  final MainAxisAlignment alignment;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 16.0,
    this.fontSize = 14.0,
    this.textColor,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRatingWidget(
          rating: rating,
          size: starSize,
          allowRating: false,
        ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor ?? ColorConstants.primaryTextColor,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: ColorConstants.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }
}

// Interactive rating widget for user input
class InteractiveStarRating extends StatelessWidget {
  final String title;
  final int currentRating;
  final Function(int) onRatingChanged;
  final String? description;

  const InteractiveStarRating({
    super.key,
    required this.title,
    required this.currentRating,
    required this.onRatingChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryTextColor,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: const TextStyle(
              fontSize: 14,
              color: ColorConstants.secondaryTextColor,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            StarRatingWidget(
              rating: currentRating.toDouble(),
              size: 32,
              allowRating: true,
              onRatingChanged: onRatingChanged,
              alignment: MainAxisAlignment.start,
            ),
            const SizedBox(width: 12),
            Text(
              _getRatingText(currentRating),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorConstants.secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }
}
