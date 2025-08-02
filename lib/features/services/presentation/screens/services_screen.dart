import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _whereController = TextEditingController();
  final TextEditingController _whenController = TextEditingController();
  final TextEditingController _whatController = TextEditingController();

  DateTime? _selectedDate;
  bool _isFlexible = false;
  List<String> _selectedServices = [];

  final List<ServiceCategory> _serviceCategories = [
    ServiceCategory(
      name: 'Photography',
      icon: Icons.camera_alt_outlined,
    ),
    ServiceCategory(
      name: 'Chefs',
      icon: Icons.restaurant_outlined,
    ),
    ServiceCategory(
      name: 'Prepared meals',
      icon: Icons.fastfood_outlined,
    ),
    ServiceCategory(
      name: 'Massage',
      icon: Icons.spa_outlined,
    ),
    ServiceCategory(
      name: 'Training',
      icon: Icons.fitness_center_outlined,
    ),
    ServiceCategory(
      name: 'Make-up',
      icon: Icons.face_outlined,
    ),
    ServiceCategory(
      name: 'Hair',
      icon: Icons.content_cut_outlined,
    ),
    ServiceCategory(
      name: 'Spa treatments',
      icon: Icons.hot_tub_outlined,
    ),
    ServiceCategory(
      name: 'Catering',
      icon: Icons.dinner_dining_outlined,
    ),
    ServiceCategory(
      name: 'Nails',
      icon: Icons.back_hand_outlined,
    ),
  ];

  final List<DateOption> _dateOptions = [
    DateOption(label: 'Today', date: DateTime.now()),
    DateOption(
        label: 'Tomorrow', date: DateTime.now().add(const Duration(days: 1))),
    DateOption(
        label: 'This weekend',
        date: DateTime.now().add(Duration(
            days: DateTime.now().weekday == 6
                ? 0
                : DateTime.now().weekday == 7
                    ? 6
                    : 6 - DateTime.now().weekday))),
    DateOption(label: 'Choose dates', date: null),
  ];

  @override
  void dispose() {
    _whereController.dispose();
    _whenController.dispose();
    _whatController.dispose();
    super.dispose();
  }

  void _toggleService(String serviceName) {
    setState(() {
      if (_selectedServices.contains(serviceName)) {
        _selectedServices.remove(serviceName);
      } else {
        _selectedServices.add(serviceName);
      }

      // Update the what controller text
      if (_selectedServices.isEmpty) {
        _whatController.text = '';
      } else if (_selectedServices.length == 1) {
        _whatController.text = _selectedServices.first;
      } else {
        _whatController.text = '${_selectedServices.length} services';
      }
    });
  }

  void _selectDateOption(DateOption option) {
    setState(() {
      if (option.date != null) {
        _selectedDate = option.date;
        _whenController.text = option.label;
      } else {
        // Handle custom date selection
        _showDatePicker();
      }
    });
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _whenController.text =
            '${picked.day} ${_getMonthAbbreviation(picked.month)}';
      });
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
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
    return months[month - 1];
  }

  void _clearAll() {
    setState(() {
      _whereController.clear();
      _whenController.clear();
      _whatController.clear();
      _selectedDate = null;
      _isFlexible = false;
      _selectedServices = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(
                        controller: _whereController,
                        label: 'Where',
                        hint: '',
                        onTap: () {
                          _showLocationSearch();
                        },
                        suffix: _isFlexible ? _buildFlexibleChip() : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSearchField(
                        controller: _whenController,
                        label: 'When',
                        hint: '',
                        onTap: () {
                          _showDateSelection();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSearchField(
                        controller: _whatController,
                        label: 'What',
                        hint: '',
                        onTap: () {
                          _showServiceTypeSelection();
                        },
                        suffix: _selectedServices.isNotEmpty
                            ? TextButton(
                                onPressed: () {
                                  _showServiceTypeSelection();
                                },
                                child: const Text('Add service'),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear all'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Implement search functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    Widget? suffix,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (suffix != null) suffix,
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        "I'm flexible",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Where?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search destinations',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.near_me, color: Colors.blue),
                ),
                title: const Text('Nearby'),
                subtitle: const Text("Find what's around you"),
                onTap: () {
                  _whereController.text = 'Nearby';
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isFlexible,
                      onChanged: (value) {
                        setState(() {
                          _isFlexible = value ?? false;
                          Navigator.pop(context);
                        });
                      },
                    ),
                    const Text("I'm flexible"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'When?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: _dateOptions.map((option) {
                    final bool isSelected = _selectedDate != null &&
                        option.date != null &&
                        _selectedDate!.day == option.date!.day &&
                        _selectedDate!.month == option.date!.month &&
                        _selectedDate!.year == option.date!.year;

                    return GestureDetector(
                      onTap: () {
                        _selectDateOption(option);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? ColorConstants.primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (option.date != null)
                              Text(
                                '${option.date!.day} ${_getMonthAbbreviation(option.date!.month)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceTypeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Type of service',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _serviceCategories.length,
                    itemBuilder: (context, index) {
                      final category = _serviceCategories[index];
                      final bool isSelected =
                          _selectedServices.contains(category.name);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _toggleService(category.name);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? ColorConstants.primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.icon,
                                color: isSelected
                                    ? ColorConstants.primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? ColorConstants.primaryColor
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply'),
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

class ServiceCategory {
  final String name;
  final IconData icon;

  ServiceCategory({
    required this.name,
    required this.icon,
  });
}

class DateOption {
  final String label;
  final DateTime? date;

  DateOption({
    required this.label,
    required this.date,
  });
}
