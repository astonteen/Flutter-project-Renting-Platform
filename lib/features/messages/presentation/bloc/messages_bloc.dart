import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/messages/data/models/message_model.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Events
abstract class MessagesEvent extends Equatable {
  const MessagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessagesEvent {}

class LoadMessages extends MessagesEvent {
  final String conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendTextMessage extends MessagesEvent {
  final String conversationId;
  final String content;

  const SendTextMessage({
    required this.conversationId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, content];
}

class SendImageMessage extends MessagesEvent {
  final String conversationId;
  final Uint8List imageBytes;
  final String fileName;
  final String? caption;

  const SendImageMessage({
    required this.conversationId,
    required this.imageBytes,
    required this.fileName,
    this.caption,
  });

  @override
  List<Object?> get props => [conversationId, imageBytes, fileName, caption];
}

class CreateConversation extends MessagesEvent {
  final String otherUserId;

  const CreateConversation(this.otherUserId);

  @override
  List<Object?> get props => [otherUserId];
}

class MarkMessagesAsRead extends MessagesEvent {
  final String conversationId;

  const MarkMessagesAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SearchConversations extends MessagesEvent {
  final String query;

  const SearchConversations(this.query);

  @override
  List<Object?> get props => [query];
}

class SubscribeToConversation extends MessagesEvent {
  final String conversationId;

  const SubscribeToConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class UnsubscribeFromConversation extends MessagesEvent {}

class NewMessageReceived extends MessagesEvent {
  final MessageModel message;

  const NewMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class RefreshConversations extends MessagesEvent {}

// States
abstract class MessagesState extends Equatable {
  const MessagesState();

  @override
  List<Object?> get props => [];
}

class MessagesInitial extends MessagesState {}

class MessagesLoading extends MessagesState {}

class ConversationsLoaded extends MessagesState {
  final List<ConversationModel> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ConversationSearchResults extends MessagesState {
  final List<ConversationModel> results;
  final String query;

  const ConversationSearchResults(this.results, this.query);

  @override
  List<Object?> get props => [results, query];
}

class MessagesLoaded extends MessagesState {
  final List<MessageModel> messages;
  final String conversationId;

  const MessagesLoaded(this.messages, this.conversationId);

  @override
  List<Object?> get props => [messages, conversationId];
}

class MessageAdded extends MessagesState {
  final List<MessageModel> messages;
  final MessageModel newMessage;
  final String conversationId;

  const MessageAdded(this.messages, this.newMessage, this.conversationId);

  @override
  List<Object?> get props => [messages, newMessage, conversationId];
}

class ConversationCreated extends MessagesState {
  final String conversationId;

  const ConversationCreated(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MessagesError extends MessagesState {
  final String message;

  const MessagesError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageSending extends MessagesState {}

class MessageSent extends MessagesState {
  final MessageModel message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ImageUploading extends MessagesState {}

class EmptyMessagesState extends MessagesState {
  final String title;
  final String subtitle;
  final String actionText;
  final String actionRoute;

  const EmptyMessagesState({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.actionRoute,
  });

  @override
  List<Object?> get props => [title, subtitle, actionText, actionRoute];
}

// BLoC
class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessagesRepository _messagesRepository;
  RealtimeChannel? _conversationChannel;
  RealtimeChannel? _conversationsChannel;
  List<MessageModel> _currentMessages = [];

  MessagesBloc({MessagesRepository? messagesRepository})
      : _messagesRepository = messagesRepository ?? MessagesRepository(),
        super(MessagesInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<CreateConversation>(_onCreateConversation);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<SearchConversations>(_onSearchConversations);
    on<SubscribeToConversation>(_onSubscribeToConversation);
    on<UnsubscribeFromConversation>(_onUnsubscribeFromConversation);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<RefreshConversations>(_onRefreshConversations);
  }

  @override
  Future<void> close() {
    _unsubscribeFromAll();
    return super.close();
  }

  void _unsubscribeFromAll() {
    if (_conversationChannel != null) {
      _messagesRepository.unsubscribe(_conversationChannel!);
      _conversationChannel = null;
    }
    if (_conversationsChannel != null) {
      _messagesRepository.unsubscribe(_conversationsChannel!);
      _conversationsChannel = null;
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagesState> emit,
  ) async {
    emit(MessagesLoading());

    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const MessagesError('User not authenticated'));
        return;
      }

      final conversations =
          await _messagesRepository.getConversations(currentUser.id);
      emit(ConversationsLoaded(conversations));

      // Subscribe to conversations updates
      _conversationsChannel = _messagesRepository.subscribeToConversations(
        currentUser.id,
        () => add(RefreshConversations()),
      );
    } catch (e) {
      emit(MessagesError('Failed to load conversations: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagesState> emit,
  ) async {
    emit(MessagesLoading());

    try {
      final messages =
          await _messagesRepository.getMessages(event.conversationId);
      _currentMessages = messages;
      emit(MessagesLoaded(messages, event.conversationId));
    } catch (e) {
      emit(MessagesError('Failed to load messages: ${e.toString()}'));
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<MessagesState> emit,
  ) async {
    emit(MessageSending());

    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const MessagesError('User not authenticated'));
        return;
      }

      final message = await _messagesRepository.sendMessage(
        conversationId: event.conversationId,
        senderId: currentUser.id,
        content: event.content,
      );

      // Add to current messages list
      _currentMessages = [..._currentMessages, message];
      emit(MessageAdded(_currentMessages, message, event.conversationId));
    } catch (e) {
      emit(MessagesError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<MessagesState> emit,
  ) async {
    emit(ImageUploading());

    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const MessagesError('User not authenticated'));
        return;
      }

      // Upload image first
      final imageUrl = await _messagesRepository.uploadImage(
        event.fileName,
        event.imageBytes,
      );

      // Send image message
      final message = await _messagesRepository.sendImageMessage(
        conversationId: event.conversationId,
        senderId: currentUser.id,
        imageUrl: imageUrl,
        caption: event.caption,
      );

      // Add to current messages list
      _currentMessages = [..._currentMessages, message];
      emit(MessageAdded(_currentMessages, message, event.conversationId));
    } catch (e) {
      emit(MessagesError('Failed to send image: ${e.toString()}'));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MessagesState> emit,
  ) async {
    emit(MessagesLoading());

    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const MessagesError('User not authenticated'));
        return;
      }

      final conversationId = await _messagesRepository.getOrCreateConversation(
        currentUser.id,
        event.otherUserId,
      );

      emit(ConversationCreated(conversationId));
    } catch (e) {
      emit(MessagesError('Failed to create conversation: ${e.toString()}'));
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      await _messagesRepository.markMessagesAsRead(
        event.conversationId,
        currentUser.id,
      );
    } catch (e) {
      // Silent fail for mark as read
    }
  }

  Future<void> _onSearchConversations(
    SearchConversations event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const MessagesError('User not authenticated'));
        return;
      }

      final results = await _messagesRepository.searchConversations(
        currentUser.id,
        event.query,
      );

      emit(ConversationSearchResults(results, event.query));
    } catch (e) {
      emit(MessagesError('Failed to search conversations: ${e.toString()}'));
    }
  }

  Future<void> _onSubscribeToConversation(
    SubscribeToConversation event,
    Emitter<MessagesState> emit,
  ) async {
    // Unsubscribe from previous conversation
    if (_conversationChannel != null) {
      _messagesRepository.unsubscribe(_conversationChannel!);
    }

    // Subscribe to new conversation
    _conversationChannel = _messagesRepository.subscribeToConversation(
      event.conversationId,
      (message) => add(NewMessageReceived(message)),
    );
  }

  Future<void> _onUnsubscribeFromConversation(
    UnsubscribeFromConversation event,
    Emitter<MessagesState> emit,
  ) async {
    if (_conversationChannel != null) {
      _messagesRepository.unsubscribe(_conversationChannel!);
      _conversationChannel = null;
    }
  }

  Future<void> _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<MessagesState> emit,
  ) async {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    // Add to current messages if not from current user
    if (event.message.senderId != currentUser.id) {
      _currentMessages = [..._currentMessages, event.message];

      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        emit(MessageAdded(
            _currentMessages, event.message, currentState.conversationId));
      }
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      final conversations =
          await _messagesRepository.getConversations(currentUser.id);
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      // Silent fail for refresh
    }
  }
}
