import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/delivery_job_model.dart';
import '../../../../core/services/role_switching_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/di/service_locator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/role_switching_loading_screen.dart';
import '../bloc/delivery_bloc.dart';
import '../../../../core/services/supabase_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _bankAccountController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.currentUser?.id;
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  String _getVehicleTypeDisplayText(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return 'Bicycle';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
    }
  }

  IconData _getVehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return Icons.pedal_bike;
      case VehicleType.motorcycle:
        return Icons.motorcycle;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.van:
        return Icons.airport_shuttle;
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Welcome to the Team!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Content
              const Text(
                'Congratulations! You have successfully become a driver. You can now start accepting delivery jobs and earning money.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Now show the loading screen with car animation
                    showRoleSwitchingLoadingScreen(
                      context,
                      'driver',
                      onComplete: () {
                        // Navigation will be handled by the loading screen
                        // It will automatically navigate to enhanced driver dashboard
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Continue to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create driver profile data for the BLoC
      final profileData = {
        'vehicle_type': _selectedVehicleType.name,
        'vehicle_model': _vehicleModelController.text.trim(),
        'license_plate': _licensePlateController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'is_active': true,
        'is_available': true, // Driver starts as available
      };

      // Use the existing BLoC to create driver profile
      context.read<DeliveryBloc>().add(
            CreateDriverProfile(_currentUserId!, profileData),
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processDriverRegistration() async {
    try {
      // Driver profile has been created successfully
      // Now add the driver role to the user's profile
      final roleSwitchingService = getIt<RoleSwitchingService>();
      final success = await roleSwitchingService.addRole('driver');

      if (success) {
        // Role added successfully, show success dialog first
        await _showSuccessDialog();
      } else {
        // Failed to add role, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add driver role. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error adding role, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding driver role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DriverProfileCreated) {
          setState(() {
            _isLoading = false;
          });

          // Add driver role to user profile and show loading screen
          _processDriverRegistration();
        } else if (state is DeliveryError) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: ColorConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Become a Driver',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: ColorConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.primaryColor,
                        ColorConstants.primaryColor.withValues(alpha: 0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Join Our Delivery Team',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Provide your vehicle and payment details to start earning as a delivery driver',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Vehicle Information Section
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Type Dropdown
                DropdownButtonFormField<VehicleType>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(_getVehicleTypeIcon(_selectedVehicleType)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: VehicleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getVehicleTypeIcon(type), size: 20),
                          const SizedBox(width: 12),
                          Text(_getVehicleTypeDisplayText(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedVehicleType = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a vehicle type';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Vehicle Model
                CustomTextField(
                  controller: _vehicleModelController,
                  labelText: 'Vehicle Model',
                  hintText: 'e.g., Honda Civic, Yamaha MT-07',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your vehicle model';
                    }
                    if (value.trim().length < 2) {
                      return 'Vehicle model must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // License Plate
                CustomTextField(
                  controller: _licensePlateController,
                  labelText: 'License Plate Number',
                  hintText: 'e.g., ABC-1234',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your license plate number';
                    }
                    if (value.trim().length < 3) {
                      return 'Please enter a valid license plate number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Payment Information Section
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Bank Account
                CustomTextField(
                  controller: _bankAccountController,
                  labelText: 'Bank Account Number',
                  hintText: 'Enter your bank account number',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your bank account number';
                    }
                    if (value.trim().length < 8) {
                      return 'Please enter a valid bank account number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Terms and Conditions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Important Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• You must have a valid driver\'s license\n'
                        '• Vehicle insurance is required\n'
                        '• Background check will be conducted\n'
                        '• Earnings are subject to local tax regulations',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Complete Registration',
                    onPressed: _isLoading ? null : _submitRegistration,
                    isLoading: _isLoading,
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.go('/profile');
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
