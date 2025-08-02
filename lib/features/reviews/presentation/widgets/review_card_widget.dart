import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/reviews/data/models/review_model.dart';

class ReviewCardWidget extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onMarkHelpful;
  final VoidCallback? onReport;
  final VoidCallback? onReply;
  final bool showOwnerResponse;
  final bool showDetailedRatings;

  const ReviewCardWidget({
    super.key,
    required this.review,
    this.onMarkHelpful,
    this.onReport,
    this.onReply,
    this.showOwnerResponse = true,
    this.showDetailedRatings = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewHeader(context),
            const SizedBox(height: 12),
            _buildRatingSection(context),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCommentSection(context),
            ],
            if (review.hasPhotos) ...[
              const SizedBox(height: 12),
              _buildPhotosSection(context),
            ],
            const SizedBox(height: 12),
            _buildActionSection(context),
            if (showOwnerResponse && review.hasOwnerResponse) ...[
              const SizedBox(height: 16),
              _buildOwnerResponseSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
          child: Text(
            review.reviewerId.substring(0, 2).toUpperCase(),
            style: const TextStyle(
              color: ColorConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Anonymous User', // In real app, would show reviewer name
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  if (review.isVerifiedRental)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 0.5),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                review.timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall rating
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.overallRating.round()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber[600],
                  size: 20,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              review.ratingDisplayText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),

        // Detailed ratings
        if (showDetailedRatings && review.hasDetailedRatings) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (review.conditionAccuracyRating != null)
                  _buildDetailedRatingRow(
                    'Item Condition',
                    review.conditionAccuracyRating!,
                    Icons.verified,
                  ),
                if (review.communicationRating != null)
                  _buildDetailedRatingRow(
                    'Communication',
                    review.communicationRating!,
                    Icons.chat,
                  ),
                if (review.deliveryExperienceRating != null)
                  _buildDetailedRatingRow(
                    'Delivery Experience',
                    review.deliveryExperienceRating!,
                    Icons.local_shipping,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedRatingRow(String label, double rating, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber[600],
                size: 14,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        review.comment,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${review.photoUrls.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: review.photoUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.photoUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Row(
      children: [
        if (review.helpfulVotes > 0) ...[
          Text(
            '${review.helpfulVotes} found this helpful',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(child: Container()),
        TextButton.icon(
          onPressed: onMarkHelpful,
          icon: const Icon(Icons.thumb_up_outlined, size: 16),
          label: const Text('Helpful'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
        if (onReply != null)
          TextButton.icon(
            onPressed: onReply,
            icon: const Icon(Icons.reply, size: 16),
            label: const Text('Reply'),
            style: TextButton.styleFrom(
              foregroundColor: ColorConstants.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildOwnerResponseSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store,
                size: 16,
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Owner Response',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryColor,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (review.ownerResponseDate != null)
                Text(
                  _formatResponseDate(review.ownerResponseDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.ownerResponse!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report Review'),
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Review'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatResponseDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
