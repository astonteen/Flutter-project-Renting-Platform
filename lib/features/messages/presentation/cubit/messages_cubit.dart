import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/core/services/supabase_service.dart';

// States
abstract class MessagesState extends Equatable {
  const MessagesState();

  @override
  List<Object?> get props => [];
}

class MessagesInitial extends MessagesState {
  const MessagesInitial();
}

class MessagesLoading extends MessagesState {
  const MessagesLoading();
}

class UnreadCountLoaded extends MessagesState {
  final int unreadCount;

  const UnreadCountLoaded({required this.unreadCount});

  @override
  List<Object?> get props => [unreadCount];
}

class MessagesError extends MessagesState {
  final String message;

  const MessagesError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit() : super(const MessagesInitial());

  Future<void> loadUnreadCount() async {
    try {
      emit(const MessagesLoading());

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Query for unread messages count
      final response = await SupabaseService.client
          .from('messages')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      final unreadCount = response.length;
      emit(UnreadCountLoaded(unreadCount: unreadCount));
    } catch (e) {
      emit(MessagesError(
          message: 'Failed to load unread count: ${e.toString()}'));
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await SupabaseService.client
          .from('messages')
          .update({'is_read': true}).eq('id', messageId);

      // Reload count
      loadUnreadCount();
    } catch (e) {
      emit(MessagesError(
          message: 'Failed to mark message as read: ${e.toString()}'));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);

      emit(const UnreadCountLoaded(unreadCount: 0));
    } catch (e) {
      emit(MessagesError(
          message: 'Failed to mark all messages as read: ${e.toString()}'));
    }
  }

  void incrementUnreadCount() {
    final currentState = state;
    if (currentState is UnreadCountLoaded) {
      emit(UnreadCountLoaded(unreadCount: currentState.unreadCount + 1));
    }
  }

  void decrementUnreadCount() {
    final currentState = state;
    if (currentState is UnreadCountLoaded && currentState.unreadCount > 0) {
      emit(UnreadCountLoaded(unreadCount: currentState.unreadCount - 1));
    }
  }
}
