import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'About',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Info
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 60,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RentEase',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version ($_buildNumber)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Section
            _buildSectionCard(
              title: 'About RentEase',
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RentEase is a peer-to-peer rental platform that makes it easy to rent and lend items in your community. Whether you need tools for a weekend project or want to earn money from items you rarely use, RentEase connects you with your neighbors.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'To create a sustainable sharing economy where everyone can access what they need while reducing waste and building stronger communities.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Features Section
            _buildSectionCard(
              title: 'Key Features',
              content: Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.search,
                    title: 'Easy Discovery',
                    description:
                        'Find items near you with smart search and filters',
                  ),
                  _buildFeatureItem(
                    icon: Icons.security,
                    title: 'Secure Payments',
                    description: 'Safe and secure payment processing',
                  ),
                  _buildFeatureItem(
                    icon: Icons.chat,
                    title: 'In-App Messaging',
                    description:
                        'Communicate directly with renters and lenders',
                  ),
                  _buildFeatureItem(
                    icon: Icons.local_shipping,
                    title: 'Delivery Options',
                    description: 'Convenient pickup and delivery services',
                  ),
                  _buildFeatureItem(
                    icon: Icons.star,
                    title: 'Reviews & Ratings',
                    description: 'Build trust through community feedback',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact Section
            _buildSectionCard(
              title: 'Contact & Support',
              content: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@rentease.com',
                    onTap: () => _launchEmail('support@rentease.com'),
                  ),
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Website',
                    subtitle: 'www.rentease.com',
                    onTap: () => _launchUrl('https://www.rentease.com'),
                  ),
                  _buildContactItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    onTap: () => _showPrivacyPolicy(),
                  ),
                  _buildContactItem(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'View our terms of service',
                    onTap: () => _showTermsOfService(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legal Section
            _buildSectionCard(
              title: 'Legal Information',
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '© 2024 RentEase. All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'RentEase is a trademark of RentEase Inc. This app is designed to facilitate peer-to-peer rentals and is not responsible for the condition or availability of listed items.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Made with Love
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Made with ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red[400],
                  ),
                  const Text(
                    ' for the community',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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

  Widget _buildSectionCard({
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=RentEase Support',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: copy email to clipboard
        await Clipboard.setData(ClipboardData(text: email));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email address copied to clipboard: $email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: copy email to clipboard
      await Clipboard.setData(ClipboardData(text: email));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email address copied to clipboard: $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy URL to clipboard
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URL copied to clipboard: $url'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL copied to clipboard: $url'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'RentEase Privacy Policy\n\n'
            'Last updated: December 2024\n\n'
            '1. Information We Collect\n'
            'We collect information you provide directly to us, such as when you create an account, list an item, or contact us for support.\n\n'
            '2. How We Use Your Information\n'
            'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.\n\n'
            '3. Information Sharing\n'
            'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.\n\n'
            '4. Data Security\n'
            'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.\n\n'
            'For the complete privacy policy, please visit our website.',
            style: TextStyle(height: 1.5),
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
            'RentEase Terms of Service\n\n'
            'Last updated: December 2024\n\n'
            '1. Acceptance of Terms\n'
            'By using RentEase, you agree to be bound by these Terms of Service.\n\n'
            '2. Description of Service\n'
            'RentEase is a platform that connects people who want to rent items with people who want to lend items.\n\n'
            '3. User Responsibilities\n'
            'You are responsible for your use of the service and for any content you provide, including compliance with applicable laws.\n\n'
            '4. Prohibited Uses\n'
            'You may not use our service for any illegal or unauthorized purpose.\n\n'
            '5. Limitation of Liability\n'
            'RentEase shall not be liable for any indirect, incidental, special, consequential, or punitive damages.\n\n'
            'For the complete terms of service, please visit our website.',
            style: TextStyle(height: 1.5),
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
}
