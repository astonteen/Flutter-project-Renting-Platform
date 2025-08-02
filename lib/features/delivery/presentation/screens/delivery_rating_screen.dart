import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/widgets/custom_text_field.dart';
import 'package:rent_ease/core/widgets/star_rating_widget.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';

class DeliveryRatingScreen extends StatefulWidget {
  final DeliveryJobModel delivery;

  const DeliveryRatingScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryRatingScreen> createState() => _DeliveryRatingScreenState();
}

class _DeliveryRatingScreenState extends State<DeliveryRatingScreen> {
  int _driverRating = 0;
  int _serviceRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  DriverProfileModel? _driverProfile;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  void _loadDriverProfile() {
    if (widget.delivery.driverId != null) {
      context
          .read<DeliveryBloc>()
          .add(LoadDriverProfile(widget.delivery.driverId!));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitRating() async {
    if (_driverRating == 0) {
      _showErrorSnackBar('Please rate the driver');
      return;
    }
    if (_serviceRating == 0) {
      _showErrorSnackBar('Please rate the delivery service');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Submit rating to backend
    context.read<DeliveryBloc>().add(
          SubmitDeliveryRating(
            deliveryId: widget.delivery.id,
            driverRating: _driverRating,
            serviceRating: _serviceRating,
            comment: _commentController.text.trim(),
          ),
        );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DriverProfileLoaded) {
          setState(() {
            _driverProfile = state.profile;
          });
        } else if (state is DeliverySuccess) {
          _showSuccessSnackBar('Thank you for your feedback!');
          context.pop();
        } else if (state is DeliveryError) {
          setState(() {
            _isSubmitting = false;
          });
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: ColorConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Rate Your Delivery',
            style: TextStyle(
              color: ColorConstants.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: ColorConstants.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: ColorConstants.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: ColorConstants.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeliveryInfo(),
              const SizedBox(height: 32),
              _buildDriverSection(),
              const SizedBox(height: 32),
              _buildServiceRating(),
              const SizedBox(height: 32),
              _buildCommentSection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstants.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: ColorConstants.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.delivery.itemName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ColorConstants.secondaryTextColor,
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
                child: _buildInfoItem(
                  'Pickup',
                  widget.delivery.pickupAddress,
                  Icons.location_on,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Delivery',
                  widget.delivery.deliveryAddress,
                  Icons.flag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: ColorConstants.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorConstants.primaryTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDriverSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
                child: _driverProfile?.userName != null
                    ? Text(
                        _driverProfile!.userName!.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 30,
                        color: ColorConstants.primaryColor,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverProfile?.userName ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_driverProfile != null)
                      StarRatingDisplay(
                        rating: _driverProfile!.averageRating,
                        reviewCount: _driverProfile!.totalDeliveries,
                        starSize: 16,
                        fontSize: 14,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InteractiveStarRating(
            title: 'How was your driver?',
            description: 'Rate punctuality, professionalism, and communication',
            currentRating: _driverRating,
            onRatingChanged: (rating) {
              setState(() {
                _driverRating = rating;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRating() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InteractiveStarRating(
        title: 'How was the delivery service?',
        description: 'Rate speed, item condition, and overall experience',
        currentRating: _serviceRating,
        onRatingChanged: (rating) {
          setState(() {
            _serviceRating = rating;
          });
        },
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Comments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us more about your experience (optional)',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstants.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _commentController,
            hintText: 'Write your feedback here...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Submit Rating',
        onPressed: _isSubmitting ? null : _submitRating,
        isLoading: _isSubmitting,
      ),
    );
  }
}
