import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/widgets/custom_text_field.dart';
import 'package:rent_ease/core/widgets/quantity_input_widget.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/core/services/storage_service.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _pricePerWeekController = TextEditingController();
  final _pricePerMonthController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedCondition = 'good';
  final List<String> _imageUrls = [];
  final List<File> _imageFiles = [];
  bool _isUploadingImages = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Quantity and availability settings
  int _quantity = 1;
  int _blockingDays = 1; // Default to 1 day return buffer

  // Address selection variables
  SavedAddressModel? _selectedSavedAddress;
  bool _useManualAddress = true;
  List<SavedAddressModel> _savedAddresses = [];

  List<Map<String, String>> _categories = [];
  bool _categoriesLoaded = false;

  final List<String> _conditionOptions = ['excellent', 'good', 'fair', 'poor'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSavedAddresses();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await SupabaseService.client
          .from('categories')
          .select('id, name')
          .order('name');

      setState(() {
        _categories = (response as List)
            .map((category) => {
                  'id': category['id'] as String,
                  'name': category['name'] as String,
                })
            .toList();
        _categoriesLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Fallback to hardcoded categories if database load fails
      setState(() {
        _categories = [
          {'id': 'electronics', 'name': 'Electronics'},
          {'id': 'tools', 'name': 'Tools & Equipment'},
          {'id': 'sports', 'name': 'Sports & Recreation'},
          {'id': 'vehicles', 'name': 'Vehicles'},
          {'id': 'home', 'name': 'Home & Garden'},
          {'id': 'other', 'name': 'Other'},
        ];
        _categoriesLoaded = true;
      });
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final repository = SavedAddressRepository();
      final addresses = await repository.getUserSavedAddresses();
      setState(() {
        _savedAddresses = addresses;
      });
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('List an Item'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocListener<ListingBloc, ListingState>(
        listener: (context, state) {
          if (state is ListingCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listing created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          } else if (state is ListingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ListingBloc, ListingState>(
          builder: (context, state) {
            if (state is ListingLoading) {
              return const LoadingWidget();
            }

            return Form(
              key: _formKey,
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadSavedAddresses();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotosSection(),
                      const SizedBox(height: 24),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildCategorySection(),
                      const SizedBox(height: 24),
                      _buildConditionSection(),
                      const SizedBox(height: 24),
                      _buildQuantitySection(),
                      const SizedBox(height: 24),
                      _buildBlockingDaysSection(),
                      const SizedBox(height: 24),
                      _buildPricingSection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == _imageUrls.length) {
                return _buildAddPhotoCard();
              }
              return _buildPhotoCard(_imageUrls[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoCard() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: _addPhoto,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text('Add Photo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String imageUrl, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: _imageFiles.length > index
                    ? FileImage(_imageFiles[index])
                    : NetworkImage(imageUrl) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          labelText: 'Item Name',
          hintText: 'Enter the name of your item',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter an item name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          validator: (value) {
            if (value?.isEmpty == true) return 'Please enter a description';
            if (value!.length < 20) {
              return 'Description should be at least 20 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your item in detail',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ColorConstants.primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (!_categoriesLoaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategoryId == category['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategoryId = category['id']),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstants.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    category['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Condition',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: _conditionOptions.map((condition) {
            final isSelected = _selectedCondition == condition;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCondition = condition),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstants.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    condition.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inventory & Availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        QuantityInputWidget(
          initialValue: _quantity,
          label: 'Available Units',
          helperText: 'How many identical units do you have for rent?',
          onChanged: (value) {
            setState(() {
              _quantity = value;
            });
          },
        ),
        const SizedBox(height: 16),
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
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Maintenance Period',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'After each rental, $_blockingDays days will be automatically blocked for item review and maintenance.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockingDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Return Buffer Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.purple[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Automatic Return Buffer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Set how many days after rental completion your item should remain blocked for return processing.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Buffer Period:'),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _blockingDays > 0
                              ? () => setState(() => _blockingDays--)
                              : null,
                          icon: const Icon(Icons.remove),
                          iconSize: 20,
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Text(
                            '$_blockingDays',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _blockingDays < 30
                              ? () => setState(() => _blockingDays++)
                              : null,
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _blockingDays == 1 ? 'day' : 'days',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.purple[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _blockingDays == 0
                            ? 'No return buffer - item becomes available immediately after rental ends'
                            : 'After rental completion, your item will be blocked for $_blockingDays ${_blockingDays == 1 ? 'day' : 'days'} for return processing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pricing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pricePerDayController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
                onChanged: _calculateWeeklyMonthlyPrices,
                decoration: InputDecoration(
                  labelText: 'Price per Day',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: ColorConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _pricePerWeekController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Price per Week',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: ColorConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pricePerMonthController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Price per Month',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: ColorConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _securityDepositController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid amount';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Security Deposit',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: ColorConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Address selection options
        Row(
          children: [
            Expanded(
              child: _buildAddressOption(
                'Manual Entry',
                Icons.edit_location,
                _useManualAddress,
                () => setState(() {
                  _useManualAddress = true;
                  _selectedSavedAddress = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddressOption(
                'Saved Address',
                Icons.bookmark_border,
                !_useManualAddress,
                () => setState(() {
                  _useManualAddress = false;
                  _locationController.clear();
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Address input based on selection
        if (_useManualAddress) ...[
          CustomTextField(
            controller: _locationController,
            labelText: 'Enter Address',
            hintText: 'Street address, city, state',
            maxLines: 2,
            validator: (value) => value?.isEmpty == true
                ? 'Please enter a pickup location'
                : null,
          ),
        ] else ...[
          _buildSavedAddressSelector(),
        ],
      ],
    );
  }

  Widget _buildAddressOption(
      String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? ColorConstants.primaryColor.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? ColorConstants.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressSelector() {
    if (_savedAddresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'No saved addresses found',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigate to add address screen
                context.push('/saved-addresses');
              },
              child: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SavedAddressModel?>(
              isExpanded: true,
              value: _selectedSavedAddress,
              hint: const Text('Select a saved address'),
              items: [
                const DropdownMenuItem<SavedAddressModel?>(
                  value: null,
                  child: Text('Select an address'),
                ),
                ..._savedAddresses.map((address) =>
                    DropdownMenuItem<SavedAddressModel?>(
                      value: address,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            address.shortAddress,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )),
              ],
              onChanged: (SavedAddressModel? address) {
                setState(() {
                  _selectedSavedAddress = address;
                });
              },
            ),
          ),
        ),
        if (_selectedSavedAddress != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedSavedAddress!.formattedAddress,
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                context.push('/saved-addresses');
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New Address'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: _isUploadingImages ? 'Uploading Images...' : 'Create Listing',
      onPressed: _isUploadingImages ? null : _submitListing,
      isFullWidth: true,
      isLoading: _isUploadingImages,
    );
  }

  void _addPhoto() async {
    if (_imageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to choose camera or gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Validate file
        if (!StorageService.isValidImageFile(imageFile)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please select a valid image file (JPG, PNG, WebP)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Check file size
        if (!await StorageService.isFileSizeValid(imageFile)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _imageFiles.add(imageFile);
          _imageUrls.add(''); // Placeholder until uploaded
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Photo added! It will be uploaded when you create the listing.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _imageUrls.removeAt(index);
      if (_imageFiles.length > index) {
        _imageFiles.removeAt(index);
      }
    });
  }

  void _calculateWeeklyMonthlyPrices(String dailyPrice) {
    final daily = double.tryParse(dailyPrice);
    if (daily != null) {
      _pricePerWeekController.text = (daily * 6.5).toStringAsFixed(2);
      _pricePerMonthController.text = (daily * 25).toStringAsFixed(2);
    }
  }

  void _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate location selection
    if (!_useManualAddress && _selectedSavedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select a saved address or switch to manual entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one photo'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Upload images first
    setState(() {
      _isUploadingImages = true;
    });

    try {
      final List<String> uploadedImageUrls = [];

      // Generate a temporary listing ID for organizing images
      final tempListingId = DateTime.now().millisecondsSinceEpoch.toString();

      for (int i = 0; i < _imageFiles.length; i++) {
        final imageFile = _imageFiles[i];
        final fileName =
            'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final uploadedUrl = await StorageService.uploadListingImage(
          imageFile: imageFile,
          listingId: tempListingId,
          fileName: fileName,
        );

        if (uploadedUrl != null) {
          uploadedImageUrls.add(uploadedUrl);
          debugPrint('Successfully uploaded image ${i + 1}: $uploadedUrl');
        } else {
          throw Exception(
              'Failed to upload image ${i + 1} - check storage permissions and bucket access');
        }
      }

      setState(() {
        _isUploadingImages = false;
      });

      // Determine the location to use
      String location;
      if (_useManualAddress) {
        location = _locationController.text.trim();
      } else {
        if (_selectedSavedAddress != null) {
          location = _selectedSavedAddress!.formattedAddress;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please select a saved address or switch to manual entry'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Create listing with uploaded image URLs
      final event = CreateListing(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        pricePerDay: double.parse(_pricePerDayController.text),
        pricePerWeek: double.parse(_pricePerWeekController.text),
        pricePerMonth: double.parse(_pricePerMonthController.text),
        securityDeposit: double.parse(_securityDepositController.text),
        imageUrls: uploadedImageUrls,
        condition: _selectedCondition,
        location: location,
        features: const [],
        quantity: _quantity,
        blockingDays: _blockingDays,
        blockingReason: 'Review and maintenance',
      );

      context.read<ListingBloc>().add(event);
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });

      debugPrint('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _pricePerWeekController.dispose();
    _pricePerMonthController.dispose();
    _securityDepositController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
