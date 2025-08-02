import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/booking/presentation/bloc/booking_management_bloc.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingManagementScreen extends StatefulWidget {
  final ListingModel listing;

  const BookingManagementScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  BookingFilterCategory? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load bookings for this listing
    context.read<BookingManagementBloc>().add(
          LoadBookingsForListing(widget.listing.id),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    BookingFilterCategory? filter;
    switch (_tabController.index) {
      case 0:
        filter = null; // All
        break;
      case 1:
        // Active: Pending + Confirmed + In Progress
        filter = BookingFilterCategory
            .active; // We'll handle multiple statuses in the bloc
        break;
      case 2:
        // Past: Completed + Cancelled
        filter = BookingFilterCategory
            .past; // We'll handle multiple statuses in the bloc
        break;
    }

    setState(() {
      _currentFilter = filter;
    });

    context.read<BookingManagementBloc>().add(
          FilterBookings(category: filter, searchQuery: _searchController.text),
        );
  }

  void _onSearchChanged(String query) {
    context.read<BookingManagementBloc>().add(
          FilterBookings(category: _currentFilter, searchQuery: query),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocConsumer<BookingManagementBloc, BookingManagementState>(
        listener: (context, state) {
          if (state is BookingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is BookingManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<BookingManagementBloc>().add(
                    RefreshBookings(widget.listing.id),
                  );
            },
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (state is BookingManagementLoading)
                  const SliverFillRemaining(
                    child: LoadingWidget(message: 'Loading bookings...'),
                  )
                else if (state is BookingManagementError)
                  SliverFillRemaining(
                    child: CustomErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<BookingManagementBloc>().add(
                            LoadBookingsForListing(widget.listing.id),
                          ),
                    ),
                  )
                else if (state is BookingManagementLoaded)
                  ..._buildContent(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: ColorConstants.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showMoreOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroSection(),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorConstants.primaryColor,
            ColorConstants.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), // Space for app bar
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: widget.listing.primaryImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.listing.primaryImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.white24,
                                child: const Icon(Icons.image,
                                    color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.white24,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white),
                              ),
                            )
                          : Container(
                              color: Colors.white24,
                              child:
                                  const Icon(Icons.image, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${widget.listing.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BlocBuilder<BookingManagementBloc, BookingManagementState>(
                builder: (context, state) {
                  if (state is BookingManagementLoaded) {
                    return _buildQuickStats(state.statistics);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatItem(
          stats['confirmed_bookings'].toString(),
          'Active',
          Icons.check_circle,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          stats['pending_bookings'].toString(),
          'Pending',
          Icons.schedule,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          '\$${stats['total_revenue'].toStringAsFixed(0)}',
          'Revenue',
          Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent(BookingManagementLoaded state) {
    return [
      // Search and tabs
      SliverPersistentHeader(
        pinned: true,
        delegate: _SearchTabsDelegate(
          searchController: _searchController,
          tabController: _tabController,
          onSearchChanged: _onSearchChanged,
          bookings: state.bookings,
        ),
      ),

      // Upcoming booking banner
      if (state.bookings.any((b) => b.isUpcoming))
        SliverToBoxAdapter(
          child: _buildUpcomingBanner(state.bookings),
        ),

      // Bookings list
      if (state.filteredBookings.isEmpty)
        SliverFillRemaining(
          child: _buildEmptyState(),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final booking = state.filteredBookings[index];
              return _buildBookingCard(booking);
            },
            childCount: state.filteredBookings.length,
          ),
        ),
    ];
  }

  Widget _buildUpcomingBanner(List<BookingModel> bookings) {
    final nextBooking = bookings
        .where((b) => b.isUpcoming)
        .reduce((a, b) => a.startDate.isBefore(b.startDate) ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next pickup: ${nextBooking.timeUntilStart}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${nextBooking.renterName} • ${DateFormat('MMM dd, yyyy').format(nextBooking.startDate)}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!nextBooking.isItemReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Prep needed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBookingDetails(booking),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(int.parse(
                    booking.status.colorCode.replaceAll('#', '0xFF'))),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: booking.renterAvatarUrl != null
                          ? NetworkImage(booking.renterAvatarUrl!)
                          : null,
                      child: booking.renterAvatarUrl == null
                          ? Text(
                              booking.renterName.isNotEmpty
                                  ? booking.renterName[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.renterName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 14, color: Colors.amber[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${booking.renterRating.toStringAsFixed(1)} (${booking.renterReviewCount})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM dd').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.durationDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '\$${booking.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (booking.isDeliveryRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping,
                                size: 12, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Delivery',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildQuickActions(booking),
                  ],
                ),
                if (booking.specialRequests != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.specialRequests!,
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final color = Color(int.parse(status.colorCode.replaceAll('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BookingModel booking) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.conversationId != null)
          IconButton(
            icon: const Icon(Icons.message, size: 20),
            onPressed: () => _openConversation(booking),
            tooltip: 'Message',
          ),
        if (booking.renterPhone != null)
          IconButton(
            icon: const Icon(Icons.phone, size: 20),
            onPressed: () => _callRenter(booking),
            tooltip: 'Call',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) => _handleMenuAction(value, booking),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'details', child: Text('View Details')),
            if (booking.status == BookingStatus.pending) ...[
              const PopupMenuItem(value: 'accept', child: Text('Accept')),
              const PopupMenuItem(value: 'decline', child: Text('Decline')),
            ],
            const PopupMenuItem(value: 'ready', child: Text('Mark as Ready')),
            const PopupMenuItem(value: 'notes', child: Text('Add Notes')),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When people book your item, you\'ll see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.share),
              label: const Text('Share Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsSheet(booking),
    );
  }

  Widget _buildBookingDetailsSheet(BookingModel booking) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Renter info
                  _buildDetailSection('Renter Information', [
                    _buildDetailRow('Name', booking.renterName),
                    _buildDetailRow('Email', booking.renterEmail),
                    if (booking.renterPhone != null)
                      _buildDetailRow('Phone', booking.renterPhone!),
                    _buildDetailRow('Rating',
                        '${booking.renterRating} ⭐ (${booking.renterReviewCount} reviews)'),
                  ]),

                  // Booking details
                  _buildDetailSection('Booking Details', [
                    _buildDetailRow('Dates',
                        '${DateFormat('MMM dd, yyyy').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}'),
                    _buildDetailRow('Duration', booking.durationDisplay),
                    _buildDetailRow('Status', booking.status.displayName),
                    _buildDetailRow('Total Amount',
                        '\$${booking.totalAmount.toStringAsFixed(2)}'),
                    _buildDetailRow('Security Deposit',
                        '\$${booking.securityDeposit.toStringAsFixed(2)}'),
                    if (booking.isDeliveryRequired) ...[
                      _buildDetailRow('Delivery Required', 'Yes'),
                      _buildDetailRow('Delivery Address',
                          booking.deliveryAddress ?? 'Not provided'),
                      if (booking.deliveryFee != null)
                        _buildDetailRow('Delivery Fee',
                            '\$${booking.deliveryFee!.toStringAsFixed(2)}'),
                    ],
                  ]),

                  // Special requests
                  if (booking.specialRequests != null)
                    _buildDetailSection('Special Requests', [
                      Text(booking.specialRequests!),
                    ]),

                  // Notes
                  if (booking.notes != null)
                    _buildDetailSection('Notes', [
                      Text(booking.notes!),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openConversation(BookingModel booking) {
    if (booking.conversationId != null) {
      // TODO: Navigate to conversation screen
      context.push('/messages/${booking.conversationId}');
    }
  }

  void _callRenter(BookingModel booking) async {
    if (booking.renterPhone != null) {
      final url = Uri.parse('tel:${booking.renterPhone}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  void _handleMenuAction(String action, BookingModel booking) {
    switch (action) {
      case 'details':
        _showBookingDetails(booking);
        break;
      case 'accept':
        context.read<BookingManagementBloc>().add(
              UpdateBookingStatus(booking.id, BookingStatus.confirmed),
            );
        break;
      case 'decline':
        context.read<BookingManagementBloc>().add(
              UpdateBookingStatus(booking.id, BookingStatus.cancelled),
            );
        break;
      case 'ready':
        context.read<BookingManagementBloc>().add(
              MarkItemReady(booking.id, !booking.isItemReady),
            );
        break;
      case 'notes':
        _showAddNotesDialog(booking);
        break;
    }
  }

  void _showAddNotesDialog(BookingModel booking) {
    final controller = TextEditingController(text: booking.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add notes about this booking...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingManagementBloc>().add(
                    AddBookingNotes(booking.id, controller.text),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Listing'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit listing
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Listing'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share listing
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Toggle Availability'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Toggle availability
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom delegate for search and tabs
class _SearchTabsDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final TabController tabController;
  final Function(String) onSearchChanged;
  final List<BookingModel> bookings;

  _SearchTabsDelegate({
    required this.searchController,
    required this.tabController,
    required this.onSearchChanged,
    required this.bookings,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          Flexible(
            child: TabBar(
              controller: tabController,
              labelColor: ColorConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: ColorConstants.primaryColor,
              labelStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: [
                Tab(text: 'All (${bookings.length})'),
                Tab(
                    text:
                        'Active (${bookings.where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed || b.status == BookingStatus.inProgress).length})'),
                Tab(
                    text:
                        'Past (${bookings.where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled).length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 90;

  @override
  double get minExtent => 90;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
