import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/utils/validators.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:rent_ease/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';

class PaymentScreen extends StatefulWidget {
  final RentalItemModel item;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final bool needsDelivery;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String? notes;

  const PaymentScreen({
    super.key,
    required this.item,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.needsDelivery,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.notes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  int _calculateDays() {
    return widget.endDate.difference(widget.startDate).inDays + 1;
  }

  double get _itemCost =>
      widget.totalAmount - (widget.needsDelivery ? 15.0 : 0.0);
  double get _deliveryFee => widget.needsDelivery ? 15.0 : 0.0;
  double get _serviceFee => widget.totalAmount * 0.05; // 5% service fee
  double get _totalWithFees => widget.totalAmount + _serviceFee;

  void _processPayment() {
    if (_selectedPaymentMethod == 'card' && !_validateCardForm()) {
      return;
    }

    context.read<PaymentBloc>().add(
          ProcessPayment(
            itemId: widget.item.id,
            amount: _totalWithFees,
            paymentMethod: _selectedPaymentMethod,
            startDate: widget.startDate,
            endDate: widget.endDate,
            notes: widget.notes,
            needsDelivery: widget.needsDelivery,
            deliveryAddress: widget.deliveryAddress,
            deliveryInstructions: widget.deliveryInstructions,
          ),
        );
  }

  bool _validateCardForm() {
    // Use enhanced validators
    final cardError = Validators.validateCardNumber(_cardNumberController.text);
    if (cardError != null) {
      _showError(cardError);
      return false;
    }

    final expiryError = Validators.validateExpiryDate(_expiryController.text);
    if (expiryError != null) {
      _showError(expiryError);
      return false;
    }

    final cvvError = Validators.validateCVV(_cvvController.text);
    if (cvvError != null) {
      _showError(cvvError);
      return false;
    }

    final nameError = Validators.validateRequired(
        _cardHolderController.text.trim(), 'Card holder name');
    if (nameError != null) {
      _showError(nameError);
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showSuccessDialog();
          } else if (state is PaymentError) {
            _showError(state.message);
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) {
              return const LoadingWidget(message: 'Processing payment...');
            }

            if (state is PaymentProcessing) {
              return PaymentProcessingWidget(
                stage: state.stage,
                paymentMethod: state.paymentMethod,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Summary
                  _buildBookingSummary(),
                  const SizedBox(height: 24),

                  // Payment Methods
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),

                  // Payment Form
                  if (_selectedPaymentMethod == 'card') _buildCardForm(),
                  if (_selectedPaymentMethod == 'paypal') _buildPayPalInfo(),
                  if (_selectedPaymentMethod == 'apple_pay')
                    _buildApplePayInfo(),
                  const SizedBox(height: 24),

                  // Cost Breakdown
                  _buildCostBreakdown(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.item.primaryImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year} - ${widget.endDate.day}/${widget.endDate.month}/${widget.endDate.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateDays()} day${_calculateDays() > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: ColorConstants.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.needsDelivery) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: ColorConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery required - address will be collected separately',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodTile(
          'card',
          'Credit/Debit Card',
          Icons.credit_card,
          'Visa, Mastercard, American Express',
        ),
        _buildPaymentMethodTile(
          'paypal',
          'PayPal',
          Icons.account_balance_wallet,
          'Pay with your PayPal account',
        ),
        _buildPaymentMethodTile(
          'apple_pay',
          'Apple Pay',
          Icons.phone_iphone,
          'Touch ID or Face ID required',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? ColorConstants.primaryColor.withValues(alpha: 0.05)
              : ColorConstants.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorConstants.primaryColor
                  : ColorConstants.secondaryTextColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : ColorConstants.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ColorConstants.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ColorConstants.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.credit_card),
                helperText: 'Enter your 16-digit card number',
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
              validator: Validators.validateCardNumber,
              onChanged: (value) {
                // Format card number with spaces
                String formatted = value.replaceAll(' ', '');
                if (formatted.length > 16) {
                  formatted = formatted.substring(0, 16);
                }

                String display = '';
                for (int i = 0; i < formatted.length; i++) {
                  if (i > 0 && i % 4 == 0) display += ' ';
                  display += formatted[i];
                }

                if (display != value) {
                  _cardNumberController.value = TextEditingValue(
                    text: display,
                    selection: TextSelection.collapsed(offset: display.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Expiry date',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    validator: Validators.validateExpiryDate,
                    onChanged: (value) {
                      if (value.length == 2 && !value.contains('/')) {
                        _expiryController.value = TextEditingValue(
                          text: '$value/',
                          selection: const TextSelection.collapsed(offset: 3),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Security code',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    validator: Validators.validateCVV,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardHolderController,
              decoration: InputDecoration(
                labelText: 'Card Holder Name',
                hintText: 'John Doe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
                helperText: 'Name as it appears on card',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  Validators.validateRequired(value, 'Card holder name'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayPalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'PayPal Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be redirected to PayPal to complete your payment securely.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplePayInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.phone_iphone,
              size: 48,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 16),
            const Text(
              'Apple Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Touch ID or Face ID to pay with Apple Pay.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCostRow('Item rental (${_calculateDays()} days)',
                '\$${_itemCost.toStringAsFixed(2)}'),
            if (widget.needsDelivery)
              _buildCostRow(
                  'Delivery fee', '\$${_deliveryFee.toStringAsFixed(2)}'),
            _buildCostRow('Service fee', '\$${_serviceFee.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildCostRow(
              'Total Amount',
              '\$${_totalWithFees.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? ColorConstants.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${_totalWithFees.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: 'Pay Now',
              onPressed: _processPayment,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FFFA),
                  Color(0xFFFFFFFF),
                  Color(0xFFF0F9FF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.green.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header section with success animation
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Success icon with animated rings
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green[400]!,
                              Colors.green[600]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(77),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.green.withAlpha(51),
                              blurRadius: 40,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Success title
                      Text(
                        'Payment Successful!',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                  letterSpacing: -0.5,
                                ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Confirmation text
                      Text(
                        'Your booking for ${widget.item.name} has been confirmed.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Booking ID chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Booking ID: #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Booking details section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                      ),
                      const SizedBox(height: 16),
                      _buildModernSummaryRow(
                        'Rental Period',
                        '${_calculateDays()} days',
                        Icons.calendar_today_outlined,
                      ),
                      _buildModernSummaryRow(
                        'Start Date',
                        _formatDate(widget.startDate),
                        Icons.event_outlined,
                      ),
                      _buildModernSummaryRow(
                        'End Date',
                        _formatDate(widget.endDate),
                        Icons.event_available_outlined,
                      ),
                      _buildModernSummaryRow(
                        'Total Paid',
                        '\$${_totalWithFees.toStringAsFixed(2)}',
                        Icons.payments_outlined,
                        isHighlighted: true,
                      ),
                      if (widget.needsDelivery)
                        _buildModernSummaryRow(
                          'Delivery',
                          'Included',
                          Icons.local_shipping_outlined,
                          showDeliveryBadge: true,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons section
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      // Primary action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/rentals');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'View My Rentals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary action button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/home');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Continue Shopping',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSummaryRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
    bool showDeliveryBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? ColorConstants.primaryColor.withAlpha(25)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isHighlighted
                  ? ColorConstants.primaryColor
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showDeliveryBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted
                    ? ColorConstants.primaryColor
                    : Colors.grey[800],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
