import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _locationServices = true;
  String _language = 'English';
  String _currency = 'USD';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _locationServices = prefs.getBool('location_services') ?? true;
        _language = prefs.getString('language') ?? 'English';
        _currency = prefs.getString('currency') ?? 'USD';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: NavigationHelper.createHamburgerMenuBackButton(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Preferences
                  const Text(
                    'App Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingTile(
                    title: 'Dark Mode',
                    subtitle: 'Switch to dark theme',
                    icon: Icons.dark_mode_outlined,
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        _saveSetting('dark_mode', value);
                      },
                      activeColor: ColorConstants.primaryColor,
                    ),
                  ),

                  _buildSettingTile(
                    title: 'Language',
                    subtitle: _language,
                    icon: Icons.language_outlined,
                    onTap: () => _showLanguageDialog(),
                  ),

                  _buildSettingTile(
                    title: 'Currency',
                    subtitle: _currency,
                    icon: Icons.attach_money_outlined,
                    onTap: () => _showCurrencyDialog(),
                  ),

                  const SizedBox(height: 32),

                  // Notifications
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications',
                    icon: Icons.notifications_outlined,
                    trailing: Switch(
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                        _saveSetting('push_notifications', value);
                      },
                      activeColor: ColorConstants.primaryColor,
                    ),
                  ),

                  _buildSettingTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive email updates',
                    icon: Icons.email_outlined,
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                        _saveSetting('email_notifications', value);
                      },
                      activeColor: ColorConstants.primaryColor,
                    ),
                  ),

                  _buildSettingTile(
                    title: 'Notification Settings',
                    subtitle: 'Manage detailed notification preferences',
                    icon: Icons.tune_outlined,
                    onTap: () => context.push('/notification-settings'),
                  ),

                  const SizedBox(height: 32),

                  // Privacy & Security
                  const Text(
                    'Privacy & Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingTile(
                    title: 'Location Services',
                    subtitle: 'Allow location access for better experience',
                    icon: Icons.location_on_outlined,
                    trailing: Switch(
                      value: _locationServices,
                      onChanged: (value) {
                        setState(() {
                          _locationServices = value;
                        });
                        _saveSetting('location_services', value);
                      },
                      activeColor: ColorConstants.primaryColor,
                    ),
                  ),

                  _buildSettingTile(
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => _showPrivacyPolicy(),
                  ),

                  _buildSettingTile(
                    title: 'Terms of Service',
                    subtitle: 'Read our terms of service',
                    icon: Icons.description_outlined,
                    onTap: () => _showTermsOfService(),
                  ),

                  const SizedBox(height: 32),

                  // Support
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingTile(
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    icon: Icons.help_outline,
                    onTap: () => context.push('/help'),
                  ),

                  _buildSettingTile(
                    title: 'About',
                    subtitle: 'App version and information',
                    icon: Icons.info_outline,
                    onTap: () => context.push('/about'),
                  ),

                  const SizedBox(height: 32),

                  // Account Actions
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingTile(
                    title: 'Clear Cache',
                    subtitle: 'Clear app cache and temporary files',
                    icon: Icons.cleaning_services_outlined,
                    onTap: () => _clearCache(),
                  ),

                  _buildSettingTile(
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout_outlined,
                    onTap: () => _showSignOutDialog(),
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ColorConstants.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  )
                : null),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('French'),
            _buildLanguageOption('German'),
            _buildLanguageOption('Chinese'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _language == language
          ? const Icon(Icons.check, color: ColorConstants.primaryColor)
          : null,
      onTap: () {
        setState(() {
          _language = language;
        });
        _saveSetting('language', language);
        Navigator.of(context).pop();
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('USD', 'US Dollar'),
            _buildCurrencyOption('EUR', 'Euro'),
            _buildCurrencyOption('GBP', 'British Pound'),
            _buildCurrencyOption('CAD', 'Canadian Dollar'),
            _buildCurrencyOption('AUD', 'Australian Dollar'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    return ListTile(
      title: Text('$code - $name'),
      trailing: _currency == code
          ? const Icon(Icons.check, color: ColorConstants.primaryColor)
          : null,
      onTap: () {
        setState(() {
          _currency = code;
        });
        _saveSetting('currency', code);
        Navigator.of(context).pop();
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the privacy policy. In a real app, this would contain the full privacy policy text or navigate to a web view.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the terms of service. In a real app, this would contain the full terms of service text or navigate to a web view.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Clearing cache...'),
          ],
        ),
      ),
    );

    // Simulate cache clearing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen
              context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
