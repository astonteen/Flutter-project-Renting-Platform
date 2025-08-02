import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/router/app_routes.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/features/messages/presentation/cubit/messages_cubit.dart';
import 'package:rent_ease/features/home/data/repositories/lender_repository.dart';
import 'package:rent_ease/features/messages/presentation/bloc/messages_bloc.dart'
    as msg_bloc;
import 'package:rent_ease/features/booking/presentation/bloc/booking_management_bloc.dart';
import 'package:rent_ease/features/messages/presentation/screens/messages_screen.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/core/constants/app_constants.dart';

class LenderHomeScreen extends StatefulWidget {
  const LenderHomeScreen({super.key});

  @override
  State<LenderHomeScreen> createState() => _LenderHomeScreenState();
}

class _LenderHomeScreenState extends State<LenderHomeScreen> {
  DateTime? _lastSyncTime;
  int _selectedTabIndex = 0; // 0 for Today, 1 for Upcoming
  List<BookingModel> _todayBookings = [];
  List<BookingModel> _upcomingBookings = [];
  bool _isLoadingBookings = false;
  late LenderRepository _lenderRepository;

  @override
  void initState() {
    super.initState();
    _lenderRepository = LenderRepository();
    _loadData();
    _setupRealtimeSubscription();
  }

  void _loadData() {
    context.read<LenderBloc>().add(const LoadAllBookings());
    context.read<MessagesCubit>().loadUnreadCount();
    _loadLenderBookings();
  }

  void _setupRealtimeSubscription() {
    // Setup real-time subscriptions for lender updates
    _loadData();
  }

  Future<void> _loadLenderBookings() async {
    if (_isLoadingBookings) return;

    setState(() {
      _isLoadingBookings = true;
    });

    try {
      // Load today's active bookings (bookings that are currently ongoing)
      final allTodayBookings =
          await _lenderRepository.getActiveBookingsForToday();

      // Filter out returned items from previous days (only show returned items for current day)
      final now = DateTime.now();

      final filteredTodayBookings = allTodayBookings.where((booking) {
        // If item is returned, only show it if it was returned today
        if (booking.isReturnCompleted == true) {
          // Check if the return was completed today
          // For now, we'll keep all returned items for the current day
          // In a real implementation, we'd check the delivery completion timestamp
          final endDate = booking.endDate;
          final daysSinceEnd = now.difference(endDate).inDays;

          // Only show returned items for the rest of today (until next 00:00)
          return daysSinceEnd <= 1; // Show if rental ended today or yesterday
        }
        // Show all non-returned items normally
        return true;
      }).toList();

      // Load upcoming bookings (bookings that start in the future)
      final upcomingBookings =
          await _lenderRepository.getUpcomingBookings(daysAhead: 30);

      setState(() {
        _todayBookings = filteredTodayBookings;
        _upcomingBookings = upcomingBookings;
        _isLoadingBookings = false;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoadingBookings = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadLenderBookings();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LenderBloc, LenderState>(
          listener: (context, state) {
            if (state is BookingStatusUpdated) {
              // Reload bookings to reflect status change
              _loadLenderBookings();
            } else if (state is AllBookingsLoaded) {
              setState(() {
                // Handle if needed in future
              });
            }
          },
        ),
        BlocListener<BookingManagementBloc, BookingManagementState>(
          listener: (context, state) {
            if (state is BookingActionSuccess) {
              // Refresh bookings when mark ready action succeeds
              _loadLenderBookings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
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
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: ColorConstants.backgroundColor,
          foregroundColor: ColorConstants.textColor,
          elevation: 0,
          leading: const SizedBox.shrink(),
          title: const Text(
            'My Rentals',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        body: _buildLenderHomeContent(context),
      ),
    );
  }

  // Lender-specific home content with Today/Upcoming tabs
  Widget _buildLenderHomeContent(BuildContext context) {
    return Column(
      children: [
        _buildLenderHeader(context),
        _buildTabSelector(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _selectedTabIndex == 0
                ? _buildTodayContent(context)
                : _buildUpcomingContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLenderHeader(BuildContext context) {
    // Calculate key metrics from current bookings
    final totalBookings = _todayBookings.length + _upcomingBookings.length;
    final pendingApprovals = [..._todayBookings, ..._upcomingBookings]
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final activeRentals = [..._todayBookings, ..._upcomingBookings]
        .where((b) => b.status == BookingStatus.inProgress)
        .length;
    final todayRevenue = _todayBookings
        .where((b) =>
            b.status == BookingStatus.inProgress ||
            b.status == BookingStatus.completed)
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main title and notification icon
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Rentals',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.textColor,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your rental activities',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (pendingApprovals > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_actions,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingApprovals pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _buildStatCard(
                icon: Icons.receipt_long,
                value: totalBookings.toString(),
                label: 'Total Bookings',
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.play_circle,
                value: activeRentals.toString(),
                label: 'Active Now',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.attach_money,
                value: '\$${todayRevenue.toStringAsFixed(0)}',
                label: 'Today\'s Revenue',
                color: Colors.blue,
              ),
            ],
          ),

          // Last update info
          if (_lastSyncTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.sync, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${_formatLastSync()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final todayCount = _todayBookings.length;
    final upcomingCount = _upcomingBookings.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? ColorConstants.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.today,
                      size: 18,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    if (todayCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          todayCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? ColorConstants.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upcoming,
                      size: 18,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    if (upcomingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          upcomingCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayContent(BuildContext context) {
    if (_isLoadingBookings) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_todayBookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildEmptyState(
            context,
            'No activities today',
            'You don\'t have any rentals or returns scheduled for today.',
            Icons.today,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _todayBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingItem(_todayBookings[index]);
      },
    );
  }

  Widget _buildUpcomingContent(BuildContext context) {
    if (_isLoadingBookings) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_upcomingBookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildEmptyState(
            context,
            'No upcoming activities',
            'You don\'t have any upcoming rentals or returns scheduled.',
            Icons.upcoming,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingItem(_upcomingBookings[index]);
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => AppRoutes.goToCreateListing(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add New Listing'),
        ),
      ],
    );
  }

  Widget _buildBookingItem(BookingModel booking) {
    final statusColor = _getBookingStatusColor(booking.status);
    final now = DateTime.now();
    final daysUntilStart = booking.startDate.difference(now).inDays;
    final daysUntilEnd = booking.endDate.difference(now).inDays;
    final isActive = booking.status == BookingStatus.inProgress;
    final isPending = booking.status == BookingStatus.pending;

    // Calculate rental duration
    final rentalDays = booking.endDate.difference(booking.startDate).inDays;

    // Determine timeline status and urgency
    String timelineText = '';
    IconData timelineIcon = Icons.schedule;
    Color timelineColor = Colors.grey;

    if (isPending) {
      timelineText = 'Awaiting your approval';
      timelineIcon = Icons.pending_actions;
      timelineColor = Colors.orange;
    } else if (daysUntilStart > 0) {
      timelineText =
          'Starts in $daysUntilStart day${daysUntilStart == 1 ? '' : 's'}';
      timelineIcon = Icons.upcoming;
      timelineColor = Colors.blue;
    } else if (isActive && daysUntilEnd > 0) {
      timelineText =
          'Active • $daysUntilEnd day${daysUntilEnd == 1 ? '' : 's'} remaining';
      timelineIcon = Icons.play_circle;
      timelineColor = Colors.green;
    } else if (booking.status == BookingStatus.completed) {
      timelineText = 'Completed';
      timelineIcon = Icons.check_circle;
      timelineColor = Colors.green;
    } else {
      timelineText = 'In progress';
      timelineIcon = Icons.timelapse;
      timelineColor = ColorConstants.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and booking info
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge and price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${booking.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                        Text(
                          '$rentalDays day${rentalDays == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Item name - prominent display
                Text(
                  booking.listingName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Renter info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.renterName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (booking.isDeliveryRequired) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DELIVERY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Timeline info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: timelineColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        timelineIcon,
                        size: 18,
                        color: timelineColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timelineText,
                        style: TextStyle(
                          fontSize: 14,
                          color: timelineColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ready status and timing info for confirmed bookings
                if (booking.status == BookingStatus.confirmed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: booking.isItemReady
                          ? Colors.green.withValues(alpha: 0.08)
                          : _canMarkReady(booking)
                              ? Colors.blue.withValues(alpha: 0.08)
                              : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: booking.isItemReady
                            ? Colors.green.withValues(alpha: 0.3)
                            : _canMarkReady(booking)
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          booking.isItemReady
                              ? Icons.check_circle
                              : _canMarkReady(booking)
                                  ? Icons.schedule
                                  : Icons.access_time,
                          size: 18,
                          color: booking.isItemReady
                              ? Colors.green
                              : _canMarkReady(booking)
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getReadyTimingMessage(booking),
                            style: TextStyle(
                              fontSize: 14,
                              color: booking.isItemReady
                                  ? Colors.green
                                  : _canMarkReady(booking)
                                      ? Colors.blue
                                      : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Action buttons for pending bookings
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle decline
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle approve
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick actions for active bookings
          if (isActive || booking.status == BookingStatus.confirmed) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[100]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.message_outlined,
                      label: 'Message',
                      onTap: () => _openMessageConversation(booking),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[100],
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'Details',
                      onTap: () => _openBookingDetails(booking),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[100],
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: booking.isDeliveryRequired
                          ? Icons.local_shipping_outlined
                          : booking.isItemReady
                              ? Icons.check_circle
                              : _canMarkReady(booking)
                                  ? Icons.check_circle_outline
                                  : Icons.schedule,
                      label: booking.isDeliveryRequired
                          ? 'Track Delivery'
                          : booking.isItemReady
                              ? 'Prepared ✓'
                              : _canMarkReady(booking)
                                  ? 'Mark Prepared'
                                  : 'Too Early',
                      onTap: () => _handleReadyOrTrackAction(booking),
                      isPrimary: !booking.isItemReady && _canMarkReady(booking),
                      color: booking.isItemReady
                          ? Colors.green
                          : _canMarkReady(booking)
                              ? null
                              : Colors.grey[300],
                      isDisabled: !booking.isDeliveryRequired &&
                          !booking.isItemReady &&
                          !_canMarkReady(booking),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? color,
    bool isDisabled = false,
    BorderRadius? borderRadius,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? ColorConstants.primaryColor : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isPrimary ? ColorConstants.primaryColor : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.inProgress:
        return ColorConstants.primaryColor;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.overdue:
        return Colors.redAccent;
    }
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return '';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // Action function implementations
  void _openMessageConversation(BookingModel booking) async {
    try {
      if (booking.conversationId != null) {
        // Load conversation data directly without showing dialog
        final messagesRepository = MessagesRepository();
        final conversation =
            await messagesRepository.getConversation(booking.conversationId!);

        // Navigate to chat screen
        if (mounted && conversation != null) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => msg_bloc.MessagesBloc(
                  messagesRepository: MessagesRepository(),
                ),
                child: ChatScreen(conversation: conversation),
              ),
              fullscreenDialog: true,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation not found')),
          );
        }
      } else {
        // Create new conversation with the renter
        final messagesBloc = context.read<msg_bloc.MessagesBloc>();
        messagesBloc.add(msg_bloc.CreateConversation(booking.renterId));

        // Listen for conversation creation and navigate
        messagesBloc.stream.listen((state) {
          if (state is msg_bloc.ConversationCreated) {
            // Use same fullscreen navigation for new conversations
            _navigateToConversation(state.conversationId);
          } else if (state is msg_bloc.MessagesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to open conversation: ${state.message}')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open conversation: $e')),
        );
      }
    }
  }

  Future<void> _navigateToConversation(String conversationId) async {
    try {
      // Load conversation data directly without dialog
      final messagesRepository = MessagesRepository();
      final conversation =
          await messagesRepository.getConversation(conversationId);

      // Navigate to chat screen
      if (mounted && conversation != null) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => msg_bloc.MessagesBloc(
                messagesRepository: MessagesRepository(),
              ),
              child: ChatScreen(conversation: conversation),
            ),
            fullscreenDialog: true,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation not found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversation: $e')),
        );
      }
    }
  }

  void _openBookingDetails(BookingModel booking) {
    // Navigate to booking details screen
    context.push('/booking/${booking.id}');
  }

  void _handleReadyOrTrackAction(BookingModel booking) {
    if (booking.isDeliveryRequired) {
      // Track delivery - navigate to delivery tracking
      _openDeliveryTracking(booking);
    } else if (!_canMarkReady(booking)) {
      // Show timing information if too early
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getReadyTimingMessage(booking)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // Mark item as ready for pickup
      _showMarkReadyDialog(booking);
    }
  }

  void _openDeliveryTracking(BookingModel booking) async {
    try {
      // Find delivery associated with this booking
      // Navigate to unified delivery tracking screen
      context.push('/track-orders');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open delivery tracking: $e')),
      );
    }
  }

  // Check if item can be marked ready based on timing rules
  bool _canMarkReady(BookingModel booking) {
    final now = DateTime.now();
    final maxDaysEarly = booking.isDeliveryRequired
        ? AppConstants.maxDaysEarlyDelivery
        : AppConstants.maxDaysEarlyPickup;
    final earliestReadyDate =
        booking.startDate.subtract(Duration(days: maxDaysEarly));
    return now.isAfter(earliestReadyDate) ||
        now.isAtSameMomentAs(earliestReadyDate);
  }

  // Get the date when item can be marked ready
  DateTime _getEarliestReadyDate(BookingModel booking) {
    final maxDaysEarly = booking.isDeliveryRequired
        ? AppConstants.maxDaysEarlyDelivery
        : AppConstants.maxDaysEarlyPickup;
    return booking.startDate.subtract(Duration(days: maxDaysEarly));
  }

  // Get formatted message about when item can be marked ready
  String _getReadyTimingMessage(BookingModel booking) {
    if (_canMarkReady(booking)) {
      if (booking.isItemReady) {
        // Check if pickup is available now
        final now = DateTime.now();
        final canPickupNow = now.isAfter(booking.startDate) ||
            now.isAtSameMomentAs(booking.startDate);

        if (canPickupNow) {
          return 'Ready & Available for pickup';
        } else {
          final daysUntilPickup = booking.startDate.difference(now).inDays + 1;
          return 'Ready - Pickup available in $daysUntilPickup day${daysUntilPickup > 1 ? 's' : ''}';
        }
      } else {
        return 'Ready to mark as prepared';
      }
    }

    final earliestDate = _getEarliestReadyDate(booking);
    final daysUntil = earliestDate.difference(DateTime.now()).inDays + 1;
    final pickupOrDelivery = booking.isDeliveryRequired ? 'delivery' : 'pickup';
    final maxDays = booking.isDeliveryRequired
        ? AppConstants.maxDaysEarlyDelivery
        : AppConstants.maxDaysEarlyPickup;

    return 'Can prepare in $daysUntil day${daysUntil > 1 ? 's' : ''} '
        '($maxDays days before $pickupOrDelivery)';
  }

  void _showMarkReadyDialog(BookingModel booking) {
    final isCurrentlyReady = booking.isItemReady;
    final action =
        isCurrentlyReady ? 'mark as not prepared' : 'mark as prepared';
    final actionCapitalized =
        isCurrentlyReady ? 'Mark Not Prepared' : 'Mark Prepared';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionCapitalized),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${action.substring(0, 1).toUpperCase()}${action.substring(1)} "${booking.listingName}"?',
            ),
            const SizedBox(height: 8),
            Text(
              'This means the item is ${isCurrentlyReady ? 'not ' : ''}cleaned, tested, and ready for handover.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (!isCurrentlyReady) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${booking.renterName} can only pickup starting ${_formatDate(booking.startDate)}, regardless of when you mark this prepared.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markItemReady(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyReady
                  ? Colors.orange
                  : ColorConstants.primaryColor,
            ),
            child: Text(actionCapitalized),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _markItemReady(BookingModel booking) {
    try {
      // Use BookingManagementBloc to mark item as ready
      final bookingBloc = context.read<BookingManagementBloc>();
      bookingBloc.add(MarkItemReady(booking.id, !booking.isItemReady));

      // Success/error handling and refresh are now handled by BlocListener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark item as ready: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
