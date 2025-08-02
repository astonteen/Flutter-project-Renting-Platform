import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final List<String> typingUsers;
  final double height;
  final Color? backgroundColor;
  final Color? dotColor;

  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
    this.height = 50,
    this.backgroundColor,
    this.dotColor,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (widget.typingUsers.isNotEmpty) {
      _fadeController.forward();
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      _fadeController.forward();
      _animationController.repeat();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      _fadeController.reverse();
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getTypingText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTypingAnimation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: widget.typingUsers.length == 1
          ? Center(
              child: Text(
                widget.typingUsers.first.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryColor,
                ),
              ),
            )
          : Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.typingUsers.first.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+${widget.typingUsers.length - 1}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTypingAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedDot(0),
          const SizedBox(width: 4),
          _buildAnimatedDot(1),
          const SizedBox(width: 4),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = (_animation.value + (index * 0.2)) % 1.0;
        final scale =
            0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));
        final opacity =
            0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: (widget.dotColor ?? ColorConstants.primaryColor)
                  .withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  String _getTypingText() {
    if (widget.typingUsers.isEmpty) return '';

    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers.first} and ${widget.typingUsers.last} are typing...';
    } else {
      return '${widget.typingUsers.first} and ${widget.typingUsers.length - 1} others are typing...';
    }
  }
}

class TypingIndicatorBubble extends StatefulWidget {
  final Color? backgroundColor;
  final Color? dotColor;
  final double size;

  const TypingIndicatorBubble({
    super.key,
    this.backgroundColor,
    this.dotColor,
    this.size = 40,
  });

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 3),
            _buildDot(1),
            const SizedBox(width: 3),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = (_animation.value + (index * 0.2)) % 1.0;
        final scale =
            0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));
        final opacity =
            0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: (widget.dotColor ?? ColorConstants.primaryColor)
                    .withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class MessageTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final bool showAvatar;
  final double? avatarSize;

  const MessageTypingIndicator({
    super.key,
    required this.typingUsers,
    this.showAvatar = true,
    this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: CircleAvatar(
                radius: avatarSize ?? 16,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
                child: typingUsers.length == 1
                    ? Text(
                        typingUsers.first.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: (avatarSize ?? 16) * 0.6,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primary,
                        ),
                      )
                    : Icon(
                        Icons.people,
                        size: (avatarSize ?? 16) * 0.8,
                        color: ColorConstants.primary,
                      ),
              ),
            ),
          const TypingIndicatorBubble(),
        ],
      ),
    );
  }
}
