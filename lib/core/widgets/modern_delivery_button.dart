import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

enum ModernButtonType { primary, secondary }

class ModernDeliveryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final bool isLoading;
  final double? width;
  final double height;

  const ModernDeliveryButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  State<ModernDeliveryButton> createState() => _ModernDeliveryButtonState();
}

class _ModernDeliveryButtonState extends State<ModernDeliveryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _animationController.forward();
  }

  void _handleTapUp() {
    _animationController.reverse();
  }

  Color get _primaryColor {
    return widget.type == ModernButtonType.primary
        ? ColorConstants.primaryColor
        : Colors.transparent;
  }

  Color get _textColor {
    return widget.type == ModernButtonType.primary
        ? Colors.white
        : ColorConstants.primaryColor;
  }

  Color get _iconBackgroundColor {
    return widget.type == ModernButtonType.primary
        ? Colors.white.withValues(alpha: 0.2)
        : ColorConstants.primaryColor.withValues(alpha: 0.15);
  }

  BorderSide? get _borderSide {
    return widget.type == ModernButtonType.secondary
        ? BorderSide(
            color: ColorConstants.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          )
        : null;
  }

  Color get _backgroundColor {
    if (widget.type == ModernButtonType.primary) {
      return _primaryColor;
    }
    return _isHovered
        ? ColorConstants.primaryColor.withValues(alpha: 0.12)
        : ColorConstants.primaryColor.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: () => _handleTapUp(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            width: widget.width,
            child: widget.type == ModernButtonType.primary
                ? _buildPrimaryButton()
                : _buildSecondaryButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textColor,
        side: _borderSide,
        backgroundColor: _backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        disabledForegroundColor: Colors.grey[600],
        disabledBackgroundColor: Colors.grey[100],
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _iconBackgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.type == ModernButtonType.primary
                ? Colors.white
                : ColorConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.5,
            color: _textColor,
          ),
        ),
      ],
    );
  }
}
