import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryColor,
              ),
              strokeWidth: 3.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorConstants.secondaryTextColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Enhanced Skeleton Loading Widgets
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -2, end: 2).animate(
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
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? ColorConstants.lightGrey;
    final highlightColor =
        widget.highlightColor ?? ColorConstants.veryLightGrey;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Item Card Skeleton
class ItemCardSkeleton extends StatelessWidget {
  const ItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.lightShadowColor,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: ColorConstants.lightGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: ColorConstants.lightGrey,
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Container(
                    height: 20,
                    width: 80,
                    color: ColorConstants.lightGrey,
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 60,
                        color: ColorConstants.lightGrey,
                      ),
                      const Spacer(),
                      Container(
                        height: 12,
                        width: 40,
                        color: ColorConstants.lightGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Message Bubble Skeleton
class MessageBubbleSkeleton extends StatelessWidget {
  final bool isMe;

  const MessageBubbleSkeleton({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 120,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 60,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Header Skeleton
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Container(
                height: 20,
                width: 120,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                    3,
                    (index) => Column(
                          children: [
                            Container(
                              height: 16,
                              width: 30,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 40,
                              color: Colors.grey[400],
                            ),
                          ],
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// List Loading with Skeleton
class ListLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) skeletonBuilder;

  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 5,
    required this.skeletonBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => skeletonBuilder(index),
    );
  }
}

// Smart Loading Messages
class SmartLoadingWidget extends StatefulWidget {
  final String context;
  final double size;

  const SmartLoadingWidget({
    super.key,
    required this.context,
    this.size = 50.0,
  });

  @override
  State<SmartLoadingWidget> createState() => _SmartLoadingWidgetState();
}

class _SmartLoadingWidgetState extends State<SmartLoadingWidget> {
  late String _currentMessage;
  late List<String> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _getMessagesForContext(widget.context);
    _currentMessage = _messages.first;
    _startMessageRotation();
  }

  List<String> _getMessagesForContext(String context) {
    switch (context) {
      case 'search':
        return [
          'Finding nearby items...',
          'Searching through listings...',
          'Filtering results...',
        ];
      case 'payment':
        return [
          'Processing payment...',
          'Verifying payment details...',
          'Confirming transaction...',
        ];
      case 'upload':
        return [
          'Uploading photos...',
          'Optimizing images...',
          'Finalizing upload...',
        ];
      case 'delivery':
        return [
          'Connecting to driver...',
          'Finding available drivers...',
          'Calculating delivery time...',
        ];
      case 'location':
        return [
          'Getting your location...',
          'Finding nearby items...',
          'Calculating distances...',
        ];
      default:
        return [
          'Loading...',
          'Please wait...',
          'Processing...',
        ];
    }
  }

  void _startMessageRotation() {
    if (_messages.length > 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            final currentIndex = _messages.indexOf(_currentMessage);
            final nextIndex = (currentIndex + 1) % _messages.length;
            _currentMessage = _messages[nextIndex];
          });
          _startMessageRotation();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryColor,
              ),
              strokeWidth: 3.0,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _currentMessage,
              key: ValueKey(_currentMessage),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Search Results Skeleton
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SkeletonLoader(
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced loading states for different scenarios
class PaymentProcessingWidget extends StatefulWidget {
  final String stage;
  final String paymentMethod;

  const PaymentProcessingWidget({
    super.key,
    required this.stage,
    required this.paymentMethod,
  });

  @override
  State<PaymentProcessingWidget> createState() =>
      _PaymentProcessingWidgetState();
}

class _PaymentProcessingWidgetState extends State<PaymentProcessingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _stageMessage {
    switch (widget.stage) {
      case 'validating':
        return 'Validating payment details...';
      case 'processing':
        return 'Processing ${widget.paymentMethod} payment...';
      case 'confirming':
        return 'Confirming booking...';
      case 'finalizing':
        return 'Finalizing transaction...';
      default:
        return 'Processing payment...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorConstants.primaryColor,
                    ),
                    strokeWidth: 4,
                    value: _animation.value,
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        _getPaymentIcon(),
                        size: 40,
                        color: ColorConstants.primaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _stageMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your payment securely',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressValue() {
    switch (widget.stage) {
      case 'validating':
        return 0.25;
      case 'processing':
        return 0.5;
      case 'confirming':
        return 0.75;
      case 'finalizing':
        return 1.0;
      default:
        return 0.0;
    }
  }

  IconData _getPaymentIcon() {
    switch (widget.paymentMethod) {
      case 'Credit Card':
        return Icons.credit_card;
      case 'PayPal':
        return Icons.account_balance_wallet;
      case 'Apple Pay':
        return Icons.phone_iphone;
      case 'Google Pay':
        return Icons.android;
      default:
        return Icons.payment;
    }
  }
}

// File Upload Progress Widget
class FileUploadProgressWidget extends StatefulWidget {
  final String fileName;
  final double progress;
  final String status;

  const FileUploadProgressWidget({
    super.key,
    required this.fileName,
    required this.progress,
    required this.status,
  });

  @override
  State<FileUploadProgressWidget> createState() =>
      _FileUploadProgressWidgetState();
}

class _FileUploadProgressWidgetState extends State<FileUploadProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.status,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getStatusColor()),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon() {
    if (widget.progress >= 1.0) {
      return Icons.check_circle;
    } else if (widget.status.toLowerCase().contains('error')) {
      return Icons.error;
    } else {
      return Icons.upload_file;
    }
  }

  Color _getStatusColor() {
    if (widget.progress >= 1.0) {
      return Colors.green;
    } else if (widget.status.toLowerCase().contains('error')) {
      return Colors.red;
    } else {
      return ColorConstants.primaryColor;
    }
  }
}

// Typing Indicator Widget
class TypingIndicatorWidget extends StatefulWidget {
  final String userName;

  const TypingIndicatorWidget({
    super.key,
    required this.userName,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} is typing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _animations[index],
                      builder: (context, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600]?.withValues(
                              alpha: 0.3 + (_animations[index].value * 0.7),
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Network Connectivity Loading Widget
class NetworkConnectivityWidget extends StatefulWidget {
  final bool isConnected;
  final VoidCallback? onRetry;

  const NetworkConnectivityWidget({
    super.key,
    required this.isConnected,
    this.onRetry,
  });

  @override
  State<NetworkConnectivityWidget> createState() =>
      _NetworkConnectivityWidgetState();
}

class _NetworkConnectivityWidgetState extends State<NetworkConnectivityWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (!widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NetworkConnectivityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange[100],
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.wifi_off,
                  color: Colors.orange[700],
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No internet connection',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Please check your connection and try again',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                ),
              ],
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: widget.onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Delivery Tracking Animation Widget
class DeliveryTrackingWidget extends StatefulWidget {
  final String stage;
  final String driverName;
  final String estimatedTime;

  const DeliveryTrackingWidget({
    super.key,
    required this.stage,
    required this.driverName,
    required this.estimatedTime,
  });

  @override
  State<DeliveryTrackingWidget> createState() => _DeliveryTrackingWidgetState();
}

class _DeliveryTrackingWidgetState extends State<DeliveryTrackingWidget>
    with TickerProviderStateMixin {
  late AnimationController _vehicleController;
  late AnimationController _pulseController;
  late Animation<double> _vehicleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _vehicleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _vehicleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vehicleController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _vehicleController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Driver Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    ColorConstants.primaryColor.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  color: ColorConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _getStageMessage(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ETA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    widget.estimatedTime,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.primaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Delivery Progress
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedBuilder(
                animation: _vehicleAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width *
                        0.8 *
                        _getProgressValue(),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: (MediaQuery.of(context).size.width *
                            0.8 *
                            _getProgressValue()) -
                        12,
                    top: -8,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: const Icon(
                        Icons.local_shipping,
                        color: ColorConstants.primaryColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stage Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStageIndicator('Pickup', _getStageIndex() >= 0),
              _buildStageIndicator('Transit', _getStageIndex() >= 1),
              _buildStageIndicator('Delivery', _getStageIndex() >= 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? ColorConstants.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isActive ? ColorConstants.primaryColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  String _getStageMessage() {
    switch (widget.stage) {
      case 'pickup':
        return 'Picking up your item';
      case 'transit':
        return 'On the way to you';
      case 'delivery':
        return 'Delivering now';
      case 'delivered':
        return 'Delivered successfully';
      default:
        return 'Processing...';
    }
  }

  int _getStageIndex() {
    switch (widget.stage) {
      case 'pickup':
        return 0;
      case 'transit':
        return 1;
      case 'delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  double _getProgressValue() {
    switch (widget.stage) {
      case 'pickup':
        return 0.33;
      case 'transit':
        return 0.66;
      case 'delivery':
        return 1.0;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }
}
