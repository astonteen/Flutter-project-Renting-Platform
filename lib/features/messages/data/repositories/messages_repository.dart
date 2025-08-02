import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/messages/data/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesRepository {
  // Cache for conversation IDs to avoid redundant database calls
  static final Map<String, String> _conversationCache = {};

  // Clear conversation cache (useful for testing or memory management)
  static void clearConversationCache() {
    _conversationCache.clear();
    if (kDebugMode) {
      debugPrint('🧹 Conversation cache cleared');
    }
  }

  // Helper method to get receiver ID from conversation
  Future<String> _getReceiverId(String conversationId, String senderId) async {
    final conversationResponse = await SupabaseService.client
        .from('conversations')
        .select('participant_1_id, participant_2_id')
        .eq('id', conversationId)
        .single();

    final participant1 = conversationResponse['participant_1_id'] as String;
    final participant2 = conversationResponse['participant_2_id'] as String;

    return participant1 == senderId ? participant2 : participant1;
  }

  // Get conversations for current user using the new schema
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching conversations for user: $userId');
      }

      final response = await SupabaseService.client
          .rpc('get_user_conversations', params: {'p_user_id': userId});

      if (kDebugMode) {
        debugPrint('📦 Database returned ${response.length} conversations');
      }

      final conversations = (response as List)
          .map((data) => ConversationModel.fromJson(data))
          .toList();

      if (kDebugMode) {
        debugPrint(
            '✅ Successfully mapped ${conversations.length} conversations');
      }

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading conversations: $e');
      }
      throw Exception('Failed to load conversations: $e');
    }
  }

  // Get messages for a specific conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      debugPrint('🔍 Fetching messages for conversation: $conversationId');

      final response = await SupabaseService.client
          .from('messages')
          .select('''
            *,
            sender:profiles!sender_id(full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      debugPrint('📦 Database returned ${response.length} messages');

      final messages = (response as List)
          .map((data) => MessageModel.fromJson(data))
          .toList();

      debugPrint('✅ Successfully mapped ${messages.length} messages');

      return messages;
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a text message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      debugPrint('📤 Sending message to conversation: $conversationId');

      // Get the receiver ID
      final receiverId = await _getReceiverId(conversationId, senderId);

      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId, // Add the missing receiver_id
        'content': content,
        'message_type': 'text',
      };

      final response = await SupabaseService.client
          .from('messages')
          .insert(messageData)
          .select('''
            *,
            sender:profiles!sender_id(full_name, avatar_url)
          ''').single();

      final message = MessageModel.fromJson(response);
      debugPrint('✅ Message sent successfully: ${message.id}');

      return message;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Send an image message
  Future<MessageModel> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      debugPrint('📤 Sending image message to conversation: $conversationId');

      // Get the receiver ID
      final receiverId = await _getReceiverId(conversationId, senderId);

      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId, // Add the missing receiver_id
        'content': caption,
        'message_type': 'image',
        'image_url': imageUrl,
      };

      final response = await SupabaseService.client
          .from('messages')
          .insert(messageData)
          .select('''
            *,
            sender:profiles!sender_id(full_name, avatar_url)
          ''').single();

      final message = MessageModel.fromJson(response);
      debugPrint('✅ Image message sent successfully: ${message.id}');

      return message;
    } catch (e) {
      debugPrint('❌ Error sending image message: $e');
      throw Exception('Failed to send image message: $e');
    }
  }

  // Get or create conversation between two users
  Future<String> getOrCreateConversation(String user1Id, String user2Id) async {
    try {
      // Create a consistent cache key regardless of parameter order
      final cacheKey = user1Id.compareTo(user2Id) < 0
          ? '$user1Id-$user2Id'
          : '$user2Id-$user1Id';

      // Check cache first
      if (_conversationCache.containsKey(cacheKey)) {
        final cachedId = _conversationCache[cacheKey]!;
        debugPrint('✅ Using cached conversation ID: $cachedId');
        return cachedId;
      }

      debugPrint(
          '🔍 Getting/creating conversation between $user1Id and $user2Id');

      final conversationId = await SupabaseService.client
          .rpc('get_or_create_conversation', params: {
        'user1_id': user1Id,
        'user2_id': user2Id,
      });

      final result = conversationId as String;

      // Cache the result
      _conversationCache[cacheKey] = result;

      debugPrint('✅ Conversation ID: $result');

      return result;
    } catch (e) {
      debugPrint('❌ Error getting/creating conversation: $e');
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      debugPrint('✅ Marking messages as read in conversation: $conversationId');

      await SupabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      debugPrint('✅ Messages marked as read');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Upload image to Supabase Storage
  Future<String> uploadImage(String filePath, Uint8List bytes) async {
    try {
      debugPrint('📤 Uploading image: $filePath');

      final fileName =
          'messages/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      await SupabaseService.client.storage
          .from('messages')
          .uploadBinary(fileName, bytes);

      final imageUrl = SupabaseService.client.storage
          .from('messages')
          .getPublicUrl(fileName);

      debugPrint('✅ Image uploaded successfully: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Search conversations
  Future<List<ConversationModel>> searchConversations(
      String userId, String query) async {
    try {
      debugPrint('🔍 Searching conversations for: $query');

      final conversations = await getConversations(userId);

      final filteredConversations = conversations
          .where((conversation) =>
              conversation.displayName
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              conversation.lastMessage
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      debugPrint(
          '✅ Found ${filteredConversations.length} matching conversations');

      return filteredConversations;
    } catch (e) {
      debugPrint('❌ Error searching conversations: $e');
      throw Exception('Failed to search conversations: $e');
    }
  }

  // Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId, String userId) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Subscribe to conversation messages (realtime)
  RealtimeChannel subscribeToConversation(
    String conversationId,
    void Function(MessageModel message) onNewMessage,
  ) {
    debugPrint('📡 Subscribing to conversation updates: $conversationId');

    final channel = SupabaseService.client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final message = MessageModel.fromJson(payload.newRecord);
              debugPrint('📨 New message received: ${message.id}');
              onNewMessage(message);
            } catch (e) {
              debugPrint('❌ Error processing new message: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Subscribe to conversations list (realtime)
  RealtimeChannel subscribeToConversations(
    String userId,
    void Function() onConversationsChanged,
  ) {
    debugPrint('📡 Subscribing to conversations updates for user: $userId');

    final channel = SupabaseService.client
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            debugPrint('🔄 Conversations updated');
            onConversationsChanged();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            debugPrint('🔄 Messages updated');
            onConversationsChanged();
          },
        )
        .subscribe();

    return channel;
  }

  // Unsubscribe from realtime channel
  void unsubscribe(RealtimeChannel channel) {
    debugPrint('📡 Unsubscribing from realtime channel');
    SupabaseService.client.removeChannel(channel);
  }

  // Get conversation details
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      debugPrint('🔍 Fetching conversation details: $conversationId');

      final response =
          await SupabaseService.client.from('conversations').select('''
            *,
            participant_1:profiles!participant_1_id(id, full_name, avatar_url),
            participant_2:profiles!participant_2_id(id, full_name, avatar_url)
          ''').eq('id', conversationId).maybeSingle();

      if (response == null) {
        debugPrint('❌ Conversation not found: $conversationId');
        return null;
      }

      // Determine other user based on current user
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      final isParticipant1 = response['participant_1_id'] == currentUserId;

      final otherUser = isParticipant1
          ? response['participant_2']
          : response['participant_1'];

      final conversation = ConversationModel(
        id: response['id'] as String,
        conversationType:
            ConversationType.individual, // Default to individual for now
        otherUserId: otherUser['id'] as String,
        otherUserName: otherUser['full_name'] as String? ?? 'Unknown User',
        otherUserAvatar: otherUser['avatar_url'] as String?,
        lastMessage: 'Start the conversation',
        lastMessageTime: DateTime.parse(response['created_at'] as String),
        unreadCount: 0,
        messageType: 'text',
      );

      debugPrint('✅ Conversation details loaded successfully');

      return conversation;
    } catch (e) {
      debugPrint('❌ Error getting conversation details: $e');
      return null;
    }
  }
}
