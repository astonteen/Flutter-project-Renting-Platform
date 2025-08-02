import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/home/data/models/category_model.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:rent_ease/features/home/presentation/bloc/home_bloc.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/home/presentation/screens/lender_home_screen.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:flutter/foundation.dart';

// DEPRECATE THIS FILE AFTER MIGRATION
// NEW SCREENS CREATED AT:
// - lib/features/home/presentation/screens/renter_home_screen.dart
// - lib/features/home/presentation/screens/lender_home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class DateOption {
  final String label;
  final DateTime? date;

  DateOption({
    required this.label,
    required this.date,
  });
}

class CategoryOption {
  final String name;
  final IconData icon;

  CategoryOption({
    required this.name,
    required this.icon,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  final GlobalKey _searchBarKey = GlobalKey();
  late RoleSwitchingService _roleSwitchingService;
  DateTime? _selectedDate;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _roleSwitchingService = getIt<RoleSwitchingService>();
    // Load home data when screen initializes
    context.read<HomeBloc>().add(LoadHomeData());
    // Initialize sample data if needed
    context.read<HomeBloc>().add(InitializeSampleData());
    // Load my listings for lender mode
    if (_roleSwitchingService.isLender) {
      context.read<ListingBloc>().add(LoadMyListings());
      _loadLenderBookings();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      // Add to search history
      if (!_searchHistory.contains(query.trim())) {
        _searchHistory.insert(0, query.trim());
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      }
      context.read<HomeBloc>().add(SearchItems(query.trim()));
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce the search to prevent rapid API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final trimmedQuery = query.trim();
      if (trimmedQuery.isNotEmpty) {
        context.read<HomeBloc>().add(SearchItems(trimmedQuery));
      } else {
        context.read<HomeBloc>().add(LoadHomeData());
      }
    });
  }

  void _onCategoryTapped(String categoryId) {
    context.read<HomeBloc>().add(LoadCategoryItems(categoryId));
  }

  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(RefreshHomeData());
    if (_roleSwitchingService.isLender) {
      await _loadLenderBookings();
    }
  }

  Future<void> _loadLenderBookings() async {
    if (_isLoadingBookings) return;

    setState(() {
      _isLoadingBookings = true;
    });

    try {
      // Load today's active bookings (bookings that are currently ongoing)
      // final todayBookings = await _lenderRepository.getActiveBookingsForToday();
      // Load upcoming bookings (bookings that start in the future)
      // final upcomingBookings = await _lenderRepository.getUpcomingBookings(daysAhead: 30);
      setState(() {
        _isLoadingBookings = false;
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

  @override
  Widget build(BuildContext context) {
    if (_roleSwitchingService.isLender) {
      return const Scaffold(body: LenderHomeScreen());
    }

    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return _buildPageContent(context, state);
        },
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, HomeState state) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildContentArea(context, state)),
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, HomeState state) {
    if (state is HomeLoading ||
        state is SearchLoading ||
        state is CategoryItemsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HomeError) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Something went wrong',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Removed ElevatedButton
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is SearchResults) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildSearchResultsList(context, state),
      );
    }

    if (state is CategoryItemsLoaded) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildCategoryItemsList(context, state),
      );
    }

    if (state is HomeLoaded) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildHomeContentBody(context, state),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(
              context,
              'Welcome to RentEase',
              'Pull down to refresh and load items',
              Icons.home_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContentBody(BuildContext context, HomeLoaded state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Categories
          _buildCategoriesSection(state.categories),
          const SizedBox(height: 24),

          // Featured listings from HomeBloc
          _buildListingsSection(
            title: 'Featured Listings',
            listings: state.featuredItems,
            sectionType: 'featured',
          ),
          const SizedBox(height: 24),

          // Near you listings from HomeBloc
          _buildListingsSection(
            title: 'Near You',
            listings: state.nearbyItems,
            sectionType: 'near_you',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context, SearchResults state) {
    if (state.results.isEmpty) {
      return ListView(
        children: [_buildEmptySection('No results found for "${state.query}"')],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        return _buildVerticalRentalItemCard(state.results[index],
            ValueKey('search_${state.results[index].id}'));
      },
    );
  }

  Widget _buildCategoryItemsList(
      BuildContext context, CategoryItemsLoaded state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.read<HomeBloc>().add(LoadHomeData()),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'Category Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.items.isEmpty
              ? ListView(
                  children: [_buildEmptySection('No items in this category')],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    return _buildVerticalRentalItemCard(state.items[index],
                        ValueKey('category_${state.items[index].id}'));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      key: _searchBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Airbnb-style centered search bar
          GestureDetector(
            onTap: () {
              _showFilterCards();
            },
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 56, // Set explicit height for better pill shape
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                      28), // Half of height for perfect pill
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Where to? • What do you need?',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical:
                          14, // Slightly reduced for better centering in the 56px height
                      horizontal: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterCards() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Where filter card
                      _buildFilterCard(
                        title: 'Where?',
                        onTap: () {
                          _showLocationSearch();
                        },
                        child: _buildSearchField(
                          hint: 'Search destinations',
                          icon: Icons.search,
                        ),
                      ),

                      // When filter card
                      _buildFilterCard(
                        title: 'When',
                        onTap: () {
                          _showDateSelection();
                        },
                        child: Row(
                          children: [
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day} ${_getMonthAbbreviation(_selectedDate!.month)}'
                                  : '20 Jul',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // What filter card
                      _buildFilterCard(
                        title: 'What',
                        onTap: () {
                          _showCategorySelection();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add service',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Clear all'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement search functionality
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
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

  Widget _buildFilterCard({
    required String title,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Where?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search destinations',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.near_me, color: Colors.blue),
                ),
                title: const Text('Nearby'),
                subtitle: const Text("Find what's around you"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateSelection() {
    final List<DateOption> dateOptions = [
      DateOption(label: 'Today', date: DateTime.now()),
      DateOption(
          label: 'Tomorrow', date: DateTime.now().add(const Duration(days: 1))),
      DateOption(
          label: 'This weekend',
          date: DateTime.now().add(Duration(
              days: DateTime.now().weekday == 6
                  ? 0
                  : DateTime.now().weekday == 7
                      ? 6
                      : 6 - DateTime.now().weekday))),
      DateOption(label: 'Choose dates', date: null),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'When?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: dateOptions.map((option) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (option.date != null) {
                            _selectedDate = option.date;
                          } else {
                            _showCustomDatePicker();
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (option.date != null)
                              Text(
                                '${option.date!.day} ${_getMonthAbbreviation(option.date!.month)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showCategorySelection() {
    final List<CategoryOption> categoryOptions = [
      CategoryOption(name: 'Electronics', icon: Icons.devices),
      CategoryOption(name: 'Furniture', icon: Icons.chair),
      CategoryOption(name: 'Clothing', icon: Icons.checkroom),
      CategoryOption(name: 'Books', icon: Icons.book),
      CategoryOption(name: 'Sports', icon: Icons.sports_soccer),
      CategoryOption(name: 'Tools', icon: Icons.handyman),
      CategoryOption(name: 'Vehicles', icon: Icons.directions_car),
      CategoryOption(name: 'Toys', icon: Icons.toys),
      CategoryOption(name: 'Music', icon: Icons.music_note),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'What are you looking for?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: categoryOptions.length,
                  itemBuilder: (context, index) {
                    final category = categoryOptions[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category.icon,
                              color: Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return DynamicCategoryCard(
                category: categories[index],
                onTap: () => _onCategoryTapped(categories[index].id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListingsSection({
    required String title,
    required List<RentalItemModel> listings,
    required String sectionType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (listings.isNotEmpty)
                TextButton(
                  onPressed: () {
                    context.push('/all-listings?section=$sectionType');
                  },
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        listings.isEmpty
            ? _buildEmptySection('No listings available')
            : SizedBox(
                height: 210, // Match other sections
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    return _buildRentalItemCard(listings[index]);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildRentalItemCard(RentalItemModel item) {
    return Container(
      width: 180,
      height: 200, // Fixed height to match other cards
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          if (item.id.isNotEmpty) {
            context.push('/item/${item.id}');
          } else {
            if (kDebugMode) {
              debugPrint('Warning: Attempted to navigate with empty item ID');
            }
          }
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 100, // Reduced to match other cards
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: item.primaryImageUrl.isNotEmpty
                      ? Image.network(
                          item.primaryImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : const Icon(Icons.image, size: 40),
                ),
              ),
              // Content with fixed height
              Container(
                height: 88, // Fixed height to prevent overflow
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.pricePerDay.toStringAsFixed(0)}/day',
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
                            item.location ?? 'Location not specified',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalRentalItemCard(RentalItemModel item, [Key? key]) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (item.id.isNotEmpty) {
            context.push('/item/${item.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: item.primaryImageUrl.isNotEmpty
                      ? Image.network(
                          item.primaryImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image, size: 40),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.pricePerDay.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                          color: ColorConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location ?? 'Location not specified',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
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
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ),
    );
  }

  // Lender-specific home content with Today/Upcoming tabs
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
      ],
    );
  }
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;

  CategoryItem({required this.id, required this.name, required this.icon});
}

class CategoryCard extends StatelessWidget {
  final CategoryItem category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: ColorConstants.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Dynamic Category Card for Supabase data
class DynamicCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const DynamicCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconFromString(category.icon),
                color: ColorConstants.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'devices':
        return Icons.devices;
      case 'handyman':
        return Icons.handyman;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'checkroom':
        return Icons.checkroom;
      case 'chair':
        return Icons.chair;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }
}
