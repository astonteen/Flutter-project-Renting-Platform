import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/messages/presentation/screens/messages_screen.dart';
import 'package:go_router/go_router.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FrequentUserModel> _frequentRenters = [];
  List<FrequentUserModel> _frequentLenders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFrequentUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFrequentUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Load frequent renters (users who frequently rent from current user)
      final frequentRenters = await _getFrequentRenters(currentUserId);

      // Load frequent lenders (users current user frequently rents from)
      final frequentLenders = await _getFrequentLenders(currentUserId);

      setState(() {
        _frequentRenters = frequentRenters;
        _frequentLenders = frequentLenders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<FrequentUserModel>> _getFrequentRenters(
      String currentUserId) async {
    try {
      // First check all rentals for debugging
      final allRentals = await SupabaseService.client
          .from('rentals')
          .select('id, status, owner_id, renter_id')
          .eq('owner_id', currentUserId);

      debugPrint('All rentals for user $currentUserId: ${allRentals.length}');
      debugPrint(
          'Rental statuses: ${allRentals.map((r) => r['status']).toSet()}');

      // If no data found, return sample data for testing
      if (allRentals.isEmpty) {
        debugPrint('No rental data found, returning sample data for testing');
        return [
          FrequentUserModel(
            id: 'sample-user-1',
            fullName: 'John Doe',
            avatarUrl: null,
            bio: 'Frequent renter who loves outdoor gear',
            rentalCount: 3,
            userType: 'Frequent Renter',
            lastInteraction: DateTime.now().subtract(const Duration(days: 5)),
          ),
          FrequentUserModel(
            id: 'sample-user-2',
            fullName: 'Jane Smith',
            avatarUrl: null,
            bio: 'Regular customer for camping equipment',
            rentalCount: 2,
            userType: 'Frequent Renter',
            lastInteraction: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];
      }

      // Query for users who have rented from the current user multiple times
      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            renter_id,
            profiles!rentals_renter_id_fkey(id, full_name, avatar_url, bio),
            created_at
          ''')
          .eq('owner_id', currentUserId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      debugPrint('Completed rentals: ${response.length}');

      // Group by renter and count rentals
      final Map<String, FrequentUserModel> renterMap = {};

      for (final rental in response) {
        final renterId = rental['renter_id'] as String;
        final profileData = rental['profiles'] as Map<String, dynamic>;

        if (renterMap.containsKey(renterId)) {
          renterMap[renterId] = renterMap[renterId]!.copyWith(
            rentalCount: renterMap[renterId]!.rentalCount + 1,
          );
        } else {
          renterMap[renterId] = FrequentUserModel(
            id: profileData['id'],
            fullName: profileData['full_name'] ?? 'Unknown User',
            avatarUrl: profileData['avatar_url'],
            bio: profileData['bio'],
            rentalCount: 1,
            userType: 'Frequent Renter',
            lastInteraction: DateTime.parse(rental['created_at']),
          );
        }
      }

      // Filter users with 1+ rentals and sort by rental count (temporarily lowered for debugging)
      final frequentRenters = renterMap.values
          .where((user) => user.rentalCount >= 1)
          .toList()
        ..sort((a, b) => b.rentalCount.compareTo(a.rentalCount));

      debugPrint('Found ${frequentRenters.length} frequent renters');

      return frequentRenters.take(20).toList(); // Limit to top 20
    } catch (e) {
      debugPrint('Error loading frequent renters: $e');
      return [];
    }
  }

  Future<List<FrequentUserModel>> _getFrequentLenders(
      String currentUserId) async {
    try {
      // First check all rentals for debugging
      final allRentals = await SupabaseService.client
          .from('rentals')
          .select('id, status, owner_id, renter_id')
          .eq('renter_id', currentUserId);

      debugPrint(
          'All rentals as renter for user $currentUserId: ${allRentals.length}');
      debugPrint(
          'Rental statuses as renter: ${allRentals.map((r) => r['status']).toSet()}');

      // If no data found, return sample data for testing
      if (allRentals.isEmpty) {
        debugPrint(
            'No rental data as renter found, returning sample data for testing');
        return [
          FrequentUserModel(
            id: 'sample-lender-1',
            fullName: 'Mike Wilson',
            avatarUrl: null,
            bio: 'Trusted lender with quality equipment',
            rentalCount: 4,
            userType: 'Trusted Lender',
            lastInteraction: DateTime.now().subtract(const Duration(days: 3)),
          ),
          FrequentUserModel(
            id: 'sample-lender-2',
            fullName: 'Sarah Johnson',
            avatarUrl: null,
            bio: 'Reliable equipment provider',
            rentalCount: 2,
            userType: 'Trusted Lender',
            lastInteraction: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ];
      }

      // Query for users the current user has rented from multiple times
      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            owner_id,
            profiles!rentals_owner_id_fkey(id, full_name, avatar_url, bio),
            created_at
          ''')
          .eq('renter_id', currentUserId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      debugPrint('Completed rentals as renter: ${response.length}');

      // Group by owner and count rentals
      final Map<String, FrequentUserModel> lenderMap = {};

      for (final rental in response) {
        final ownerId = rental['owner_id'] as String;
        final profileData = rental['profiles'] as Map<String, dynamic>;

        if (lenderMap.containsKey(ownerId)) {
          lenderMap[ownerId] = lenderMap[ownerId]!.copyWith(
            rentalCount: lenderMap[ownerId]!.rentalCount + 1,
          );
        } else {
          lenderMap[ownerId] = FrequentUserModel(
            id: profileData['id'],
            fullName: profileData['full_name'] ?? 'Unknown User',
            avatarUrl: profileData['avatar_url'],
            bio: profileData['bio'],
            rentalCount: 1,
            userType: 'Trusted Lender',
            lastInteraction: DateTime.parse(rental['created_at']),
          );
        }
      }

      // Filter users with 1+ rentals and sort by rental count (temporarily lowered for debugging)
      final frequentLenders = lenderMap.values
          .where((user) => user.rentalCount >= 1)
          .toList()
        ..sort((a, b) => b.rentalCount.compareTo(a.rentalCount));

      debugPrint('Found ${frequentLenders.length} frequent lenders');

      return frequentLenders.take(20).toList(); // Limit to top 20
    } catch (e) {
      debugPrint('Error loading frequent lenders: $e');
      return [];
    }
  }

  Future<void> _startConversation(FrequentUserModel user) async {
    try {
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Quick lightweight loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Opening conversation...'),
              ],
            ),
            duration: Duration(milliseconds: 1500),
            backgroundColor: ColorConstants.primaryColor,
          ),
        );
      }

      // Get or create conversation (optimized)
      final messagesRepository = MessagesRepository();
      final conversationId = await messagesRepository.getOrCreateConversation(
          currentUserId, user.id);

      // Create minimal conversation model for navigation
      final conversation = ConversationModel(
        id: conversationId,
        conversationType: ConversationType.individual,
        otherUserId: user.id,
        otherUserName: user.fullName,
        otherUserAvatar: user.avatarUrl,
        lastMessage: '', // Let ChatScreen load actual messages
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        messageType: 'text',
      );

      // Navigate immediately without blocking dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Connections',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: ColorConstants.primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Frequent Renters',
            ),
            Tab(
              icon: Icon(Icons.store_outlined),
              text: 'Trusted Lenders',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersList(_frequentRenters),
                    _buildUsersList(_frequentLenders),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFrequentUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<FrequentUserModel> users) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFrequentUsers,
      color: ColorConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
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
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No connections yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more rentals to build your network',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(FrequentUserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: ColorConstants.primaryColor.withAlpha(25),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.userType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${user.rentalCount} rental${user.rentalCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.bio!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),

            // Message button
            IconButton(
              onPressed: () => _startConversation(user),
              icon: const Icon(
                Icons.message_outlined,
                color: ColorConstants.primaryColor,
              ),
              style: IconButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor.withAlpha(25),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FrequentUserModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final int rentalCount;
  final String userType;
  final DateTime lastInteraction;

  const FrequentUserModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    required this.rentalCount,
    required this.userType,
    required this.lastInteraction,
  });

  FrequentUserModel copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    String? bio,
    int? rentalCount,
    String? userType,
    DateTime? lastInteraction,
  }) {
    return FrequentUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      rentalCount: rentalCount ?? this.rentalCount,
      userType: userType ?? this.userType,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }
}
