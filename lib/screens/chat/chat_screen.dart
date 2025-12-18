import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? recipientName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.recipientName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  bool _otherUserTyping = false;
  String? _typingUserName;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  String? _recipientName;
  String? _recipientAvatar;
  Timer? _typingDebounce;
  bool _lastTypingState = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToTyping();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    // Send not typing when leaving
    _sendTypingIndicator(false);
    super.dispose();
  }

  void _onTypingChanged() {
    final isTyping = _messageController.text.isNotEmpty;
    
    // Only send if state changed
    if (isTyping != _lastTypingState) {
      _lastTypingState = isTyping;
      _sendTypingIndicator(isTyping);
    }
    
    // Reset debounce timer
    _typingDebounce?.cancel();
    if (isTyping) {
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        _sendTypingIndicator(false);
        _lastTypingState = false;
      });
    }
  }

  Future<void> _sendTypingIndicator(bool isTyping) async {
    final service = ref.read(messageServiceProvider);
    await service.sendTypingIndicator(
      conversationId: widget.conversationId,
      isTyping: isTyping,
      userName: null, // Will be filled from profile if needed
    );
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(messageServiceProvider);
      final messages = await service.getMessages(widget.conversationId);
      
      // Get conversation details for recipient info
      final conversations = await service.getConversations();
      final convo = conversations.where((c) => c.id == widget.conversationId).firstOrNull;
      
      if (convo != null) {
        _recipientName = convo.otherParticipantName;
        _recipientAvatar = convo.otherParticipantAvatar;
      }
      
      // Mark as read
      await service.markAsRead(widget.conversationId);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    final service = ref.read(messageServiceProvider);
    _messageSubscription = service.subscribeToMessages(widget.conversationId).listen((message) {
      if (!_messages.any((m) => m.id == message.id)) {
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
        service.markAsRead(widget.conversationId);
      }
    });
  }

  void _subscribeToTyping() {
    final service = ref.read(messageServiceProvider);
    _typingSubscription = service.subscribeToTyping(widget.conversationId).listen((indicator) {
      setState(() {
        _otherUserTyping = indicator.isTyping;
        _typingUserName = indicator.userName;
      });
    });
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _sendTypingIndicator(false);
    _lastTypingState = false;

    try {
      final service = ref.read(messageServiceProvider);
      final message = await service.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      if (message != null && !_messages.any((m) => m.id == message.id)) {
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
      }
      
      // Refresh conversations list
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _sendImageMessage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final service = ref.read(messageServiceProvider);
      final message = await service.sendMediaMessage(
        conversationId: widget.conversationId,
        file: imageFile,
        mediaType: 'image',
      );

      if (message != null && !_messages.any((m) => m.id == message.id)) {
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
      }

      ref.invalidate(conversationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sent'),
            backgroundColor: DCTheme.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_otherUserTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: DCTheme.surface,
            backgroundImage: _recipientAvatar != null
                ? NetworkImage(_recipientAvatar!)
                : null,
            child: _recipientAvatar == null
                ? Text(
                    _recipientName?.isNotEmpty == true
                        ? _recipientName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: DCTheme.text, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName ?? _recipientName ?? 'Chat',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_otherUserTyping)
                  const Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: DCTheme.primary,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const Text(
                    'Tap for info',
                    style: TextStyle(
                      fontSize: 12,
                      color: DCTheme.textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice calls coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showChatOptions();
          },
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: DCTheme.surface,
            backgroundImage: _recipientAvatar != null
                ? NetworkImage(_recipientAvatar!)
                : null,
            child: _recipientAvatar == null
                ? Text(
                    _typingUserName?.isNotEmpty == true
                        ? _typingUserName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: DCTheme.text, fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DCTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: DCTheme.textMuted.withValues(alpha: 0.3 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DCTheme.primary),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: DCTheme.textMuted.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No messages yet',
                style: TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Say hello to ${_recipientName ?? 'start the conversation'}!',
                style: const TextStyle(color: DCTheme.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDate = index == 0 ||
            !_isSameDay(_messages[index - 1].createdAt, message.createdAt);
        
        return Column(
          children: [
            if (showDate) _buildDateDivider(message.createdAt),
            _MessageBubble(
              message: message,
              showAvatar: !message.isMe && (
                index == _messages.length - 1 ||
                _messages[index + 1].senderId != message.senderId
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: DCTheme.border.withValues(alpha: 0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateDivider(date),
              style: const TextStyle(
                color: DCTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: DCTheme.border.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 24,
      ),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(color: DCTheme.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DCTheme.primary,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              color: DCTheme.textMuted,
              onPressed: _isUploading ? null : _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DCTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(color: DCTheme.text),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: DCTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: DCTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                color: Colors.white,
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DCTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DCTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.location_on,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location sharing coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DCTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DCTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: DCTheme.text),
              title: const Text('Search in chat', style: TextStyle(color: DCTheme.text)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: DCTheme.text),
              title: const Text('Mute notifications', style: TextStyle(color: DCTheme.text)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mute coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: DCTheme.error),
              title: const Text('Block user', style: TextStyle(color: DCTheme.error)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';
    
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: DCTheme.surface,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Text(
                      message.senderName?.isNotEmpty == true
                          ? message.senderName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: DCTheme.text, fontSize: 10),
                    )
                  : null,
            )
          else if (!isMe)
            const SizedBox(width: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: message.hasMedia 
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? DCTheme.primary : DCTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.hasMedia && message.isImage)
                    GestureDetector(
                      onTap: () => _showFullImage(context, message.mediaUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          width: 200,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 200,
                              height: 150,
                              color: DCTheme.surfaceSecondary,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: DCTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: 150,
                            color: DCTheme.surfaceSecondary,
                            child: const Icon(
                              Icons.broken_image,
                              color: DCTheme.textMuted,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!message.hasMedia || message.content != '📷 Photo')
                    Padding(
                      padding: message.hasMedia 
                          ? const EdgeInsets.fromLTRB(10, 8, 10, 0)
                          : EdgeInsets.zero,
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : DCTheme.text,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (message.hasTranslation) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : DCTheme.surfaceSecondary)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate,
                            size: 14,
                            color: isMe ? Colors.white70 : DCTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.translatedContent!,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : DCTheme.textMuted,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: message.hasMedia 
                        ? const EdgeInsets.fromLTRB(10, 4, 10, 6)
                        : const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeStamp,
                          style: TextStyle(
                            color: isMe ? Colors.white60 : DCTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead ? Colors.lightBlueAccent : Colors.white60,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) const SizedBox(width: 28),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullImageScreen(imageUrl: imageUrl),
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const _FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: DCTheme.text,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
