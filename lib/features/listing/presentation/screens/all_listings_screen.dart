import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

class AllListingsScreen extends StatefulWidget {
  final String? sectionType; // 'featured' or 'near_you'

  const AllListingsScreen({
    super.key,
    this.sectionType,
  });

  @override
  State<AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends State<AllListingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadAllListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllListings() {
    // Load listings based on section type
    switch (widget.sectionType) {
      case 'featured':
        context.read<ListingBloc>().add(const LoadFeaturedListings(limit: 50));
        break;
      case 'near_you':
        // Use available listings for "Near You" section
        // In production, you would implement location-based filtering
        context.read<ListingBloc>().add(const LoadAvailableListings(limit: 50));
        break;
      default:
        context.read<ListingBloc>().add(const LoadAvailableListings(limit: 50));
        break;
    }
  }

  void _onSearchChanged(String query) {
    // Only apply search to available listings, not featured or near_you
    if (widget.sectionType == 'featured' || widget.sectionType == 'near_you') {
      // Featured and Near You listings don't support search, reload listings
      if (query.trim().isEmpty) {
        if (widget.sectionType == 'featured') {
          context
              .read<ListingBloc>()
              .add(const LoadFeaturedListings(limit: 50));
        } else {
          context
              .read<ListingBloc>()
              .add(const LoadAvailableListings(limit: 50));
        }
      }
      return;
    }

    // Use existing LoadAvailableListings event with search query
    context.read<ListingBloc>().add(
          LoadAvailableListings(
            searchQuery: query.trim(),
            categoryId: _selectedCategoryId,
            limit: 50,
          ),
        );
  }

  String _getScreenTitle() {
    switch (widget.sectionType) {
      case 'featured':
        return 'Featured Listings';
      case 'near_you':
        return 'Near You';
      default:
        return 'All Listings';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: (widget.sectionType == 'featured' ||
                widget.sectionType == 'near_you')
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: ColorConstants.primaryColor),
                      ),
                    ),
                  ),
                ),
              ),
      ),
      body: BlocBuilder<ListingBloc, ListingState>(
        builder: (context, state) {
          if (state is ListingLoading) {
            return const LoadingWidget();
          }

          if (state is ListingError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: _loadAllListings,
            );
          }

          // Handle different state types based on section
          List<ListingModel>? listings;
          if (widget.sectionType == 'featured' &&
              state is FeaturedListingsLoaded) {
            listings = state.listings;
          } else if (state is AvailableListingsLoaded) {
            listings = state.listings;
          }

          if (listings != null) {
            return _buildListingsGrid(listings);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildListingsGrid(List<ListingModel> listings) {
    if (listings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadAllListings();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return _buildListingCard(listings[index]);
        },
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (listing.id.isNotEmpty) {
            context.push('/item/${listing.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: listing.primaryImageUrl.isNotEmpty
                      ? Image.network(
                          listing.primaryImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        color: ColorConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No listings found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try searching with different keywords'
                : 'No listings are available at the moment',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllListings,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
