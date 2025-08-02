import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class EnhancedMessageInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File) onSendImage;
  final Function(File) onSendVoice;
  final Function(double, double) onSendLocation;
  final bool isLoading;
  final String? replyToMessage;
  final VoidCallback? onCancelReply;

  const EnhancedMessageInput({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onSendLocation,
    this.isLoading = false,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  State<EnhancedMessageInput> createState() => _EnhancedMessageInputState();
}

class _EnhancedMessageInputState extends State<EnhancedMessageInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showAttachmentMenu = false;
  bool _isRecording = false;
  bool _canSend = false;

  late AnimationController _attachmentAnimationController;
  late AnimationController _recordingAnimationController;
  late Animation<double> _attachmentAnimation;
  late Animation<double> _recordingAnimation;

  @override
  void initState() {
    super.initState();

    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimationController,
      curve: Curves.easeInOut,
    );

    _recordingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));

    _controller.addListener(() {
      final canSend = _controller.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() {
          _canSend = canSend;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _attachmentAnimationController.dispose();
    _recordingAnimationController.dispose();
    super.dispose();
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });

    if (_showAttachmentMenu) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
  }

  void _sendMessage() {
    if (_canSend && !widget.isLoading) {
      final text = _controller.text.trim();
      widget.onSendText(text);
      _controller.clear();
      _hideAttachmentMenu();
    }
  }

  void _hideAttachmentMenu() {
    if (_showAttachmentMenu) {
      setState(() {
        _showAttachmentMenu = false;
      });
      _attachmentAnimationController.reverse();
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
    _recordingAnimationController.repeat(reverse: true);
    _hideAttachmentMenu();

    // TODO: Implement actual voice recording
    // For now, simulate recording
    Future.delayed(const Duration(seconds: 3), () {
      _stopVoiceRecording();
    });
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    _recordingAnimationController.stop();

    // TODO: Save and send voice message
    // For now, create a mock file
    // widget.onSendVoice(mockVoiceFile);
  }

  void _pickImage(ImageSource source) async {
    _hideAttachmentMenu();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      widget.onSendImage(File(pickedFile.path));
    }
  }

  void _shareLocation() async {
    _hideAttachmentMenu();

    // TODO: Implement actual location sharing
    // For now, use mock coordinates
    widget.onSendLocation(37.7749, -122.4194); // San Francisco coordinates
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reply preview
          if (widget.replyToMessage != null) _buildReplyPreview(),

          // Attachment menu
          if (_showAttachmentMenu) _buildAttachmentMenu(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: ColorConstants.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.replyToMessage!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_attachmentAnimation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAttachmentOption(
              icon: Icons.photo_camera,
              label: 'Camera',
              color: Colors.blue,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            _buildAttachmentOption(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.green,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            _buildAttachmentOption(
              icon: Icons.location_on,
              label: 'Location',
              color: Colors.red,
              onTap: _shareLocation,
            ),
            _buildAttachmentOption(
              icon: Icons.attach_file,
              label: 'File',
              color: Colors.orange,
              onTap: () {
                // TODO: Implement file picker
                _hideAttachmentMenu();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (_isRecording) {
      return _buildRecordingInterface();
    }

    return Row(
      children: [
        // Attachment button
        IconButton(
          onPressed: _toggleAttachmentMenu,
          icon: AnimatedRotation(
            turns: _showAttachmentMenu ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.add,
              color: _showAttachmentMenu
                  ? ColorConstants.primaryColor
                  : Colors.grey[600],
            ),
          ),
        ),

        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onTap: _hideAttachmentMenu,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send/Voice button
        GestureDetector(
          onTap: _canSend ? _sendMessage : null,
          onLongPress: !_canSend ? _startVoiceRecording : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _canSend || widget.isLoading
                  ? ColorConstants.primaryColor
                  : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _canSend ? Icons.send : Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _recordingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _recordingAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recording voice message...',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: _stopVoiceRecording,
            icon: const Icon(
              Icons.stop,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Reply Templates Widget
class QuickReplyTemplates extends StatelessWidget {
  final Function(String) onReplySelected;
  final String conversationType; // 'rental', 'delivery', 'general'

  const QuickReplyTemplates({
    super.key,
    required this.onReplySelected,
    required this.conversationType,
  });

  @override
  Widget build(BuildContext context) {
    final templates = _getTemplatesForType(conversationType);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                template,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => onReplySelected(template),
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
            ),
          );
        },
      ),
    );
  }

  List<String> _getTemplatesForType(String type) {
    switch (type) {
      case 'rental':
        return [
          'Yes, that works for me',
          'When can I pick it up?',
          'Is it still available?',
          'Can we negotiate the price?',
          'Thank you!',
        ];
      case 'delivery':
        return [
          'On my way',
          'Arrived at pickup',
          'Package delivered',
          'Running 5 minutes late',
          'Call me when ready',
        ];
      default:
        return [
          'Hello',
          'Thank you',
          'Got it',
          'Will get back to you',
        ];
    }
  }
}

// Message Reactions Widget
class MessageReactions extends StatelessWidget {
  final String messageId;
  final Map<String, List<String>> reactions; // emoji -> list of user IDs
  final Function(String, String) onReactionToggle; // messageId, emoji

  const MessageReactions({
    super.key,
    required this.messageId,
    required this.reactions,
    required this.onReactionToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;
        final count = userIds.length;

        return GestureDetector(
          onTap: () => onReactionToggle(messageId, emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
