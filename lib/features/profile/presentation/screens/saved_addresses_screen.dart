import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';
import 'package:rent_ease/features/profile/presentation/bloc/saved_address_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavedAddressBloc(getIt<SavedAddressRepository>())
        ..add(LoadSavedAddresses()),
      child: const _SavedAddressesView(),
    );
  }
}

class _SavedAddressesView extends StatelessWidget {
  const _SavedAddressesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAddressDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<SavedAddressBloc, SavedAddressState>(
        listener: (context, state) {
          if (state is SavedAddressOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SavedAddressError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
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

          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildAddressList(context, addresses);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(context),
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

  Widget _buildEmptyState(BuildContext context) {
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
            onPressed: () => _showAddAddressDialog(context),
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(
      BuildContext context, List<SavedAddressModel> addresses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(context, address);
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, SavedAddressModel address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        address.isDefault ? Icons.home : Icons.location_on,
                        color: address.isDefault
                            ? ColorConstants.primaryColor
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.displayLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: address.isDefault
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
                            color: ColorConstants.primaryColor.withAlpha(25),
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
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuAction(context, value, address),
                  itemBuilder: (context) => [
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.home, size: 18),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
      BuildContext context, String action, SavedAddressModel address) {
    switch (action) {
      case 'default':
        context.read<SavedAddressBloc>().add(SetDefaultAddress(address.id));
        break;
      case 'edit':
        _showEditAddressDialog(context, address);
        break;
      case 'delete':
        _showDeleteConfirmation(context, address);
        break;
    }
  }

  void _showAddAddressDialog(BuildContext context) async {
    final result = await context.push('/saved-addresses/add');
    if (result == true && context.mounted) {
      context.read<SavedAddressBloc>().add(LoadSavedAddresses());
    }
  }

  void _showEditAddressDialog(
      BuildContext context, SavedAddressModel address) async {
    final result = await context.push('/saved-addresses/edit/${address.id}');
    if (result == true && context.mounted) {
      context.read<SavedAddressBloc>().add(LoadSavedAddresses());
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, SavedAddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content:
            Text('Are you sure you want to delete "${address.displayLabel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<SavedAddressBloc>()
                  .add(DeleteSavedAddress(address.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
