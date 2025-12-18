import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/message.dart';

class MessageService {
  final _client = SupabaseConfig.client;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;

  /// Get or create a conversation between customer and barber
  Future<Conversation?> getOrCreateConversation(String barberId) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return null;

    try {
      // Check for existing conversation
      final existing = await _client
          .from('conversations')
          .select()
          .eq('customer_id', customerId)
          .eq('barber_id', barberId)
          .maybeSingle();

      if (existing != null) {
        return Conversation.fromJson(existing);
      }

      // Create new conversation
      final response = await _client
          .from('conversations')
          .insert({
            'customer_id': customerId,
            'barber_id': barberId,
          })
          .select()
          .single();

      return Conversation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get user's conversations
  Future<List<Conversation>> getConversations() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('conversations')
          .select('''
            *,
            customer:customer_id(full_name, avatar_url),
            barber:barber_id(display_name, profile_image_url)
          ''')
          .or('customer_id.eq.$userId,barber_id.eq.$userId')
          .order('last_message_at', ascending: false, nullsFirst: false);

      return (response as List).map((c) => Conversation.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from('messages')
          .select('*, sender:sender_id(full_name, avatar_url)')
          .eq('conversation_id', conversationId);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((m) => Message.fromJson(m))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Send a message
  Future<Message?> sendMessage({
    required String conversationId,
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final senderId = SupabaseConfig.currentUserId;
    if (senderId == null) return null;

    try {
      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'content': content,
            'media_url': mediaUrl,
            'media_type': mediaType,
          })
          .select()
          .single();

      // Update conversation's last message
      await _client.from('conversations').update({
        'last_message_content': mediaUrl != null ? '📷 Photo' : content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return Message.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Upload media file and send message
  Future<Message?> sendMediaMessage({
    required String conversationId,
    required File file,
    required String mediaType,
    String? caption,
  }) async {
    final senderId = SupabaseConfig.currentUserId;
    if (senderId == null) return null;

    try {
      // Generate unique filename
      final ext = file.path.split('.').last;
      final filename = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'messages/$filename';

      // Upload to Supabase Storage
      await _client.storage
          .from('chat-media')
          .upload(path, file);

      // Get public URL
      final mediaUrl = _client.storage
          .from('chat-media')
          .getPublicUrl(path);

      // Send message with media
      return sendMessage(
        conversationId: conversationId,
        content: caption ?? '📷 Photo',
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Upload media from bytes (for web/cross-platform)
  Future<Message?> sendMediaMessageFromBytes({
    required String conversationId,
    required Uint8List bytes,
    required String filename,
    required String mediaType,
    String? caption,
  }) async {
    final senderId = SupabaseConfig.currentUserId;
    if (senderId == null) return null;

    try {
      // Generate unique filename
      final ext = filename.split('.').last;
      final uniqueFilename = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'messages/$uniqueFilename';

      // Upload to Supabase Storage
      await _client.storage
          .from('chat-media')
          .uploadBinary(path, bytes);

      // Get public URL
      final mediaUrl = _client.storage
          .from('chat-media')
          .getPublicUrl(path);

      // Send message with media
      return sendMessage(
        conversationId: conversationId,
        content: caption ?? '📷 Photo',
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead(String conversationId) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return 0;

    try {
      // Get conversations where user is a participant
      final convos = await _client
          .from('conversations')
          .select('id')
          .or('customer_id.eq.$userId,barber_id.eq.$userId');

      final convoIds = (convos as List).map((c) => c['id'] as String).toList();
      if (convoIds.isEmpty) return 0;

      final response = await _client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', convoIds)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Subscribe to new messages in a conversation
  Stream<Message> subscribeToMessages(String conversationId) {
    final controller = StreamController<Message>.broadcast();

    _messagesChannel = _client
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
            final message = Message.fromJson(payload.newRecord);
            controller.add(message);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _messagesChannel?.unsubscribe();
    };

    return controller.stream;
  }

  /// Subscribe to typing indicators
  Stream<TypingStatus> subscribeToTyping(String conversationId) {
    final controller = StreamController<TypingStatus>.broadcast();
    final userId = SupabaseConfig.currentUserId;

    _typingChannel = _client
        .channel('typing:$conversationId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final typingUserId = payload['user_id'] as String?;
            final isTyping = payload['is_typing'] as bool? ?? false;
            final userName = payload['user_name'] as String?;
            
            // Don't show own typing indicator
            if (typingUserId != null && typingUserId != userId) {
              controller.add(TypingStatus(
                userId: typingUserId,
                userName: userName,
                isTyping: isTyping,
              ),);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _typingChannel?.unsubscribe();
    };

    return controller.stream;
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
    String? userName,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    try {
      await _client.channel('typing:$conversationId').sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': userId,
          'user_name': userName,
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      // Ignore typing errors
    }
  }

  /// Subscribe to all conversations updates
  Stream<Conversation> subscribeToConversations() {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return const Stream.empty();

    final controller = StreamController<Conversation>.broadcast();

    _client
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) async {
            final convo = Conversation.fromJson(payload.newRecord);
            // Only emit if user is a participant
            if (convo.customerId == userId || convo.barberId == userId) {
              controller.add(convo);
            }
          },
        )
        .subscribe();

    return controller.stream;
  }

  /// Unsubscribe from all channels
  void unsubscribe() {
    _messagesChannel?.unsubscribe();
    _messagesChannel = null;
    _typingChannel?.unsubscribe();
    _typingChannel = null;
  }

  /// Delete a message (soft delete)
  Future<bool> deleteMessage(String messageId) async {
    final senderId = SupabaseConfig.currentUserId;
    if (senderId == null) return false;

    try {
      await _client
          .from('messages')
          .update({'content': '[Message deleted]', 'media_url': null})
          .eq('id', messageId)
          .eq('sender_id', senderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Typing indicator data model
class TypingStatus {
  final String userId;
  final String? userName;
  final bool isTyping;

  TypingStatus({
    required this.userId,
    this.userName,
    required this.isTyping,
  });
}
