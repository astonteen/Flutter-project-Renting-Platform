import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

enum ButtonType { primary, secondary, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isFullWidth = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton();
      case ButtonType.secondary:
        return _buildSecondaryButton();
      case ButtonType.text:
        return _buildTextButton();
    }
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryColor,
          foregroundColor: ColorConstants.white,
          padding: const EdgeInsets.symmetric(vertical: SpacingConstants.md),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.radiusXLarge,
          ),
          elevation: ElevationConstants.low,
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primaryColor,
          side: const BorderSide(color: ColorConstants.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: SpacingConstants.md),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.radiusXLarge,
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.white),
        ),
      );
    } else if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: SpacingConstants.sm),
          Text(text)
        ],
      );
    } else {
      return Text(text);
    }
  }
}
