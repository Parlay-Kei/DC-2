import '../config/supabase_config.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? translatedContent;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;
  final DateTime createdAt;

  // Sender info (joined)
  final String? senderName;
  final String? senderAvatar;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.translatedContent,
    this.mediaUrl,
    this.mediaType,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      translatedContent: json['translated_content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: sender?['full_name'] as String?,
      senderAvatar: sender?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'translated_content': translatedContent,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isMe => senderId == SupabaseConfig.currentUserId;
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get hasTranslation =>
      translatedContent != null && translatedContent!.isNotEmpty;

  String get timeStamp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) {
      return _formatTime(createdAt);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${_formatTime(createdAt)}';
    } else {
      return '${createdAt.month}/${createdAt.day} ${_formatTime(createdAt)}';
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? translatedContent,
    String? mediaUrl,
    String? mediaType,
    bool? isRead,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      translatedContent: translatedContent ?? this.translatedContent,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}

class Conversation {
  final String id;
  final String customerId;
  final String barberId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  // Participant info (joined)
  final String? customerName;
  final String? customerAvatar;
  final String? barberName;
  final String? barberAvatar;

  Conversation({
    required this.id,
    required this.customerId,
    required this.barberId,
    this.lastMessageContent,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    this.customerName,
    this.customerAvatar,
    this.barberName,
    this.barberAvatar,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final barber = json['barber'] as Map<String, dynamic>?;

    return Conversation(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      barberId: json['barber_id'] as String,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: customer?['full_name'] as String?,
      customerAvatar: customer?['avatar_url'] as String?,
      barberName:
          barber?['full_name'] as String? ?? barber?['display_name'] as String?,
      barberAvatar:
          barber?['avatar_url'] as String? ?? barber?['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'barber_id': barberId,
      'last_message_content': lastMessageContent,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get hasUnread => unreadCount > 0;

  /// Get the other participant's name (from current user's perspective)
  String? get otherParticipantName {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == customerId) {
      return barberName;
    } else {
      return customerName;
    }
  }

  /// Get the other participant's avatar (from current user's perspective)
  String? get otherParticipantAvatar {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == customerId) {
      return barberAvatar;
    } else {
      return customerAvatar;
    }
  }

  /// Get the other participant's ID
  String get otherParticipantId {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == customerId) {
      return barberId;
    } else {
      return customerId;
    }
  }

  String get lastMessagePreview {
    if (lastMessageContent == null) return 'No messages yet';
    if (lastMessageContent!.length > 50) {
      return '${lastMessageContent!.substring(0, 50)}...';
    }
    return lastMessageContent!;
  }

  String get lastMessageTime {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${lastMessageAt!.month}/${lastMessageAt!.day}';
  }

  /// Time ago for display in conversation list
  String get timeAgo {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${lastMessageAt!.month}/${lastMessageAt!.day}';
  }

  Conversation copyWith({
    String? id,
    String? customerId,
    String? barberId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    String? customerName,
    String? customerAvatar,
    String? barberName,
    String? barberAvatar,
  }) {
    return Conversation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      barberName: barberName ?? this.barberName,
      barberAvatar: barberAvatar ?? this.barberAvatar,
    );
  }
}
