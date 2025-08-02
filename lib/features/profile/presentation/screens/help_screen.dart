import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I create a listing?',
      answer: 'To create a listing, tap the "+" button on the home screen, fill in the item details, add photos, set your price, and publish your listing.',
    ),
    FAQItem(
      question: 'How do I rent an item?',
      answer: 'Browse available items, select the one you want, choose your rental dates, and proceed with the booking. You can message the owner if you have questions.',
    ),
    FAQItem(
      question: 'How does payment work?',
      answer: 'Payments are processed securely through our platform. The rental fee is charged when you confirm your booking, and a security deposit may be held temporarily.',
    ),
    FAQItem(
      question: 'What if an item is damaged?',
      answer: 'Report any damage immediately through the app. We have a resolution process to handle disputes fairly between renters and lenders.',
    ),
    FAQItem(
      question: 'How do I contact the item owner?',
      answer: 'You can message the owner directly through the in-app messaging system once you\'ve made a booking inquiry.',
    ),
    FAQItem(
      question: 'Can I cancel a booking?',
      answer: 'Yes, you can cancel bookings according to the cancellation policy set by the item owner. Check the listing details for specific terms.',
    ),
    FAQItem(
      question: 'How do I update my profile?',
      answer: 'Go to your profile screen and tap "Edit Profile" to update your information, profile picture, and verification status.',
    ),
    FAQItem(
      question: 'What items can I list?',
      answer: 'You can list most items except prohibited items like weapons, illegal substances, or items that violate our terms of service.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
            // Quick Actions
            _buildSectionCard(
              title: 'Quick Actions',
              content: Column(
                children: [
                  _buildQuickActionTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Contact Support',
                    subtitle: 'Get help from our support team',
                    onTap: () => _showContactSupportDialog(),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug',
                    subtitle: 'Let us know about any issues',
                    onTap: () => _showReportBugDialog(),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    subtitle: 'Share your thoughts and suggestions',
                    onTap: () => _showFeedbackDialog(),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.phone_outlined,
                    title: 'Emergency Contact',
                    subtitle: 'For urgent safety concerns',
                    onTap: () => _showEmergencyContactDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            _buildSectionCard(
              title: 'Frequently Asked Questions',
              content: Column(
                children: _faqItems
                    .map((faq) => _buildFAQTile(faq))
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Getting Started
            _buildSectionCard(
              title: 'Getting Started',
              content: Column(
                children: [
                  _buildGuideTile(
                    icon: Icons.person_add_outlined,
                    title: 'Setting Up Your Account',
                    description: 'Complete your profile and verify your identity',
                  ),
                  _buildGuideTile(
                    icon: Icons.add_circle_outline,
                    title: 'Creating Your First Listing',
                    description: 'Learn how to list items effectively',
                  ),
                  _buildGuideTile(
                    icon: Icons.search_outlined,
                    title: 'Finding Items to Rent',
                    description: 'Tips for discovering great rental items',
                  ),
                  _buildGuideTile(
                    icon: Icons.security_outlined,
                    title: 'Safety Guidelines',
                    description: 'Best practices for safe transactions',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information
            _buildSectionCard(
              title: 'Contact Information',
              content: Column(
                children: [
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@rentease.com',
                    onTap: () => _launchEmail('support@rentease.com'),
                  ),
                  _buildContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () => _launchPhone('+15551234567'),
                  ),
                  _buildContactTile(
                    icon: Icons.schedule_outlined,
                    title: 'Support Hours',
                    subtitle: 'Mon-Fri 9AM-6PM EST',
                    onTap: null,
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

  Widget _buildQuickActionTile({
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

  Widget _buildFAQTile(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq.answer,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideTile({
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

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Choose how you\'d like to contact our support team:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchEmail('support@rentease.com');
            },
            child: const Text('Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchPhone('+15551234567');
            },
            child: const Text('Phone'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the bug you encountered:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendBugReport(controller.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We\'d love to hear your thoughts and suggestions:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendFeedback(controller.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: const Text(
          'For immediate safety concerns or emergencies, please contact local authorities (911) first.\n\nFor urgent app-related safety issues, you can reach our emergency line.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchPhone('911');
            },
            child: const Text('Call 911'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchPhone('+15551234567');
            },
            child: const Text('Emergency Line'),
          ),
        ],
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

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number copied to clipboard: $phoneNumber'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number copied to clipboard: $phoneNumber'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _sendBugReport(String description) {
    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the bug'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // In a real app, this would send the bug report to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bug report sent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendFeedback(String feedback) {
    if (feedback.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // In a real app, this would send the feedback to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback sent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
