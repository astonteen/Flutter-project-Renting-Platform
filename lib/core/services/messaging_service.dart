import 'package:rent_ease/features/messages/data/models/message_model.dart';

class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.timestamp,
  });
}

class MessagingService {
  // TODO: Implement when required packages are added
  // This service requires: file_picker, permission_handler, path_provider, record, audioplayers

  // Mock methods for now
  Future<void> initialize() async {}
  void dispose() {}

  Stream<MessageModel> get messageStream => const Stream.empty();
  Stream<TypingIndicator> get typingStream => const Stream.empty();
  Stream<MessageModel> get messageStatusStream => const Stream.empty();
  Stream<MessageReaction> get reactionStream => const Stream.empty();

  Future<MessageModel?> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? replyToMessageId,
  }) async =>
      null;

  Future<MessageModel?> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String imagePath,
    String? caption,
  }) async =>
      null;

  Future<MessageModel?> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? caption,
    List<String>? allowedExtensions,
  }) async =>
      null;

  Future<bool> startVoiceRecording() async => false;
  Future<String?> stopVoiceRecording() async => null;
  Future<void> cancelVoiceRecording() async {}

  Future<MessageModel?> sendVoiceMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String voiceFilePath,
    required Duration duration,
  }) async =>
      null;

  Future<void> playVoiceMessage(String audioPath) async {}
  Future<void> stopVoicePlayback() async {}

  void startTyping(String conversationId, String userId, String userName) {}
  void stopTyping(String conversationId, String userId) {}

  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}

  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}

  Future<void> markMessageAsRead(String messageId, String userId) async {}
  Future<void> deleteMessage(String messageId, String userId) async {}
  Future<void> editMessage(String messageId, String newContent) async {}
}
