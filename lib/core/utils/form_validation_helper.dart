import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rent_ease/core/utils/validators.dart';

class FormValidationHelper {
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  static void setupRealTimeValidation({
    required TextEditingController controller,
    required Function(ValidationResult) onValidationChanged,
    required String? Function(String?) validator,
    bool immediate = false,
  }) {
    Timer? debounceTimer;

    controller.addListener(() {
      debounceTimer?.cancel();

      if (immediate || controller.text.isNotEmpty) {
        debounceTimer = Timer(_debounceDelay, () {
          final result = _validateWithResult(controller.text, validator);
          onValidationChanged(result);
        });
      }
    });
  }

  static ValidationResult _validateWithResult(
      String value, String? Function(String?) validator) {
    try {
      final error = validator(value);
      if (error == null) {
        return ValidationResult(isValid: true, message: 'Valid');
      } else {
        return ValidationResult(isValid: false, message: error);
      }
    } catch (e) {
      return ValidationResult(
          isValid: false, message: 'Validation error occurred');
    }
  }

  static Widget buildValidationMessage(ValidationResult result) {
    if (result.isValid || result.message == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration enhanceInputDecoration({
    required InputDecoration decoration,
    required ValidationResult validationResult,
    bool showValidationIcon = true,
  }) {
    Color? borderColor;
    Widget? suffixIcon = decoration.suffixIcon;

    if (!validationResult.isValid) {
      borderColor = Colors.red;

      if (showValidationIcon) {
        suffixIcon = const Icon(
          Icons.error,
          color: Colors.red,
          size: 20,
        );
      }
    } else if (validationResult.message != null &&
        validationResult.message!.isNotEmpty) {
      borderColor = Colors.green;

      if (showValidationIcon) {
        suffixIcon = const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
      }
    }

    return decoration.copyWith(
      suffixIcon: suffixIcon,
      border: decoration.border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: borderColor ?? Colors.grey[300]!,
            ),
          ),
      enabledBorder: decoration.enabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: borderColor ?? Colors.grey[300]!,
            ),
          ),
      focusedBorder: decoration.focusedBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: borderColor ?? Colors.blue,
              width: 2,
            ),
          ),
      errorBorder: decoration.errorBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
    );
  }
}

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool showValidationIcon;
  final bool showValidationMessage;
  final bool validateOnChange;
  final bool validateOnFocus;
  final List<String>? suggestions;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.validator,
    required this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.showValidationIcon = true,
    this.showValidationMessage = true,
    this.validateOnChange = true,
    this.validateOnFocus = false,
    this.suggestions,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  ValidationResult _validationResult =
      ValidationResult(isValid: true, message: null);
  bool _hasBeenFocused = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();

    if (widget.validateOnChange) {
      FormValidationHelper.setupRealTimeValidation(
        controller: widget.controller,
        onValidationChanged: (result) {
          if (mounted) {
            setState(() {
              _validationResult = result;
            });
          }
        },
        validator: widget.validator,
        immediate: widget.validateOnFocus,
      );
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _hasBeenFocused = true;
        if (widget.suggestions != null && widget.suggestions!.isNotEmpty) {
          _showSuggestions();
        }
      } else {
        _hideSuggestions();
        if (widget.validateOnFocus && _hasBeenFocused) {
          _validateField();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  void _validateField() {
    final result = FormValidationHelper._validateWithResult(
      widget.controller.text,
      widget.validator,
    );

    if (mounted) {
      setState(() {
        _validationResult = result;
      });
    }
  }

  void _showSuggestions() {
    if (widget.suggestions == null || widget.suggestions!.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.suggestions!.length,
                itemBuilder: (context, index) {
                  final suggestion = widget.suggestions![index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    onTap: () {
                      widget.controller.text = suggestion;
                      widget.onChanged?.call(suggestion);
                      _hideSuggestions();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: FormValidationHelper.enhanceInputDecoration(
              decoration: widget.decoration,
              validationResult: _validationResult,
              showValidationIcon: widget.showValidationIcon,
            ),
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            onTap: widget.onTap,
            onChanged: (value) {
              widget.onChanged?.call(value);
              if (widget.suggestions != null &&
                  widget.suggestions!.isNotEmpty) {
                if (value.isNotEmpty && _focusNode.hasFocus) {
                  _showSuggestions();
                } else {
                  _hideSuggestions();
                }
              }
            },
            onSubmitted: widget.onSubmitted,
          ),
        ),
        if (widget.showValidationMessage)
          FormValidationHelper.buildValidationMessage(_validationResult),
      ],
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showText;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final result = Validators.validatePasswordRealTime(password);
    final strength = result.strength ?? PasswordStrength.weak;
    final strengthColor = _getStrengthColor(strength);
    final strengthValue = _getStrengthValue(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  color:
                      index < strengthValue ? strengthColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (showText && password.isNotEmpty && result.message != null) ...[
          const SizedBox(height: 4),
          Text(
            result.message!,
            style: TextStyle(
              fontSize: 12,
              color: strengthColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  int _getStrengthValue(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.good:
        return 3;
      case PasswordStrength.strong:
        return 4;
    }
  }
}
