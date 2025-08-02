import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/messages/presentation/screens/messages_screen.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown User',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) => user.fullName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .neq('id', currentUserId) // Exclude current user
          .order('full_name');

      final users =
          (response as List).map((data) => UserProfile.fromJson(data)).toList();

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectUser(UserProfile user) async {
    try {
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: ColorConstants.primaryColor,
          ),
        ),
      );

      // Get or create conversation using repository directly
      final messagesRepository = MessagesRepository();
      final conversationId = await messagesRepository.getOrCreateConversation(
          currentUserId, user.id);

      // Create conversation model for navigation
      final conversation = ConversationModel(
        id: conversationId,
        conversationType: ConversationType.individual,
        otherUserId: user.id,
        otherUserName: user.fullName,
        otherUserAvatar: user.avatarUrl,
        lastMessage: 'Start the conversation',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        messageType: 'text',
      );

      // Hide loading and navigate to chat screen
      if (mounted) {
        // Close loading dialog first
        Navigator.of(context).pop();

        // Use WidgetsBinding to ensure navigation happens after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Pop user selection screen and push chat screen in one operation
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ChatScreen(conversation: conversation),
                fullscreenDialog: true,
              ),
            );
          }
        });
      }
    } catch (e) {
      // Hide loading dialog safely
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // Ignore if already popped
        }
      }

      // Show error after ensuring dialog is closed
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start conversation: $e'),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'New message',
          style: TextStyle(
            color: ColorConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'To:',
                  style: TextStyle(
                    color: ColorConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: ColorConstants.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: ColorConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: ColorConstants.lightGrey,
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading users...')
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Users list
        if (_filteredUsers.isEmpty && _searchQuery.isNotEmpty)
          _buildEmptyState()
        else
          ..._filteredUsers.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? const Icon(
                Icons.person,
                color: ColorConstants.primaryColor,
                size: 24,
              )
            : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
          color: ColorConstants.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _selectUser(user),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: ColorConstants.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              color: ColorConstants.grey.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different name',
            style: TextStyle(
              color: ColorConstants.grey.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
