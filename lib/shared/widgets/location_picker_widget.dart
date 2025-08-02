import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/location_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialLocation;
  final String? hintText;
  final bool enabled;
  final Function(String address, double? latitude, double? longitude)?
      onLocationSelected;
  final VoidCallback? onCurrentLocationPressed;

  const LocationPickerWidget({
    super.key,
    this.controller,
    this.initialLocation,
    this.hintText = 'Enter location',
    this.enabled = true,
    this.onLocationSelected,
    this.onCurrentLocationPressed,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final LocationService _locationService = LocationService();
  bool _isLoadingCurrentLocation = false;
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    if (widget.initialLocation != null) {
      _internalController.text = widget.initialLocation!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google Places Autocomplete Field
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _internalController,
            googleAPIKey: LocationService.googleApiKey,
            inputDecoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_internalController.text.isNotEmpty && widget.enabled)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        _internalController.clear();
                        if (widget.onLocationSelected != null) {
                          widget.onLocationSelected!('', null, null);
                        }
                      },
                    ),
                  IconButton(
                    icon: _isLoadingCurrentLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorConstants.primaryColor,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.my_location,
                            color: ColorConstants.primaryColor,
                            size: 20,
                          ),
                    onPressed: widget.enabled ? _getCurrentLocation : null,
                    tooltip: 'Use current location',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorConstants.primaryColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: widget.enabled ? Colors.white : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            debounceTime: 600,
            countries: const [], // Empty means all countries
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              _onPlaceSelected(prediction);
            },
            itemClick: (Prediction prediction) {
              _internalController.text = prediction.description ?? '';
              _internalController.selection = TextSelection.fromPosition(
                TextPosition(offset: prediction.description?.length ?? 0),
              );
            },
            seperatedBuilder: const Divider(
              height: 1,
              color: Colors.grey,
            ),
            containerHorizontalPadding: 0,
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: const EdgeInsets.all(16),
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
                            prediction.structuredFormatting?.mainText ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (prediction.structuredFormatting?.secondaryText !=
                              null)
                            Text(
                              prediction.structuredFormatting!.secondaryText!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onPlaceSelected(Prediction prediction) {
    if (widget.onLocationSelected != null &&
        prediction.lat != null &&
        prediction.lng != null) {
      widget.onLocationSelected!(
        prediction.description ?? '',
        double.tryParse(prediction.lat!),
        double.tryParse(prediction.lng!),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!widget.enabled) return;

    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Check permissions first
      bool hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        bool granted = await _locationService.requestLocationPermission();
        if (!granted) {
          _showPermissionDialog();
          return;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Get current location
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        // Get address from coordinates
        String? address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null) {
          _internalController.text = address;
          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(
              address,
              position.latitude,
              position.longitude,
            );
          }
          if (widget.onCurrentLocationPressed != null) {
            widget.onCurrentLocationPressed!();
          }
        } else {
          _showErrorSnackBar('Unable to get current location');
        }
      } else {
        _showErrorSnackBar('Unable to get current location');
      }
    } catch (e) {
      _showErrorSnackBar('Error getting current location: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to get your current location. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _locationService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _locationService.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }
}
