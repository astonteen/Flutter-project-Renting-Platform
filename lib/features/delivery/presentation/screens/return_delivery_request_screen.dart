import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/location_service.dart';
import 'package:rent_ease/core/widgets/google_places_autocomplete_field.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';

class ReturnDeliveryRequestScreen extends StatefulWidget {
  final String originalDeliveryId;
  final String itemName;

  const ReturnDeliveryRequestScreen({
    super.key,
    required this.originalDeliveryId,
    required this.itemName,
  });

  @override
  State<ReturnDeliveryRequestScreen> createState() =>
      _ReturnDeliveryRequestScreenState();
}

class _ReturnDeliveryRequestScreenState
    extends State<ReturnDeliveryRequestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _returnAddressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _contactNumberController = TextEditingController();

  PlaceDetails? _selectedPlace;

  DateTime? _preferredReturnDate;
  bool _isProcessing = false;
  String _selectedTimeSlot = 'morning';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeForm();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    // Set default return date to tomorrow
    _preferredReturnDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _returnAddressController.dispose();
    _specialInstructionsController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Schedule Return Pickup',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try to pop first, if no route to pop, go to track orders
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/track-orders');
            }
          },
        ),
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySuccess) {
            _showSuccessMessage(state.message);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) context.pop();
            });
          } else if (state is DeliveryError) {
            _showErrorMessage(state.message);
            setState(() => _isProcessing = false);
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildReturnDetailsForm(),
                    const SizedBox(height: 20),
                    _buildSchedulingSection(),
                    const SizedBox(height: 20),
                    _buildAdditionalOptionsSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal,
            Colors.teal.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_return,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Return Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Schedule a return pickup for "${widget.itemName}". We\'ll arrange for a driver to collect the item from you.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnDetailsForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Return Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GooglePlacesAutocompleteField(
              controller: _returnAddressController,
              googleApiKey: LocationService.googleApiKey,
              labelText: 'Pickup Address',
              hintText: 'Where should we collect the item?',
              prefixIcon: const Icon(Icons.location_on),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the pickup address';
                }
                return null;
              },
              onPlaceSelected: (address, prediction) {
                // Store the selected place details
                _selectedPlace = PlaceDetails(
                  address: address,
                  latitude: double.tryParse(prediction.lat ?? ''),
                  longitude: double.tryParse(prediction.lng ?? ''),
                  placeId: prediction.placeId,
                  formattedAddress: prediction.description,
                );
                debugPrint('📍 Selected place: ${_selectedPlace.toString()}');
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNumberController,
              decoration: InputDecoration(
                labelText: 'Your Contact Number',
                hintText: 'Phone number for driver to reach you',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your contact number';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Pickup Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildTimeSlotSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: ColorConstants.primaryColor,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pickup Date',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _preferredReturnDate != null
                      ? _formatDate(_preferredReturnDate!)
                      : 'Select date',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    final timeSlots = [
      {'value': 'morning', 'label': 'Morning', 'time': '9:00 AM - 12:00 PM'},
      {'value': 'afternoon', 'label': 'Afternoon', 'time': '1:00 PM - 5:00 PM'},
      {'value': 'evening', 'label': 'Evening', 'time': '6:00 PM - 8:00 PM'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Slot',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...timeSlots.map((slot) => _buildTimeSlotOption(slot)).toList(),
      ],
    );
  }

  Widget _buildTimeSlotOption(Map<String, String> slot) {
    final isSelected = _selectedTimeSlot == slot['value'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTimeSlot = slot['value']!;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConstants.primaryColor.withValues(alpha: 0.1)
                : Colors.grey[50],
            border: Border.all(
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? ColorConstants.primaryColor : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot['label']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ColorConstants.primaryColor
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      slot['time']!,
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
        ),
      ),
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialInstructionsController,
              decoration: InputDecoration(
                labelText: 'Special Instructions (Optional)',
                hintText: 'Any special pickup instructions for the driver?',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How it works:',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Provide your contact number so the driver can reach you\n'
                    '• The item owner will be notified for approval\n'
                    '• Auto-approved in 2 hours if not reviewed\n'
                    '• Driver will contact you before arrival',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _submitReturnRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_return, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Request Return Pickup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _preferredReturnDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ColorConstants.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _preferredReturnDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _submitReturnRequest() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      // Calculate scheduled time based on selected slot
      DateTime scheduledTime = _preferredReturnDate!;
      switch (_selectedTimeSlot) {
        case 'morning':
          scheduledTime = DateTime(
            _preferredReturnDate!.year,
            _preferredReturnDate!.month,
            _preferredReturnDate!.day,
            10, 0, // 10:00 AM
          );
          break;
        case 'afternoon':
          scheduledTime = DateTime(
            _preferredReturnDate!.year,
            _preferredReturnDate!.month,
            _preferredReturnDate!.day,
            14, 0, // 2:00 PM
          );
          break;
        case 'evening':
          scheduledTime = DateTime(
            _preferredReturnDate!.year,
            _preferredReturnDate!.month,
            _preferredReturnDate!.day,
            18, 0, // 6:00 PM
          );
          break;
      }

      context.read<DeliveryBloc>().add(
            RequestReturnDelivery(
              originalDeliveryId: widget.originalDeliveryId,
              returnAddress: _returnAddressController.text,
              contactNumber: _contactNumberController.text,
              scheduledTime: scheduledTime,
              specialInstructions: _specialInstructionsController.text,
            ),
          );
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
