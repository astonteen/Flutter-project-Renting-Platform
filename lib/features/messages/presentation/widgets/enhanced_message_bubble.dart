import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/messages/presentation/widgets/enhanced_message_input.dart';

class EnhancedMessageBubble extends StatefulWidget {
  final String messageId;
  final String content;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String? imageUrl;
  final String? voiceUrl;
  final double? latitude;
  final double? longitude;
  final String? replyToMessageId;
  final String? replyToContent;
  final Map<String, List<String>> reactions;
  final bool isRead;
  final Function(String)? onReply;
  final Function(String, String)? onReactionToggle;
  final Function()? onImageTap;
  final Function()? onVoicePlay;

  const EnhancedMessageBubble({
    super.key,
    required this.messageId,
    required this.content,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
    this.senderAvatar,
    this.type = MessageType.text,
    this.imageUrl,
    this.voiceUrl,
    this.latitude,
    this.longitude,
    this.replyToMessageId,
    this.replyToContent,
    this.reactions = const {},
    this.isRead = false,
    this.onReply,
    this.onReactionToggle,
    this.onImageTap,
    this.onVoicePlay,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showReactions = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showReactionPicker() {
    setState(() {
      _showReactions = true;
    });
    _animationController.forward();
  }

  void _hideReactionPicker() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showReactions = false;
        });
      }
    });
  }

  void _addReaction(String emoji) {
    widget.onReactionToggle?.call(widget.messageId, emoji);
    _hideReactionPicker();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideReactionPicker,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment:
                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe) _buildAvatar(),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!widget.isMe) _buildSenderName(),
                      _buildMessageContainer(),
                      _buildReactions(),
                      _buildTimestamp(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isMe) _buildAvatar(),
              ],
            ),
            if (_showReactions) _buildReactionPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: widget.senderAvatar != null
          ? NetworkImage(widget.senderAvatar!)
          : null,
      child: widget.senderAvatar == null
          ? Text(
              widget.senderName.isNotEmpty ? widget.senderName[0] : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Text(
        widget.senderName,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageContainer() {
    return GestureDetector(
      onLongPress: _showReactionPicker,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: widget.isMe ? ColorConstants.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: widget.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: widget.isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.replyToContent != null) _buildReplyPreview(),
            _buildMessageContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white : ColorConstants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reply to:',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                Text(
                  widget.replyToContent!,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isMe ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.voice:
        return _buildVoiceContent();
      case MessageType.location:
        return _buildLocationContent();
      case MessageType.file:
        return _buildFileContent();
    }
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          _buildMessageActions(),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onImageTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.imageUrl != null
                ? Image.network(
                    widget.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.red),
                      );
                    },
                  )
                : Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
          ),
        ),
        if (widget.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.content,
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: _buildMessageActions(),
        ),
      ],
    );
  }

  Widget _buildVoiceContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onVoicePlay,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white
                        : ColorConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: widget.isMe
                        ? ColorConstants.primaryColor
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: List.generate(20, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: (index % 3 + 1) * 8.0,
                          decoration: BoxDecoration(
                            color:
                                widget.isMe ? Colors.white : Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:15',
                style: TextStyle(
                  color: widget.isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          _buildMessageActions(),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Mock map view
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.green[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Location shared',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildMessageActions(),
        ),
      ],
    );
  }

  Widget _buildFileContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      widget.isMe ? Colors.white : ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color:
                      widget.isMe ? ColorConstants.primaryColor : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: widget.isMe ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '2.5 MB',
                      style: TextStyle(
                        color: widget.isMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: widget.isMe ? Colors.white : Colors.grey[600],
              ),
            ],
          ),
          _buildMessageActions(),
        ],
      ),
    );
  }

  Widget _buildMessageActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onReply != null)
          GestureDetector(
            onTap: () => widget.onReply!(widget.content),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Reply',
                style: TextStyle(
                  color: widget.isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReactions() {
    if (widget.reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MessageReactions(
        messageId: widget.messageId,
        reactions: widget.reactions,
        onReactionToggle: widget.onReactionToggle ?? (_, __) {},
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(widget.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          if (widget.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              widget.isRead ? Icons.done_all : Icons.done,
              size: 12,
              color: widget.isRead ? Colors.blue : Colors.grey[600],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionPicker() {
    return Positioned(
      top: widget.isMe ? 0 : 40,
      right: widget.isMe ? 50 : null,
      left: widget.isMe ? null : 50,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
              return GestureDetector(
                onTap: () => _addReaction(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

enum MessageType {
  text,
  image,
  voice,
  location,
  file,
}

// Typing Indicator Widget
class TypingIndicator extends StatefulWidget {
  final String userName;

  const TypingIndicator({
    super.key,
    required this.userName,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0] : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} is typing',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final animationValue =
                            (_animation.value - delay).clamp(0.0, 1.0);
                        final opacity = (animationValue * 2).clamp(0.0, 1.0);

                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600]!.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
