import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';
import 'package:rent_ease/features/profile/presentation/bloc/saved_address_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

class AddressSelectionScreen extends StatelessWidget {
  final SavedAddressModel? selectedAddress;
  final Function(SavedAddressModel?) onAddressSelected;

  const AddressSelectionScreen({
    super.key,
    this.selectedAddress,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SavedAddressBloc(SavedAddressRepository())..add(LoadSavedAddresses()),
      child: _AddressSelectionView(
        selectedAddress: selectedAddress,
        onAddressSelected: onAddressSelected,
      ),
    );
  }
}

class _AddressSelectionView extends StatefulWidget {
  final SavedAddressModel? selectedAddress;
  final Function(SavedAddressModel?) onAddressSelected;

  const _AddressSelectionView({
    this.selectedAddress,
    required this.onAddressSelected,
  });

  @override
  State<_AddressSelectionView> createState() => _AddressSelectionViewState();
}

class _AddressSelectionViewState extends State<_AddressSelectionView> {
  SavedAddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              widget.onAddressSelected(_selectedAddress);
              context.pop();
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<SavedAddressBloc, SavedAddressState>(
        listener: (context, state) {
          if (state is SavedAddressOperationSuccess) {
            // Reload addresses after any operation
            context.read<SavedAddressBloc>().add(LoadSavedAddresses());
          }
        },
        builder: (context, state) {
          if (state is SavedAddressLoading) {
            return const LoadingWidget();
          }

          if (state is SavedAddressError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () =>
                  context.read<SavedAddressBloc>().add(LoadSavedAddresses()),
            );
          }

          final addresses = _getAddresses(state);

          return Column(
            children: [
              // Manual address option
              _buildManualAddressOption(),

              if (addresses.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saved Addresses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildAddressList(addresses),
                ),
              ] else ...[
                Expanded(
                  child: _buildEmptyState(),
                ),
              ]
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(),
        backgroundColor: ColorConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<SavedAddressModel> _getAddresses(SavedAddressState state) {
    if (state is SavedAddressLoaded) {
      return state.addresses;
    } else if (state is SavedAddressOperationSuccess) {
      return state.addresses;
    }
    return [];
  }

  Widget _buildManualAddressOption() {
    final isSelected = _selectedAddress == null;

    return Container(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? ColorConstants.primaryColor.withAlpha(13)
                : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_location,
                color:
                    isSelected ? ColorConstants.primaryColor : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter address manually',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ColorConstants.primaryColor
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type your delivery address',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
      ),
    );
  }

  Widget _buildAddressList(List<SavedAddressModel> addresses) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(SavedAddressModel address) {
    final isSelected = _selectedAddress?.id == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? ColorConstants.primaryColor.withAlpha(13)
                : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                address.isDefault ? Icons.home : Icons.location_on,
                color: isSelected
                    ? ColorConstants.primaryColor
                    : (address.isDefault
                        ? ColorConstants.primaryColor
                        : Colors.grey[600]),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.displayLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? ColorConstants.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  ColorConstants.primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: ColorConstants.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: ColorConstants.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first address to make\nbooking deliveries easier',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Address',
            onPressed: () => _navigateToAddAddress(),
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _navigateToAddAddress() async {
    final result = await context.push('/saved-addresses/add');
    if (result != null && mounted) {
      // Reload addresses after adding new one
      context.read<SavedAddressBloc>().add(LoadSavedAddresses());
    }
  }
}
