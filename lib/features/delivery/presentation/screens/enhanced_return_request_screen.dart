import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';

class EnhancedReturnRequestScreen extends StatefulWidget {
  final DeliveryJobModel originalDelivery;

  const EnhancedReturnRequestScreen({
    super.key,
    required this.originalDelivery,
  });

  @override
  State<EnhancedReturnRequestScreen> createState() =>
      _EnhancedReturnRequestScreenState();
}

class _EnhancedReturnRequestScreenState
    extends State<EnhancedReturnRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _returnAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _returnReasonController = TextEditingController();

  DateTime? _preferredReturnDate;
  String _selectedTimeSlot = 'morning';
  bool _isProcessing = false;

  final List<String> _returnReasons = [
    'Rental period ended',
    'Item not as described',
    'No longer needed',
    'Found an alternative',
    'Quality issues',
    'Other',
  ];

  String _selectedReason = 'Rental period ended';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Pre-fill the return address with delivery address (where item currently is)
    _returnAddressController.text = widget.originalDelivery.deliveryAddress;

    // Set default return date to tomorrow
    _preferredReturnDate = DateTime.now().add(const Duration(days: 1));

    // Pre-fill contact number if available
    _contactNumberController.text = widget.originalDelivery.customerPhone ?? '';
  }

  @override
  void dispose() {
    _returnAddressController.dispose();
    _contactNumberController.dispose();
    _specialInstructionsController.dispose();
    _returnReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Request Return Pickup',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySuccess) {
            _showSuccessDialog();
          } else if (state is DeliveryError) {
            _showErrorMessage(state.message);
            setState(() => _isProcessing = false);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemHeader(),
                      const SizedBox(height: 24),
                      _buildReturnReasonSection(),
                      const SizedBox(height: 24),
                      _buildAddressSection(),
                      const SizedBox(height: 24),
                      _buildSchedulingSection(),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 24),
                      _buildSpecialInstructionsSection(),
                      const SizedBox(height: 24),
                      _buildCostSummary(),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: ColorConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.originalDelivery.itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${widget.originalDelivery.id.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnReasonSection() {
    return _buildSection(
      title: 'Return Reason',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedReason,
            decoration: InputDecoration(
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
                borderSide:
                    const BorderSide(color: ColorConstants.primaryColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _returnReasons.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(reason),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedReason = value!;
              });
            },
          ),
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _returnReasonController,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
              validator: (value) {
                if (_selectedReason == 'Other' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please specify the reason for return';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'Pickup Address',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The driver will pick up from where the item was delivered',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _returnAddressController,
            decoration: InputDecoration(
              labelText: 'Pickup Address',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the pickup address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return _buildSection(
      title: 'Preferred Pickup Time',
      child: Column(
        children: [
          // Date picker
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: ColorConstants.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _preferredReturnDate != null
                          ? _formatDate(_preferredReturnDate!)
                          : 'Select date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Time slot selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Slot',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimeSlotOption('morning', 'Morning\n(9AM-12PM)'),
                  const SizedBox(width: 8),
                  _buildTimeSlotOption('afternoon', 'Afternoon\n(1PM-5PM)'),
                  const SizedBox(width: 8),
                  _buildTimeSlotOption('evening', 'Evening\n(6PM-8PM)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotOption(String value, String label) {
    final isSelected = _selectedTimeSlot == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTimeSlot = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConstants.primaryColor.withValues(alpha: 0.1)
                : Colors.grey[100],
            border: Border.all(
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contact Information',
      child: TextFormField(
        controller: _contactNumberController,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          prefixIcon: const Icon(Icons.phone),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return _buildSection(
      title: 'Special Instructions (Optional)',
      child: TextFormField(
        controller: _specialInstructionsController,
        decoration: InputDecoration(
          labelText: 'Any special instructions for the driver?',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildCostSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Return Pickup Fee'),
              Text(
                '\$18.00',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Fee will be charged after owner approval',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _submitReturnRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Request Return Pickup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _preferredReturnDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _preferredReturnDate = picked;
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

      final reason = _selectedReason == 'Other'
          ? _returnReasonController.text
          : _selectedReason;

      final instructions =
          'Return Reason: $reason\n\n${_specialInstructionsController.text}';

      context.read<DeliveryBloc>().add(
            RequestReturnDelivery(
              originalDeliveryId: widget.originalDelivery.id,
              returnAddress: _returnAddressController.text,
              contactNumber: _contactNumberController.text,
              scheduledTime: scheduledTime,
              specialInstructions: instructions,
            ),
          );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Return Request Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          'Your return pickup request has been submitted successfully. The owner will be notified to approve your request.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Go back to tracking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
