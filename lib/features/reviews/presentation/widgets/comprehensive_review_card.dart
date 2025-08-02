import 'package:flutter/material.dart';
import '../../data/models/review_model.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/loading_widget.dart';

class ComprehensiveReviewCard extends StatefulWidget {
  final ReviewModel review;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final VoidCallback? onReply;
  final Function(ReviewPhoto)? onPhotoTap;
  final bool showDimensions;
  final bool showPhotos;
  final bool showBadges;
  final bool showResponses;
  final bool isExpanded;

  const ComprehensiveReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
    this.onReport,
    this.onReply,
    this.onPhotoTap,
    this.showDimensions = true,
    this.showPhotos = true,
    this.showBadges = true,
    this.showResponses = true,
    this.isExpanded = false,
  });

  @override
  State<ComprehensiveReviewCard> createState() =>
      _ComprehensiveReviewCardState();
}

class _ComprehensiveReviewCardState extends State<ComprehensiveReviewCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showAllPhotos = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildRatingSection(),
          if (widget.review.title != null) _buildTitle(),
          if (widget.review.content != null) _buildContent(),
          if (widget.showDimensions && widget.review.hasMultipleDimensions)
            _buildDimensionsSection(),
          if (widget.showPhotos && widget.review.hasPhotos)
            _buildPhotosSection(),
          _buildTagsSection(),
          _buildFooter(),
          if (widget.showResponses && widget.review.hasResponses)
            _buildResponsesSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.review.reviewerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.review.isVerifiedPurchase) ...[
                      const SizedBox(width: 8),
                      _buildVerifiedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.review.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (widget.review.isRecommended) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.thumb_up,
                        size: 12,
                        color: ColorConstants.successColor,
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 10,
                          color: ColorConstants.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (widget.showBadges && widget.review.reviewerBadges.isNotEmpty)
            _buildTrustBadges(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
          backgroundImage: widget.review.reviewerAvatar != null
              ? NetworkImage(widget.review.reviewerAvatar!)
              : null,
          child: widget.review.reviewerAvatar == null
              ? Text(
                  widget.review.reviewerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                )
              : null,
        ),
        if (widget.review.isVerifiedPurchase)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ColorConstants.successColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ColorConstants.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ColorConstants.successColor, width: 1),
      ),
      child: const Text(
        'VERIFIED',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: ColorConstants.successColor,
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    final badges = widget.review.reviewerBadges.take(3).toList();
    return Row(
      children: badges.map((badge) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(int.parse(badge.color.replaceFirst('#', '0xFF'))),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            size: 12,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStarRating(widget.review.overallRating),
          const SizedBox(width: 8),
          Text(
            widget.review.overallRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.review.ratingText,
            style: TextStyle(
              fontSize: 14,
              color: _getRatingColor(widget.review.overallRating),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            size: 16,
            color: Colors.amber,
          );
        } else if (index < rating) {
          return const Icon(
            Icons.star_half,
            size: 16,
            color: Colors.amber,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: 16,
            color: Colors.grey.shade400,
          );
        }
      }),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        widget.review.title!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final content = widget.review.content!;
    final isLongContent = content.length > 200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isExpanded || !isLongContent
                ? content
                : '${content.substring(0, 200)}...',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (isLongContent)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDimensionsSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _isExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detailed Ratings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.review.dimensions.map((dimension) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDimensionBar(dimension),
                    );
                  }),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDimensionBar(ReviewDimension dimension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dimension.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              dimension.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: _getRatingColor(dimension.rating),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: dimension.rating / dimension.maxRating,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getRatingColor(dimension.rating),
          ),
        ),
        if (dimension.comment != null) ...[
          const SizedBox(height: 4),
          Text(
            dimension.comment!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotosSection() {
    final photos = widget.review.photos;
    final displayPhotos = _showAllPhotos ? photos : photos.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos (${photos.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayPhotos.map((photo) {
              return GestureDetector(
                onTap: () => widget.onPhotoTap?.call(photo),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo.thumbnailUrl ?? photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SkeletonLoader(
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (photos.length > 3)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllPhotos = !_showAllPhotos;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _showAllPhotos
                      ? 'Show less'
                      : 'View all ${photos.length} photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.review.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.review.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onHelpful,
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Helpful (${widget.review.helpfulCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: widget.onReply,
            child: Row(
              children: [
                Icon(
                  Icons.reply_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onReport,
            child: Icon(
              Icons.flag_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Responses',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ...widget.review.responses.map((response) {
            return _buildResponseItem(response);
          }),
        ],
      ),
    );
  }

  Widget _buildResponseItem(ReviewResponse response) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: response.isOwnerResponse
            ? Border.all(
                color: ColorConstants.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: response.isOwnerResponse
                    ? ColorConstants.primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                backgroundImage: response.responderAvatar != null
                    ? NetworkImage(response.responderAvatar!)
                    : null,
                child: response.responderAvatar == null
                    ? Text(
                        response.responderName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: response.isOwnerResponse
                              ? ColorConstants.primaryColor
                              : Colors.grey.shade600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          response.responderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (response.isOwnerResponse) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ColorConstants.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatResponseTime(response.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return ColorConstants.successColor;
    if (rating >= 3.0) return ColorConstants.warningColor;
    return ColorConstants.errorColor;
  }

  String _formatResponseTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
