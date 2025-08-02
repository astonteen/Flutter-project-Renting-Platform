import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
  system,
  location,
  sticker,
  reply,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageReaction extends Equatable {
  final String emoji;
  final String userId;
  final String userName;
  final DateTime timestamp;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [emoji, userId, userName, timestamp];

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String? ?? '👍',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Unknown User',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class MessageAttachment extends Equatable {
  final String id;
  final String url;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  const MessageAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailUrl,
    this.metadata,
  });

  @override
  List<Object?> get props =>
      [id, url, fileName, mimeType, fileSize, thumbnailUrl, metadata];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'thumbnail_url': thumbnailUrl,
      'metadata': metadata,
    };
  }

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'Unknown File',
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      thumbnailUrl: json['thumbnail_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class ReplyToMessage extends Equatable {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;

  const ReplyToMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
  });

  @override
  List<Object?> get props => [messageId, senderId, senderName, content, type];

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'type': type.name,
    };
  }

  factory ReplyToMessage.fromJson(Map<String, dynamic> json) {
    return ReplyToMessage(
      messageId: json['message_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'Unknown User',
      content: json['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }
}

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final List<MessageReaction> reactions;
  final List<MessageAttachment> attachments;
  final ReplyToMessage? replyTo;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final bool isDeleted;
  final bool isEdited;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.editedAt,
    this.reactions = const [],
    this.attachments = const [],
    this.replyTo,
    this.metadata,
    this.readBy = const [],
    this.isDeleted = false,
    this.isEdited = false,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatar,
        content,
        type,
        status,
        timestamp,
        editedAt,
        reactions,
        attachments,
        replyTo,
        metadata,
        readBy,
        isDeleted,
        isEdited,
      ];

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    List<MessageReaction>? reactions,
    List<MessageAttachment>? attachments,
    ReplyToMessage? replyTo,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    bool? isDeleted,
    bool? isEdited,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'reply_to': replyTo?.toJson(),
      'metadata': metadata,
      'read_by': readBy,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Extract sender info from nested profile data
    final senderProfile = json['sender'] as Map<String, dynamic>?;

    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: senderProfile?['full_name'] as String? ??
          json['sender_name'] as String? ??
          'Unknown User',
      senderAvatar: senderProfile?['avatar_url'] as String? ??
          json['sender_avatar'] as String?,
      content: json['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) =>
            e.name ==
            (json['message_type'] ?? json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now()),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromJson(r))
              .toList() ??
          [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((a) => MessageAttachment.fromJson(a))
              .toList() ??
          [],
      replyTo: json['reply_to'] != null
          ? ReplyToMessage.fromJson(json['reply_to'])
          : null,
      metadata: json['metadata'],
      readBy: List<String>.from(json['read_by'] ?? []),
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
    );
  }

  // Helper methods
  bool get isRead => status == MessageStatus.read;
  bool get hasReactions => reactions.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyTo != null;
  bool get isVoiceMessage => type == MessageType.voice;
  bool get isImageMessage => type == MessageType.image;
  bool get isFileMessage => type == MessageType.file;

  List<MessageReaction> getReactionsForEmoji(String emoji) {
    return reactions.where((r) => r.emoji == emoji).toList();
  }

  bool hasUserReacted(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  Duration? get voiceDuration {
    if (type == MessageType.voice && metadata != null) {
      return Duration(seconds: metadata!['duration'] ?? 0);
    }
    return null;
  }

  // Add missing getter properties
  bool get hasImage => type == MessageType.image && attachments.isNotEmpty;
  String? get imageUrl => hasImage ? attachments.first.url : null;
  bool get hasContent => content.isNotEmpty;
  DateTime get createdAt => timestamp;
}
