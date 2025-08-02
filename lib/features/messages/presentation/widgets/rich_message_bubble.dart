import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/message_model.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/loading_widget.dart';

class RichMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onReply;
  final Function(String emoji)? onReaction;
  final VoidCallback? onImageTap;
  final VoidCallback? onFileTap;
  final VoidCallback? onVoicePlay;
  final bool isVoicePlaying;
  final Duration? voicePosition;
  final bool showReadReceipts;
  final bool showReactions;
  final bool showTimestamp;

  const RichMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onReply,
    this.onReaction,
    this.onImageTap,
    this.onFileTap,
    this.onVoicePlay,
    this.isVoicePlaying = false,
    this.voicePosition,
    this.showReadReceipts = true,
    this.showReactions = true,
    this.showTimestamp = true,
  });

  @override
  State<RichMessageBubble> createState() => _RichMessageBubbleState();
}

class _RichMessageBubbleState extends State<RichMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isReactionPickerVisible = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<String> _quickReactions = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
    '👎'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showMessageOptions,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          crossAxisAlignment: widget.isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (widget.message.isReply) _buildReplyPreview(),
            Row(
              mainAxisAlignment: widget.isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isCurrentUser) _buildAvatar(),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
                if (widget.isCurrentUser) _buildMessageStatus(),
              ],
            ),
            if (widget.message.hasReactions && widget.showReactions)
              _buildReactions(),
            if (widget.showTimestamp) _buildTimestamp(),
            if (_isReactionPickerVisible) _buildReactionPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
        backgroundImage: widget.message.senderAvatar != null
            ? NetworkImage(widget.message.senderAvatar!)
            : null,
        child: widget.message.senderAvatar == null
            ? Text(
                widget.message.senderName.substring(0, 1).toUpperCase(),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? ColorConstants.primary
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isCurrentUser) _buildSenderName(),
          _buildMessageBody(),
          if (widget.message.isEdited) _buildEditedIndicator(),
        ],
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        widget.message.senderName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: ColorConstants.primary,
        ),
      ),
    );
  }

  Widget _buildMessageBody() {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.voice:
        return _buildVoiceMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.location:
        return _buildLocationMessage();
      case MessageType.sticker:
        return _buildStickerMessage();
      case MessageType.system:
        return _buildSystemMessage();
      case MessageType.reply:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return SelectableText(
      widget.message.content,
      style: TextStyle(
        fontSize: 16,
        color: widget.isCurrentUser ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildImageMessage() {
    if (widget.message.attachments.isEmpty) {
      return const Text('Image not available');
    }

    final attachment = widget.message.attachments.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onImageTap,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                attachment.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: SkeletonLoader(
                        child: Container(
                          width: 250,
                          height: 150,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content,
              style: TextStyle(
                fontSize: 14,
                color: widget.isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceMessage() {
    final duration = widget.message.voiceDuration ?? Duration.zero;
    final position = widget.voicePosition ?? Duration.zero;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onVoicePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isCurrentUser
                    ? Colors.white.withValues(alpha: 0.2)
                    : ColorConstants.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isVoicePlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isCurrentUser
                    ? Colors.white
                    : ColorConstants.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: (widget.isCurrentUser ? Colors.white : Colors.grey)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                  child: LinearProgressIndicator(
                    value: duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isCurrentUser
                          ? Colors.white
                          : ColorConstants.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isCurrentUser
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage() {
    if (widget.message.attachments.isEmpty) {
      return const Text('File not available');
    }

    final attachment = widget.message.attachments.first;
    return GestureDetector(
      onTap: widget.onFileTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isCurrentUser
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(attachment.mimeType),
              size: 32,
              color:
                  widget.isCurrentUser ? Colors.white : ColorConstants.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          widget.isCurrentUser ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(attachment.fileSize),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isCurrentUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: widget.isCurrentUser ? Colors.white : ColorConstants.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Location shared',
            style: TextStyle(
              fontSize: 14,
              color: widget.isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.emoji_emotions,
        size: 80,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.message.content,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final replyTo = widget.message.replyTo!;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: ColorConstants.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyTo.senderName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyTo.content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    final reactionGroups = <String, List<MessageReaction>>{};
    for (final reaction in widget.message.reactions) {
      reactionGroups[reaction.emoji] ??= [];
      reactionGroups[reaction.emoji]!.add(reaction);
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionGroups.entries.map((entry) {
          final emoji = entry.key;
          final reactions = entry.value;
          return GestureDetector(
            onTap: () => widget.onReaction?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${reactions.length}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTimestamp(widget.message.timestamp),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!widget.isCurrentUser) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (widget.message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(left: 4, bottom: 4),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildEditedIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'edited',
        style: TextStyle(
          fontSize: 10,
          color: widget.isCurrentUser
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildReactionPicker() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _quickReactions.map((emoji) {
            return GestureDetector(
              onTap: () {
                widget.onReaction?.call(emoji);
                _hideReactionPicker();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text copied to clipboard')),
                );
              },
            ),
            if (widget.isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle delete
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker() {
    setState(() {
      _isReactionPickerVisible = true;
    });
    _animationController.forward();
  }

  void _hideReactionPicker() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isReactionPickerVisible = false;
        });
      }
    });
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('powerpoint')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('rar')) {
      return Icons.archive;
    }
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
