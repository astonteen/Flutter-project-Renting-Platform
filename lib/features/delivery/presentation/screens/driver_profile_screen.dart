import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _locationController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.bike;
  bool _isEditing = false;
  String? _currentUserId;
  DriverProfileModel? _currentProfile;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      context.read<DeliveryBloc>().add(LoadDriverProfile(user.id));
    }
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _bankAccountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Driver Profile' : 'Driver Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: NavigationHelper.createHamburgerMenuBackButton(context),
        actions: [
          if (_currentProfile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
                _populateFields();
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          _handleStateChanges(context, state);
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const LoadingWidget();
          }

          if (state is DeliveryActionLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing driver profile...'),
                ],
              ),
            );
          }

          if (state is DeliveryError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () {
                if (_currentUserId != null) {
                  context
                      .read<DeliveryBloc>()
                      .add(LoadDriverProfile(_currentUserId!));
                }
              },
            );
          }

          if (state is DriverProfileLoaded) {
            _currentProfile = state.profile;
            if (!_isEditing) {
              return _buildProfileView();
            }
          }

          if (_currentProfile == null && !_isEditing) {
            return _buildCreateProfilePrompt();
          }

          return _buildProfileForm();
        },
      ),
    );
  }

  Widget _buildProfileView() {
    if (_currentProfile == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 8,
            shadowColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.primaryColor,
                    ColorConstants.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currentProfile!.availabilityStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _currentProfile!.isAvailable,
                        onChanged: _toggleAvailability,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Deliveries',
                          '${_currentProfile!.totalDeliveries}',
                          Icons.local_shipping,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Average Rating',
                          _currentProfile!.formattedAverageRating,
                          Icons.star,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Earnings',
                          _currentProfile!.formattedTotalEarnings,
                          Icons.attach_money,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Vehicle Information
          _buildSectionCard(
            'Vehicle Information',
            Icons.directions_car,
            [
              _buildInfoRow('Type', _currentProfile!.vehicleTypeDisplayText),
              _buildInfoRow(
                  'Model', _currentProfile!.vehicleModel ?? 'Not specified'),
              _buildInfoRow('License Plate',
                  _currentProfile!.licensePlate ?? 'Not specified'),
            ],
          ),

          const SizedBox(height: 16),

          // Driver Information
          _buildSectionCard(
            'Driver Information',
            Icons.person,
            [
              _buildInfoRow('Current Location',
                  _currentProfile!.currentLocation ?? 'Not specified'),
              _buildInfoRow(
                  'Bank Account',
                  _currentProfile!.bankAccountNumber != null
                      ? '**** ${_currentProfile!.bankAccountNumber!.substring(_currentProfile!.bankAccountNumber!.length - 4)}'
                      : 'Not configured'),
              _buildInfoRow(
                  'Status', _currentProfile!.isActive ? 'Active' : 'Inactive'),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                    _populateFields();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // Navigate to earnings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Earnings screen coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Earnings'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProfilePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 64,
                color: ColorConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Become a Driver',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Join our delivery network and start earning money by delivering items in your area.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Driver Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: ColorConstants.primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Vehicle Type Dropdown
                    DropdownButtonFormField<VehicleType>(
                      value: _selectedVehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                      ),
                      items: VehicleType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getVehicleTypeDisplayText(type)),
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
                    TextFormField(
                      controller: _vehicleModelController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Model (Optional)',
                        hintText: 'e.g., Honda Civic 2020',
                        prefixIcon: Icon(Icons.car_rental),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // License Plate
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate',
                        hintText: 'e.g., ABC-123',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your license plate';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: ColorConstants.primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Payment Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bank Account
                    TextFormField(
                      controller: _bankAccountController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Account Number (Optional)',
                        hintText: 'For earnings payment',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),

                    const SizedBox(height: 16),

                    // Current Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Current Location (Optional)',
                        hintText: 'e.g., Downtown Springfield',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentProfile == null
                      ? 'Create Driver Profile'
                      : 'Update Profile',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ColorConstants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getVehicleTypeDisplayText(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.bike:
        return 'Bicycle';
    }
  }

  void _populateFields() {
    if (_currentProfile != null) {
      _selectedVehicleType = _currentProfile!.vehicleType;
      _vehicleModelController.text = _currentProfile!.vehicleModel ?? '';
      _licensePlateController.text = _currentProfile!.licensePlate ?? '';
      _bankAccountController.text = _currentProfile!.bankAccountNumber ?? '';
      _locationController.text = _currentProfile!.currentLocation ?? '';
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _clearForm();
  }

  void _clearForm() {
    _vehicleModelController.clear();
    _licensePlateController.clear();
    _bankAccountController.clear();
    _locationController.clear();
    _selectedVehicleType = VehicleType.bike;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _currentUserId != null) {
      final profileData = {
        'vehicle_type': _selectedVehicleType.name,
        'vehicle_model': _vehicleModelController.text.trim().isEmpty
            ? null
            : _vehicleModelController.text.trim(),
        'license_plate': _licensePlateController.text.trim().isEmpty
            ? null
            : _licensePlateController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim().isEmpty
            ? null
            : _bankAccountController.text.trim(),
        'current_location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'is_active': true,
        'is_available': true,
      };

      if (_currentProfile == null) {
        context.read<DeliveryBloc>().add(
              CreateDriverProfile(_currentUserId!, profileData),
            );
      } else {
        context.read<DeliveryBloc>().add(
              UpdateDriverProfile(_currentUserId!, profileData),
            );
      }
    }
  }

  void _toggleAvailability(bool isAvailable) {
    if (_currentUserId != null) {
      context.read<DeliveryBloc>().add(
            UpdateDriverAvailability(_currentUserId!, isAvailable),
          );
    }
  }

  void _handleStateChanges(BuildContext context, DeliveryState state) {
    if (state is DriverProfileCreated) {
      _currentProfile = state.profile;
      setState(() {
        _isEditing = false;
      });
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (state is DriverProfileUpdated) {
      _currentProfile = state.profile;
      setState(() {
        _isEditing = false;
      });
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (state is DriverAvailabilityUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.isAvailable
                ? 'You are now available for deliveries'
                : 'You are now offline',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (state is DeliveryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
