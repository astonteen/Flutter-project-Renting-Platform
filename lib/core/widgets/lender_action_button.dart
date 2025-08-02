import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

enum LenderActionButtonType {
  approve,
  decline,
  save,
  cancel,
  primary,
  secondary,
}

class LenderActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final LenderActionButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const LenderActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.type,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final buttonConfig = _getButtonConfig();

    if (type == LenderActionButtonType.decline ||
        type == LenderActionButtonType.cancel ||
        type == LenderActionButtonType.secondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonConfig.textColor,
            side: BorderSide(color: buttonConfig.borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _buildButtonContent(buttonConfig),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonConfig.backgroundColor,
          foregroundColor: buttonConfig.textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: buttonConfig.backgroundColor.withAlpha(75),
        ),
        child: _buildButtonContent(buttonConfig),
      ),
    );
  }

  Widget _buildButtonContent(_ButtonConfig config) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: config.textColor,
      ),
    );
  }

  _ButtonConfig _getButtonConfig() {
    switch (type) {
      case LenderActionButtonType.approve:
        return _ButtonConfig(
          backgroundColor: Colors.green[600]!,
          textColor: Colors.white,
          borderColor: Colors.green[600]!,
        );
      case LenderActionButtonType.decline:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: Colors.red[600]!,
          borderColor: Colors.red[300]!,
        );
      case LenderActionButtonType.save:
        return _ButtonConfig(
          backgroundColor: ColorConstants.primaryColor,
          textColor: Colors.white,
          borderColor: ColorConstants.primaryColor,
        );
      case LenderActionButtonType.cancel:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: ColorConstants.grey,
          borderColor: ColorConstants.lightGrey,
        );
      case LenderActionButtonType.primary:
        return _ButtonConfig(
          backgroundColor: ColorConstants.primaryColor,
          textColor: Colors.white,
          borderColor: ColorConstants.primaryColor,
        );
      case LenderActionButtonType.secondary:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: ColorConstants.primaryColor,
          borderColor: ColorConstants.primaryColor,
        );
    }
  }
}

class _ButtonConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  _ButtonConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
