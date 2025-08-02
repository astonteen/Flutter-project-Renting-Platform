import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/messages/presentation/bloc/messages_bloc.dart';
import 'package:rent_ease/features/messages/presentation/screens/user_selection_screen.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/messages/data/models/message_model.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ConversationModel> _allConversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<MessagesBloc>().add(LoadConversations());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _allConversations;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredConversations = _allConversations
            .where((conversation) =>
                conversation.displayName.toLowerCase().contains(query) ||
                conversation.lastMessage.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.backgroundColor,
        foregroundColor: ColorConstants.textColor,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Direct Messages',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: BlocConsumer<MessagesBloc, MessagesState>(
              listener: (context, state) {
                if (state is ConversationsLoaded) {
                  setState(() {
                    _allConversations = state.conversations;
                    _filteredConversations = _isSearching
                        ? _filteredConversations
                        : state.conversations;
                  });
                }
              },
              builder: (context, state) {
                if (state is MessagesLoading) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                        const MessageBubbleSkeleton(),
                  );
                }

                if (state is MessagesError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<MessagesBloc>().add(LoadConversations());
                    },
                  );
                }

                if (state is ConversationsLoaded ||
                    _filteredConversations.isNotEmpty) {
                  final conversations = _filteredConversations;

                  if (conversations.isEmpty && _isSearching) {
                    return _buildEmptySearchState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MessagesBloc>().add(LoadConversations());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return ConversationCard(
                          conversation: conversations[index],
                          onTap: () => _openChat(context, conversations[index]),
                        );
                      },
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUserSelectionScreen();
        },
        backgroundColor: ColorConstants.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
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
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with item owners or renters.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _showUserSelectionScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, ConversationModel conversation) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
        fullscreenDialog: true,
      ),
    );
  }

  void _showUserSelectionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserSelectionScreen(),
      ),
    );
  }
}

class ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    ColorConstants.primaryColor.withValues(alpha: 0.1),
                backgroundImage: conversation.displayAvatar != null
                    ? NetworkImage(conversation.displayAvatar!)
                    : null,
                child: conversation.displayAvatar == null
                    ? const Icon(
                        Icons.person,
                        color: ColorConstants.primaryColor,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<MessageModel> _messages = [];
  late MessagesBloc _messagesBloc;

  @override
  void initState() {
    super.initState();
    _messagesBloc = context.read<MessagesBloc>();
    _loadMessages();

    // Set fullscreen mode - hide status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
      overlays: [],
    );

    // Also set the status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _loadMessages() {
    // Load messages using BLoC
    _messagesBloc.add(LoadMessages(widget.conversation.id));

    // Subscribe to real-time updates
    _messagesBloc.add(SubscribeToConversation(widget.conversation.id));
  }

  @override
  void dispose() {
    // Unsubscribe from conversation updates first (non-blocking)
    if (mounted) {
      _messagesBloc.add(UnsubscribeFromConversation());
    }

    // Dispose controllers immediately
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    // Restore system UI asynchronously to avoid blocking
    Future.microtask(() {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is MessagesLoaded &&
            state.conversationId == widget.conversation.id) {
          setState(() {
            _messages = state.messages;
          });
        } else if (state is MessageAdded &&
            state.conversationId == widget.conversation.id) {
          setState(() {
            _messages = state.messages;
          });
          // Scroll to bottom when new message is added
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: ColorConstants.backgroundColor,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor:
                ColorConstants.backgroundColor.withValues(alpha: 0.95),
            foregroundColor: ColorConstants.textColor,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorConstants.backgroundColor.withValues(alpha: 0.95),
                    ColorConstants.backgroundColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      ColorConstants.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: widget.conversation.displayAvatar != null
                      ? NetworkImage(widget.conversation.displayAvatar!)
                      : null,
                  child: widget.conversation.displayAvatar == null
                      ? const Icon(
                          Icons.person,
                          color: ColorConstants.primaryColor,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.conversation.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                            message: _messages[index],
                            isOwnMessage: _messages[index].senderId ==
                                SupabaseService.client.auth.currentUser?.id,
                          );
                        },
                      ),
              ),

              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.backgroundColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add,
                          color: ColorConstants.primaryColor),
                      onPressed: () {
                        _showAttachmentOptions();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                                color: ColorConstants.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: ColorConstants.primaryColor,
                      ),
                      onPressed: _sendMessage,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.conversation.displayAvatar != null
                ? NetworkImage(widget.conversation.displayAvatar!)
                : null,
            child: widget.conversation.displayAvatar == null
                ? const Icon(
                    Icons.person,
                    color: ColorConstants.primaryColor,
                    size: 40,
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'This conversation with ${widget.conversation.displayName} looks\npretty empty.',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try sending a message!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Send message via BLoC
    _messagesBloc.add(SendTextMessage(
      conversationId: widget.conversation.id,
      content: content,
    ));
    _messageController.clear();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera,
                  color: ColorConstants.primaryColor),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Take photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: ColorConstants.primaryColor),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick from gallery
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwnMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOwnMessage ? ColorConstants.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isImageMessage && message.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              if (message.hasContent) const SizedBox(height: 8),
            ],
            if (message.hasContent)
              Text(
                message.content,
                style: TextStyle(
                  color: isOwnMessage ? Colors.white : ColorConstants.textColor,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isOwnMessage
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubbleSkeleton extends StatelessWidget {
  const MessageBubbleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
