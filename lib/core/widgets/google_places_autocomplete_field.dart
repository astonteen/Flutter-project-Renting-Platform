import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class GooglePlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String address, Prediction prediction)? onPlaceSelected;
  final String googleApiKey;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;

  const GooglePlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.googleApiKey,
    this.labelText,
    this.hintText,
    this.validator,
    this.onPlaceSelected,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
  });

  @override
  State<GooglePlacesAutocompleteField> createState() =>
      _GooglePlacesAutocompleteFieldState();
}

class _GooglePlacesAutocompleteFieldState
    extends State<GooglePlacesAutocompleteField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: widget.controller,
      googleAPIKey: widget.googleApiKey,
      focusNode: _focusNode,
      debounceTime: 800, // Wait 800ms after user stops typing
      countries: const ["MY"], // Restrict to Malaysia, adjust as needed
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) {
        // This callback is triggered when user selects a place
        if (widget.onPlaceSelected != null) {
          widget.onPlaceSelected!(prediction.description ?? '', prediction);
        }
      },
      itemClick: (Prediction prediction) {
        widget.controller.text = prediction.description ?? '';
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description?.length ?? 0),
        );
        _focusNode.unfocus();
      },
      seperatedBuilder: const Divider(height: 1, color: Colors.grey),
      containerHorizontalPadding: 0,

      // TextField styling
      inputDecoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        enabled: widget.enabled,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
        errorStyle: const TextStyle(fontSize: 12),
      ),

      // Dropdown list styling
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.structuredFormatting?.mainText ??
                          prediction.description ??
                          '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (prediction.structuredFormatting?.secondaryText !=
                        null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prediction.structuredFormatting!.secondaryText!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },

      // Validation
      validator: widget.validator != null
          ? (value, context) => widget.validator!(value)
          : null,
    );
  }
}

class PlaceDetails {
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? formattedAddress;

  PlaceDetails({
    required this.address,
    this.latitude,
    this.longitude,
    this.placeId,
    this.formattedAddress,
  });

  @override
  String toString() {
    return 'PlaceDetails(address: $address, lat: $latitude, lng: $longitude)';
  }
}
