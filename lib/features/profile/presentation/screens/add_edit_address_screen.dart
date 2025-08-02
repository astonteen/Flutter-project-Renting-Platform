import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/widgets/custom_text_field.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';
import 'package:rent_ease/features/profile/presentation/bloc/saved_address_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:rent_ease/core/services/location_service.dart';
import 'package:rent_ease/core/widgets/google_places_autocomplete_field.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({super.key, this.addressId});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Focus nodes for proper focus management
  final _labelFocusNode = FocusNode();
  final _streetFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _stateFocusNode = FocusNode();
  final _postalCodeFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _instructionsFocusNode = FocusNode();

  bool _isDefault = false;
  bool _isLoading = false;
  SavedAddressModel? _existingAddress;

  @override
  void initState() {
    super.initState();
    _countryController.text = 'United States'; // Default country
    if (widget.addressId != null) {
      _loadExistingAddress();
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _instructionsController.dispose();

    _labelFocusNode.dispose();
    _streetFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _countryFocusNode.dispose();
    _instructionsFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadExistingAddress() async {
    setState(() => _isLoading = true);
    try {
      final repository = getIt<SavedAddressRepository>();
      final address = await repository.getAddressById(widget.addressId!);
      if (address != null) {
        setState(() {
          _existingAddress = address;
          _labelController.text = address.label;
          _streetController.text = address.addressLine1;
          _cityController.text = address.city;
          _stateController.text = address.state;
          _postalCodeController.text = address.postalCode;
          _countryController.text = address.country;
          _instructionsController.text = address.addressLine2 ?? '';
          _isDefault = address.isDefault;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error loading address';
        if (e is SavedAddressException) {
          errorMessage = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addressId != null;

    return BlocProvider(
      create: (context) => SavedAddressBloc(getIt<SavedAddressRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Address' : 'Add Address'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _isLoading
            ? const LoadingWidget()
            : BlocListener<SavedAddressBloc, SavedAddressState>(
                listener: (context, state) {
                  if (state is SavedAddressOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(true);
                  } else if (state is SavedAddressError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: _buildForm(context, isEditing),
              ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isEditing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Address Label'),
            const SizedBox(height: 8),
            Focus(
              child: CustomTextField(
                key: const Key('label_field'),
                controller: _labelController,
                focusNode: _labelFocusNode,
                hintText: 'e.g., Home, Work, Mom\'s House',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label for this address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Street Address'),
                TextButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Use Current Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.primaryColor,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Focus(
              child: _buildGooglePlacesField(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('City'),
                      const SizedBox(height: 8),
                      Focus(
                        child: CustomTextField(
                          key: const Key('city_field'),
                          controller: _cityController,
                          focusNode: _cityFocusNode,
                          hintText: 'Enter city',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('State'),
                      const SizedBox(height: 8),
                      Focus(
                        child: CustomTextField(
                          key: const Key('state_field'),
                          controller: _stateController,
                          focusNode: _stateFocusNode,
                          hintText: 'State',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Postal Code'),
                      const SizedBox(height: 8),
                      Focus(
                        child: CustomTextField(
                          key: const Key('postal_code_field'),
                          controller: _postalCodeController,
                          focusNode: _postalCodeFocusNode,
                          hintText: 'ZIP Code',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Country'),
                      const SizedBox(height: 8),
                      Focus(
                        child: CustomTextField(
                          key: const Key('country_field'),
                          controller: _countryController,
                          focusNode: _countryFocusNode,
                          hintText: 'Enter country',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Special Instructions (Optional)'),
            const SizedBox(height: 8),
            Focus(
              child: CustomTextField(
                key: const Key('instructions_field'),
                controller: _instructionsController,
                focusNode: _instructionsFocusNode,
                hintText: 'e.g., Ring doorbell, Leave at door, etc.',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text('Set as default address'),
              subtitle: const Text(
                  'This will be selected automatically for deliveries'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: ColorConstants.primaryColor,
            ),
            const SizedBox(height: 32),
            BlocBuilder<SavedAddressBloc, SavedAddressState>(
              builder: (context, state) {
                final isLoading = state is SavedAddressLoading;

                return SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: isEditing ? 'Update Address' : 'Save Address',
                    onPressed: isLoading
                        ? null
                        : () => _saveAddress(context, isEditing),
                    type: ButtonType.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildGooglePlacesField() {
    return Column(
      children: [
        GooglePlacesAutocompleteField(
          controller: _streetController,
          googleApiKey: LocationService.googleApiKey,
          hintText: 'Enter street address',
          prefixIcon: const Icon(Icons.location_on_outlined),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a street address';
            }
            return null;
          },
          onPlaceSelected: (address, prediction) {
            _handlePlaceSelection(prediction);
          },
        ),
        // Validation message
        if (_streetController.text.isEmpty &&
            _formKey.currentState?.validate() == false)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: const Text(
              'Please enter street address',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  void _handlePlaceSelection(Prediction prediction) async {
    if (prediction.placeId != null) {
      try {
        // Parse the address components using LocationService
        final locationService = LocationService();
        final addressComponents = locationService
            .parseGooglePlaceAddress(prediction.description ?? '');

        // Auto-fill the form fields
        setState(() {
          // Update street address with the full street from prediction
          if (addressComponents['street'] != null) {
            _streetController.text = addressComponents['street']!;
          }

          if (addressComponents['city'] != null) {
            _cityController.text = addressComponents['city']!;
          }
          if (addressComponents['state'] != null) {
            _stateController.text = addressComponents['state']!;
          }
          if (addressComponents['postalCode'] != null) {
            _postalCodeController.text = addressComponents['postalCode']!;
          }
          if (addressComponents['country'] != null) {
            _countryController.text = addressComponents['country']!;
          }
        });

        // Show success message if address is complete
        if (locationService.isAddressComplete(addressComponents)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address auto-filled successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error handling place selection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error auto-filling address. Please fill manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _useCurrentLocation() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Getting your location...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Get current location
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      // Get address from coordinates
      final address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address == null) {
        throw Exception('Unable to get address from location');
      }

      // Parse and fill address components
      final addressComponents =
          locationService.parseGooglePlaceAddress(address);

      setState(() {
        _streetController.text = address;
        if (addressComponents['city'] != null) {
          _cityController.text = addressComponents['city']!;
        }
        if (addressComponents['state'] != null) {
          _stateController.text = addressComponents['state']!;
        }
        if (addressComponents['postalCode'] != null) {
          _postalCodeController.text = addressComponents['postalCode']!;
        }
        if (addressComponents['country'] != null) {
          _countryController.text = addressComponents['country']!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location address filled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting current location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveAddress(BuildContext context, bool isEditing) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for street address
    if (_streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a street address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isEditing && _existingAddress != null) {
      final updatedAddress = _existingAddress!.copyWith(
        label: _labelController.text.trim(),
        addressLine1: _streetController.text.trim(),
        addressLine2: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        isDefault: _isDefault,
      );

      context.read<SavedAddressBloc>().add(
            UpdateSavedAddress(updatedAddress),
          );
    } else {
      final newAddress = SavedAddressModel(
        id: '', // Will be set by the database
        userId: '', // Will be set by the repository
        label: _labelController.text.trim(),
        addressLine1: _streetController.text.trim(),
        addressLine2: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        isDefault: _isDefault,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<SavedAddressBloc>().add(
            CreateSavedAddress(newAddress),
          );
    }
  }
}
