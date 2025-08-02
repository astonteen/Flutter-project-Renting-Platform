import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';

import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/listing/data/repositories/listing_repository.dart';

enum PortfolioView { overview, performance, categories }

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PortfolioView _currentView = PortfolioView.overview;

  final TextEditingController _searchController = TextEditingController();
  String? _swipedListingId;

  Map<String, Map<String, dynamic>> _listingStats = {};
  Map<String, dynamic> _portfolioOverview = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPortfolioData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentView = PortfolioView.overview;
          break;
        case 1:
          _currentView = PortfolioView.performance;
          break;
        case 2:
          _currentView = PortfolioView.categories;
          break;
      }
      _swipedListingId = null;
    });
  }

  Future<void> _loadPortfolioData() async {
    try {
      // Load listings first
      if (!mounted) return;
      context.read<ListingBloc>().add(LoadMyListings());

      // Wait for listings to load, then load portfolio stats
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadPortfolioAnalytics() async {
    try {
      // Get portfolio overview statistics
      final portfolioStats =
          await getIt<ListingRepository>().getPortfolioStatistics();

      // Get current listings to calculate individual stats
      if (!mounted) return;
      final state = context.read<ListingBloc>().state;
      if (state is MyListingsLoaded) {
        final listingIds = state.listings.map((l) => l.id).toList();
        final listingStats =
            await getIt<ListingRepository>().getListingStatistics(listingIds);

        if (mounted) {
          setState(() {
            _portfolioOverview = {
              'totalListings': state.listings.length,
              'totalEarnings': portfolioStats['totalEarnings'] ?? 0.0,
              'activeBookings': portfolioStats['activeBookings'] ?? 0,
              'avgRating': portfolioStats['avgRating'] ?? 0.0,
            };
            _listingStats = listingStats;
          });
        }
      }
    } catch (e) {
      if (mounted) {}
    }
  }

  void _dismissSwipe() {
    setState(() {
      _swipedListingId = null;
    });
  }

  List<ListingModel> _getFilteredListings(List<ListingModel> listings) {
    switch (_currentView) {
      case PortfolioView.performance:
        // Sort by performance metrics (total earnings, booking count)
        final sortedListings = List<ListingModel>.from(listings);
        sortedListings.sort((a, b) {
          final aStats =
              _listingStats[a.id] ?? {'totalEarnings': 0.0, 'totalBookings': 0};
          final bStats =
              _listingStats[b.id] ?? {'totalEarnings': 0.0, 'totalBookings': 0};
          return (bStats['totalEarnings'] as double)
              .compareTo(aStats['totalEarnings'] as double);
        });
        return sortedListings;
      case PortfolioView.categories:
        // Sort by category name then by item name
        final sortedListings = List<ListingModel>.from(listings);
        sortedListings.sort((a, b) {
          final categoryComparison =
              (a.categoryName ?? '').compareTo(b.categoryName ?? '');
          if (categoryComparison != 0) return categoryComparison;
          return a.name.compareTo(b.name);
        });
        return sortedListings;
      case PortfolioView.overview:
        return listings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Column(
        children: [
          // Modern Portfolio Header - extends to top of screen
          _buildPortfolioHeader(),

          // Tab Content
          Expanded(
            child: BlocConsumer<ListingBloc, ListingState>(
              listener: (context, state) {
                if (state is MyListingsLoaded) {
                  // Load real analytics data
                  _loadPortfolioAnalytics();
                }
              },
              builder: (context, state) {
                if (state is ListingLoading) {
                  return const LoadingWidget();
                }

                if (state is ListingError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: _loadPortfolioData,
                  );
                }

                if (state is MyListingsLoaded) {
                  final allListings = state.listings;
                  final filteredListings = _getFilteredListings(allListings);

                  return Column(
                    children: [
                      // Enhanced Tab Bar
                      _buildModernTabBar(allListings),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewContent(filteredListings),
                            _buildPerformanceContent(filteredListings),
                            _buildCategoriesContent(filteredListings),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-listing'),
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
    );
  }

  Widget _buildPortfolioHeader() {
    final totalListings = _portfolioOverview['totalListings'] ?? 0;
    final totalEarnings = _portfolioOverview['totalEarnings'] ?? 0.0;
    final activeBookings = _portfolioOverview['activeBookings'] ?? 0;
    final avgRating = _portfolioOverview['avgRating'] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryColor,
            ColorConstants.primaryColor.withAlpha(204),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Portfolio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: SpacingConstants.xs),
                      Text(
                        'Manage your rental inventory',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Metrics grid
            Row(
              children: [
                _buildMetricCard(
                  icon: Icons.inventory_2,
                  value: totalListings.toString(),
                  label: 'Total Items',
                  color: Colors.white,
                ),
                const SizedBox(width: SpacingConstants.md),
                _buildMetricCard(
                  icon: Icons.attach_money,
                  value: '\$${totalEarnings.toStringAsFixed(0)}',
                  label: 'Total Earnings',
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.trending_up,
                  value: activeBookings.toString(),
                  label: 'Active Bookings',
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.star,
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                  label: 'Avg Rating',
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withAlpha(204),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableListingCard(ListingModel listing) {
    final isSwiped = _swipedListingId == listing.id;
    final swipeOffset = isSwiped ? -120.0 : 0.0;

    return GestureDetector(
      onTap: () {
        if (isSwiped) {
          _dismissSwipe();
        } else {
          _showListingDetails(listing);
        }
      },
      child: Stack(
        children: [
          // Background actions
          if (isSwiped)
            Positioned(
              right: 0,
              top: 0,
              bottom: 12,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _dismissSwipe();
                        _editListing(listing);
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _dismissSwipe();
                        _showDeleteConfirmation(listing);
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Main card
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -500 && !isSwiped) {
                // Swiped left - show actions
                setState(() {
                  _swipedListingId = listing.id;
                });
              } else if (details.primaryVelocity! > 500 && isSwiped) {
                // Swiped right - dismiss actions
                _dismissSwipe();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(swipeOffset, 0, 0),
              child: _buildListingCard(listing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    final isSwiped = _swipedListingId == listing.id;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacingConstants.md),
      elevation: ElevationConstants.low,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusConstants.radiusMedium),
      child: Container(
        padding: SpacingConstants.paddingMD,
        decoration: BoxDecoration(
          borderRadius: BorderRadiusConstants.radiusMedium,
          border: isSwiped
              ? Border.all(color: ColorConstants.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadiusConstants.radiusSmall,
              child: SizedBox(
                width: 80,
                height: 80,
                child: listing.primaryImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.primaryImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.name,
                          style: const TextStyle(
                            fontSize: FontSizeConstants.subtitle,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(listing),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${listing.pricePerDay.toStringAsFixed(0)}/day',
                    style: const TextStyle(
                      fontSize: FontSizeConstants.body,
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: SpacingConstants.xs),
                      Text('${_getViewCount(listing)} views',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: SpacingConstants.md),
                      if (_getPendingBookingsCount(listing) > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadiusConstants.radiusSmall,
                          ),
                          child: Text(
                            '${_getPendingBookingsCount(listing)} pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (_getActiveBookingsCount(listing) > 0) ...[
                        const SizedBox(width: SpacingConstants.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadiusConstants.radiusSmall,
                          ),
                          child: Text(
                            '${_getActiveBookingsCount(listing)} active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_getTotalEarnings(listing) > 0)
                    Text(
                      'Earned: \$${_getTotalEarnings(listing).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ListingModel listing) {
    final isActive = listing.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Rented',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for listing statistics
  int _getPendingBookingsCount(ListingModel listing) {
    return _listingStats[listing.id]?['pendingBookings'] ?? 0;
  }

  int _getActiveBookingsCount(ListingModel listing) {
    return _listingStats[listing.id]?['activeBookings'] ?? 0;
  }

  double _getTotalEarnings(ListingModel listing) {
    return _listingStats[listing.id]?['totalEarnings'] ?? 0.0;
  }

  int _getViewCount(ListingModel listing) {
    return _listingStats[listing.id]?['viewCount'] ?? 0;
  }

  void _showListingDetails(ListingModel listing) {
    // Navigate to booking management screen for owners
    context.pushNamed(
      'booking-management',
      pathParameters: {'listingId': listing.id},
      extra: listing,
    );
  }

  void _editListing(ListingModel listing) {
    // TODO: Navigate to edit listing screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit listing feature coming soon')),
    );
  }

  void _showDeleteConfirmation(ListingModel listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${listing.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteListing(listing);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteListing(ListingModel listing) {
    context.read<ListingBloc>().add(DeleteListing(listing.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${listing.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  Widget _buildOverviewContent(List<ListingModel> filteredListings) {
    if (filteredListings.isEmpty) {
      return _buildEmptyPortfolioState();
    }

    return Container(
      color: ColorConstants.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async => _loadPortfolioData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredListings.length,
          itemBuilder: (context, index) {
            final listing = filteredListings[index];
            return _buildSwipeableListingCard(listing);
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceContent(List<ListingModel> filteredListings) {
    if (filteredListings.isEmpty) {
      return _buildEmptyPortfolioState();
    }

    // Sort listings by total earnings (highest first)
    final sortedByPerformance = List<ListingModel>.from(filteredListings);
    sortedByPerformance.sort((a, b) {
      final aEarnings = _listingStats[a.id]?['totalEarnings'] as double? ?? 0.0;
      final bEarnings = _listingStats[b.id]?['totalEarnings'] as double? ?? 0.0;
      return bEarnings.compareTo(aEarnings);
    });

    return Container(
      color: ColorConstants.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async => _loadPortfolioData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedByPerformance.length,
          itemBuilder: (context, index) {
            final listing = sortedByPerformance[index];
            return _buildPerformanceListingCard(listing, index + 1);
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceListingCard(ListingModel listing, int rank) {
    final stats = _listingStats[listing.id];
    final totalEarnings = stats?['totalEarnings'] as double? ?? 0.0;
    final activeBookings = stats?['activeBookings'] as int? ?? 0;
    final totalBookings = stats?['totalBookings'] as int? ?? 0;

    // Determine performance level
    String performanceLevel = 'Low';
    Color performanceColor = Colors.grey;
    IconData performanceIcon = Icons.trending_down;

    if (totalEarnings > 500) {
      performanceLevel = 'High';
      performanceColor = Colors.green;
      performanceIcon = Icons.trending_up;
    } else if (totalEarnings > 100) {
      performanceLevel = 'Medium';
      performanceColor = Colors.orange;
      performanceIcon = Icons.trending_flat;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewListingDetails(listing),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rank <= 3 ? ColorConstants.primaryColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Listing image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: listing.primaryImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.primaryImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.inventory_2, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),

              // Listing details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          performanceIcon,
                          size: 16,
                          color: performanceColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          performanceLevel,
                          style: TextStyle(
                            fontSize: 14,
                            color: performanceColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listing.categoryName ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${totalEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalBookings bookings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (activeBookings > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ColorConstants.primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$activeBookings active',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ColorConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesContent(List<ListingModel> filteredListings) {
    if (filteredListings.isEmpty) {
      return _buildEmptyPortfolioState();
    }

    // Group listings by category
    final categorizedListings = <String, List<ListingModel>>{};
    for (final listing in filteredListings) {
      final categoryName = listing.categoryName ?? 'Uncategorized';
      categorizedListings.putIfAbsent(categoryName, () => []).add(listing);
    }

    // Sort categories alphabetically
    final sortedCategories = categorizedListings.keys.toList()..sort();

    return Container(
      color: ColorConstants.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async => _loadPortfolioData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final categoryName = sortedCategories[index];
            final categoryListings = categorizedListings[categoryName]!;

            return _buildCategorySection(categoryName, categoryListings);
          },
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String categoryName, List<ListingModel> listings) {
    // Calculate category stats
    final totalEarnings = listings.fold(
        0.0,
        (sum, listing) =>
            sum + (_listingStats[listing.id]?['totalEarnings'] ?? 0.0));
    final activeBookings = listings.fold(
        0,
        (sum, listing) =>
            sum +
            ((_listingStats[listing.id]?['activeBookings'] as int?) ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorConstants.primaryColor.withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(categoryName),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    Text(
                      '${listings.length} items • \$${totalEarnings.toStringAsFixed(0)} earned • $activeBookings active',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.primaryColor.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category listings
        ...listings.map((listing) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSwipeableListingCard(listing),
            )),

        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'sports':
      case 'sports & recreation':
        return Icons.sports_soccer;
      case 'tools':
      case 'tools & equipment':
        return Icons.build;
      case 'vehicles':
      case 'automotive':
        return Icons.directions_car;
      case 'furniture':
      case 'home & garden':
        return Icons.chair;
      case 'clothing':
      case 'fashion':
        return Icons.checkroom;
      case 'books':
      case 'education':
        return Icons.book;
      case 'music':
      case 'musical instruments':
        return Icons.music_note;
      case 'cameras':
      case 'photography':
        return Icons.camera_alt;
      case 'games':
      case 'gaming':
        return Icons.games;
      default:
        return Icons.category;
    }
  }

  Widget _buildEmptyPortfolioState() {
    String title, subtitle;
    IconData icon;

    switch (_currentView) {
      case PortfolioView.performance:
        title = 'No Active Listings';
        subtitle = 'Your active listings will appear here';
        icon = Icons.check_circle_outline;
        break;
      case PortfolioView.categories:
        title = 'No Rented Items';
        subtitle = 'Items currently being rented will appear here';
        icon = Icons.schedule;
        break;
      case PortfolioView.overview:
        title = 'No Listings Yet';
        subtitle = 'Start by creating your first listing';
        icon = Icons.inventory_2_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentView == PortfolioView.overview) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/create-listing'),
                icon: const Icon(Icons.add),
                label: const Text('Create Listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar(List<ListingModel> allListings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: ColorConstants.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: ColorConstants.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(
            text: 'Overview',
            icon: Icon(Icons.dashboard),
          ),
          Tab(
            text: 'Performance',
            icon: Icon(Icons.trending_up),
          ),
          Tab(
            text: 'Categories',
            icon: Icon(Icons.category),
          ),
        ],
      ),
    );
  }

  void _viewListingDetails(ListingModel listing) {
    context.pushNamed(
      'listing-details',
      pathParameters: {'listingId': listing.id},
      extra: listing,
    );
  }
}
