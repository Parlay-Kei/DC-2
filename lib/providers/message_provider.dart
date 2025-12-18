import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/message_service.dart';
import '../models/message.dart';

// Service provider
final messageServiceProvider = Provider((ref) => MessageService());

// User's conversations
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.read(messageServiceProvider).getConversations();
});

// Messages for a conversation
final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.read(messageServiceProvider).getMessages(conversationId);
});

// Unread count
final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.read(messageServiceProvider).getUnreadCount();
});

// Get or create conversation with barber
final getConversationProvider =
    FutureProvider.family<Conversation?, String>((ref, barberId) {
  return ref.read(messageServiceProvider).getOrCreateConversation(barberId);
});

// Real-time message stream for a conversation
final messageStreamProvider =
    StreamProvider.family<Message, String>((ref, conversationId) {
  return ref.read(messageServiceProvider).subscribeToMessages(conversationId);
});

// Chat state
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  factory ChatState.initial() => ChatState();

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Chat notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final MessageService _messageService;
  final String conversationId;
  StreamSubscription? _subscription;

  ChatNotifier(this._messageService, this.conversationId)
      : super(ChatState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final messages = await _messageService.getMessages(conversationId);
      state = state.copyWith(messages: messages, isLoading: false);
      await _messageService.markAsRead(conversationId);
      _subscription = _messageService
          .subscribeToMessages(conversationId)
          .listen(_onNewMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _onNewMessage(Message message) {
    state = state.copyWith(messages: [...state.messages, message]);
    _messageService.markAsRead(conversationId);
  }

  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;
    state = state.copyWith(isSending: true);
    try {
      final message = await _messageService.sendMessage(
        conversationId: conversationId,
        content: content.trim(),
      );
      state = state.copyWith(isSending: false);
      return message != null;
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageService.unsubscribe();
    super.dispose();
  }
}

// Chat provider
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, conversationId) {
    return ChatNotifier(ref.read(messageServiceProvider), conversationId);
  },
);
