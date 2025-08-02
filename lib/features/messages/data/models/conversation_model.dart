import 'package:equatable/equatable.dart';

enum ConversationType { individual, group }

class ConversationModel extends Equatable {
  final String id;
  final ConversationType conversationType;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? groupName;
  final String? groupAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String messageType;
  final String? itemName;

  const ConversationModel({
    required this.id,
    required this.conversationType,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.groupName,
    this.groupAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.messageType,
    this.itemName,
  });

  // Helper getters
  bool get isGroup => conversationType == ConversationType.group;
  bool get isIndividual => conversationType == ConversationType.individual;

  String get displayName {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    }
    return otherUserName ?? 'Unknown User';
  }

  String? get displayAvatar {
    if (isGroup) {
      return groupAvatar;
    }
    return otherUserAvatar;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final conversationTypeStr =
        json['conversation_type'] as String? ?? 'individual';
    final conversationType = conversationTypeStr == 'group'
        ? ConversationType.group
        : ConversationType.individual;

    return ConversationModel(
      id: (json['conversation_id'] ?? json['id']) as String? ?? '',
      conversationType: conversationType,
      otherUserId: json['other_user_id'] as String?,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
      groupName: json['group_name'] as String?,
      groupAvatar: json['group_avatar'] as String?,
      lastMessage: json['last_message'] as String? ?? 'No messages yet',
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : DateTime.now(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      messageType: json['message_type'] as String? ?? 'text',
      itemName: json['item_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': id,
      'conversation_type':
          conversationType == ConversationType.group ? 'group' : 'individual',
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'group_name': groupName,
      'group_avatar': groupAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'message_type': messageType,
      'item_name': itemName,
    };
  }

  ConversationModel copyWith({
    String? id,
    ConversationType? conversationType,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? groupName,
    String? groupAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? messageType,
    String? itemName,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      conversationType: conversationType ?? this.conversationType,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      groupName: groupName ?? this.groupName,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messageType: messageType ?? this.messageType,
      itemName: itemName ?? this.itemName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationType,
        otherUserId,
        otherUserName,
        otherUserAvatar,
        groupName,
        groupAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
        messageType,
        itemName,
      ];

  @override
  String toString() {
    return 'ConversationModel(id: $id, type: $conversationType, displayName: $displayName, unreadCount: $unreadCount)';
  }
}
