import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:rent_ease/features/home/data/repositories/home_repository.dart';
import 'package:rent_ease/features/rental/presentation/bloc/item_details_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/features/rental/presentation/screens/booking_screen.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/wishlist/data/repositories/wishlist_repository.dart';
import 'package:rent_ease/features/wishlist/data/repositories/viewed_items_repository.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemDetailsBloc(
        homeRepository: context.read<HomeRepository>(),
      )..add(LoadItemDetails(itemId)),
      child: ItemDetailsView(itemId: itemId),
    );
  }
}

class ItemDetailsView extends StatefulWidget {
  final String itemId;

  const ItemDetailsView({
    super.key,
    required this.itemId,
  });

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _recordView();
  }

  Future<void> _checkIfLiked() async {
    final isLiked =
        await getIt<WishlistRepository>().isInWishlist(widget.itemId);
    if (mounted) {
      setState(() {
        _isLiked = isLiked;
      });
    }
  }

  Future<void> _recordView() async {
    await getIt<ViewedItemsRepository>().recordView(widget.itemId);
  }

  Future<void> _toggleLike() async {
    if (_isLiked) {
      await getIt<WishlistRepository>().removeFromWishlist(widget.itemId);
    } else {
      await getIt<WishlistRepository>().addToWishlist(widget.itemId);
    }
    if (mounted) {
      setState(() {
        _isLiked = !_isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDetailsBloc, ItemDetailsState>(
      builder: (context, state) {
        if (state is ItemDetailsLoading) {
          return const Scaffold(
            body: LoadingWidget(),
          );
        }

        if (state is ItemDetailsError) {
          return Scaffold(
            body: CustomErrorWidget(
              message: state.message,
              onRetry: () {
                context
                    .read<ItemDetailsBloc>()
                    .add(LoadItemDetails(widget.itemId));
              },
            ),
          );
        }

        if (state is ItemDetailsLoaded) {
          return _buildItemDetails(context, state.item);
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildItemDetails(BuildContext context, RentalItemModel item) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, item),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildItemInfo(context, item),
                _buildDescription(context, item),
                _buildOwnerInfo(context, item),
                _buildPricing(context, item),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, item),
    );
  }

  Widget _buildAppBar(BuildContext context, RentalItemModel item) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(item),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
        IconButton(
          icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
          color: _isLiked ? Colors.pink : null,
          onPressed: _toggleLike,
        ),
      ],
    );
  }

  Widget _buildImageGallery(RentalItemModel item) {
    if (item.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: item.imageUrls.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(item.imageUrls[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemInfo(BuildContext context, RentalItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (item.location != null)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatingDisplay(item),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.available ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.available ? 'Available' : 'Not Available',
                  style: TextStyle(
                    color: item.available ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDisplay(RentalItemModel item) {
    if (item.rating == null || item.rating == 0) {
      return Text(
        'No reviews yet',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber[600],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${item.rating!.toStringAsFixed(1)} (${item.reviewCount ?? 0} reviews)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, RentalItemModel item) {
    if (item.description == null || item.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(BuildContext context, RentalItemModel item) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ColorConstants.primaryColor,
            child: Text(
              (item.ownerName?.isNotEmpty == true)
                  ? item.ownerName![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ownerName ?? 'Unknown Owner',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner since 2023',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Navigate to chat with owner
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ColorConstants.primaryColor),
                foregroundColor: ColorConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: const Text(
                'Message',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(BuildContext context, RentalItemModel item) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Per day',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                item.formattedPricePerDay,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (item.securityDeposit != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security deposit',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${item.securityDeposit!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, RentalItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.formattedPricePerDay,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'per day',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: 'Book Now',
              onPressed: () {
                // Navigate to booking screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(item: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
