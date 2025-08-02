import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  final List<RoleOption> _roleOptions = [
    RoleOption(
      id: 'renter',
      title: 'Renter',
      description: 'I want to rent items from others',
      icon: Icons.shopping_bag,
    ),
    RoleOption(
      id: 'owner',
      title: 'Owner',
      description: 'I want to list my items for rent',
      icon: Icons.monetization_on,
    ),
    RoleOption(
      id: 'driver',
      title: 'Delivery Partner',
      description: 'I want to deliver items and earn',
      icon: Icons.delivery_dining,
    ),
  ];

  void _selectRole(String roleId) {
    setState(() {
      _selectedRole = roleId;
    });
  }

  Future<void> _continueToNextScreen() async {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Navigate to profile setup
      context.go('/profile-setup?role=$_selectedRole');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Choose Your Role'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description text
              Text(
                'How would you like to use RentEase?',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: ColorConstants.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'You can change or add roles later',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Role options
              Expanded(
                child: ListView.builder(
                  itemCount: _roleOptions.length,
                  itemBuilder: (context, index) {
                    final role = _roleOptions[index];
                    final isSelected = role.id == _selectedRole;

                    return RoleCard(
                      role: role,
                      isSelected: isSelected,
                      onTap: () => _selectRole(role.id),
                    );
                  },
                ),
              ),

              // Continue button
              CustomButton(
                text: 'Continue',
                onPressed: _selectedRole != null
                    ? () => _continueToNextScreen()
                    : () {},
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  RoleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class RoleCard extends StatelessWidget {
  final RoleOption role;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? ColorConstants.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConstants.primaryColor
                      : ColorConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role.icon,
                  size: 30,
                  color:
                      isSelected ? Colors.white : ColorConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColorConstants.grey,
                          ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
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
}
