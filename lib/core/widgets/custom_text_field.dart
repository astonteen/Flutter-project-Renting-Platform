import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final int? maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(
            borderRadius: BorderRadiusConstants.radiusSmall),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadiusConstants.radiusSmall,
          borderSide: BorderSide(color: ColorConstants.lightGrey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadiusConstants.radiusSmall,
          borderSide: BorderSide(color: ColorConstants.primaryColor),
        ),
        contentPadding: SpacingConstants.paddingMD,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
