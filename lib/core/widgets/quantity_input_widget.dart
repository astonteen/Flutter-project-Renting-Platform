import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class QuantityInputWidget extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String label;
  final String? helperText;
  final bool isRequired;
  final ValueChanged<int> onChanged;

  const QuantityInputWidget({
    super.key,
    this.initialValue = 1,
    this.minValue = 1,
    this.maxValue = 999,
    this.label = 'Quantity',
    this.helperText,
    this.isRequired = true,
    required this.onChanged,
  });

  @override
  State<QuantityInputWidget> createState() => _QuantityInputWidgetState();
}

class _QuantityInputWidgetState extends State<QuantityInputWidget> {
  late TextEditingController _controller;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    if (_currentValue < widget.maxValue) {
      setState(() {
        _currentValue++;
        _controller.text = _currentValue.toString();
      });
      widget.onChanged(_currentValue);
    }
  }

  void _decrement() {
    if (_currentValue > widget.minValue) {
      setState(() {
        _currentValue--;
        _controller.text = _currentValue.toString();
      });
      widget.onChanged(_currentValue);
    }
  }

  void _onTextChanged(String value) {
    final parsedValue = int.tryParse(value);
    if (parsedValue != null &&
        parsedValue >= widget.minValue &&
        parsedValue <= widget.maxValue) {
      setState(() {
        _currentValue = parsedValue;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

        // Quantity Input Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Decrement Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _currentValue > widget.minValue ? _decrement : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: _currentValue > widget.minValue
                          ? ColorConstants.primaryColor
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Text Input
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '1',
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
              ),

              // Increment Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _currentValue < widget.maxValue ? _increment : null,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: _currentValue < widget.maxValue
                          ? ColorConstants.primaryColor
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Helper Text
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),

        // Range Info
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Range: ${widget.minValue} - ${widget.maxValue}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }
}
