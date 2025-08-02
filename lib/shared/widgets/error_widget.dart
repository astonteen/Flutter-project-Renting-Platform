import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final ErrorType errorType;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showContactSupport;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.errorType = ErrorType.general,
    this.actionLabel,
    this.onAction,
    this.showContactSupport = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildErrorIcon(),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getErrorColor(),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_getErrorSuggestion().isNotEmpty) ...[
              Text(
                _getErrorSuggestion(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getErrorColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getErrorIcon(),
        size: 40,
        color: _getErrorColor(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (onRetry != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              label: Text(_getRetryLabel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getErrorColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (onAction != null && actionLabel != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAction,
              icon: Icon(_getActionIcon()),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getErrorColor(),
                side: BorderSide(color: _getErrorColor()),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (showContactSupport) ...[
          TextButton.icon(
            onPressed: () => _showContactSupport(context),
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  String _getErrorTitle() {
    switch (errorType) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.auth:
        return 'Authentication Required';
      case ErrorType.payment:
        return 'Payment Issue';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.permission:
        return 'Permission Denied';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.general:
        return 'Something went wrong';
    }
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.payment:
        return Icons.payment_outlined;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.permission:
        return Icons.security_outlined;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.dns_outlined;
      case ErrorType.timeout:
        return Icons.timer_off_outlined;
      case ErrorType.general:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (errorType) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.auth:
        return Colors.red;
      case ErrorType.payment:
        return Colors.purple;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.general:
        return Colors.red;
    }
  }

  String _getErrorSuggestion() {
    switch (errorType) {
      case ErrorType.network:
        return 'Check your internet connection and try again';
      case ErrorType.auth:
        return 'Please log in to continue';
      case ErrorType.payment:
        return 'Please check your payment details';
      case ErrorType.validation:
        return 'Please check your input and try again';
      case ErrorType.permission:
        return 'This action requires additional permissions';
      case ErrorType.notFound:
        return 'The requested item could not be found';
      case ErrorType.server:
        return 'Our servers are experiencing issues. Please try again later';
      case ErrorType.timeout:
        return 'The request took too long. Please try again';
      case ErrorType.general:
        return 'Please try again or contact support if the problem persists';
    }
  }

  String _getRetryLabel() {
    switch (errorType) {
      case ErrorType.network:
        return 'Retry Connection';
      case ErrorType.auth:
        return 'Try Again';
      case ErrorType.payment:
        return 'Retry Payment';
      case ErrorType.validation:
        return 'Try Again';
      case ErrorType.permission:
        return 'Grant Permission';
      case ErrorType.notFound:
        return 'Search Again';
      case ErrorType.server:
        return 'Retry';
      case ErrorType.timeout:
        return 'Retry';
      case ErrorType.general:
        return 'Try Again';
    }
  }

  IconData _getActionIcon() {
    switch (errorType) {
      case ErrorType.network:
        return Icons.settings;
      case ErrorType.auth:
        return Icons.login;
      case ErrorType.payment:
        return Icons.credit_card;
      case ErrorType.validation:
        return Icons.edit;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.notFound:
        return Icons.home;
      case ErrorType.server:
        return Icons.info;
      case ErrorType.timeout:
        return Icons.settings;
      case ErrorType.general:
        return Icons.help;
    }
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact our support team:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('support@rentease.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('+1 (555) 123-4567'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('Live Chat (9 AM - 5 PM)'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Note: In a production app, this would send actual support email
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }
}

// Specialized Error Widgets
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      message: customMessage ?? 'Unable to connect to the internet',
      errorType: ErrorType.network,
      onRetry: onRetry,
      actionLabel: 'Check Settings',
      onAction: () => _openNetworkSettings(context),
      showContactSupport: true,
    );
  }

  void _openNetworkSettings(BuildContext context) {
    // Note: In a production app, this would open device network settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please check your network settings'),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}

class AuthErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin;
  final String? customMessage;

  const AuthErrorWidget({
    super.key,
    this.onLogin,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      message:
          customMessage ?? 'You need to be logged in to access this feature',
      errorType: ErrorType.auth,
      onRetry: onLogin,
      actionLabel: 'Go to Login',
      onAction: () => _navigateToLogin(context),
    );
  }

  void _navigateToLogin(BuildContext context) {
    // Note: Using named routes for demo - production would use GoRouter
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class PaymentErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const PaymentErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      message: customMessage ?? 'Payment could not be processed',
      errorType: ErrorType.payment,
      onRetry: onRetry,
      actionLabel: 'Update Payment',
      onAction: () => _updatePaymentMethod(context),
      showContactSupport: true,
    );
  }

  void _updatePaymentMethod(BuildContext context) {
    // Note: In a production app, this would navigate to payment settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment update feature - demo placeholder'),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}

class ValidationErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  final List<String>? validationErrors;

  const ValidationErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
    this.validationErrors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      message: customMessage ?? 'Please check your input and try again',
      errorType: ErrorType.validation,
      onRetry: onRetry,
      actionLabel: 'Fix Errors',
      onAction: () => _showValidationDetails(context),
    );
  }

  void _showValidationDetails(BuildContext context) {
    if (validationErrors == null || validationErrors!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: validationErrors!
              .map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error)),
                      ],
                    ),
                  ))
              .toList(),
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

// Error Type Enum
enum ErrorType {
  general,
  network,
  auth,
  payment,
  validation,
  permission,
  notFound,
  server,
  timeout,
}

// Error Handler Utility
class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    final errorInfo = _parseError(error);

    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorInfo.message),
          backgroundColor: _getErrorColor(errorInfo.type),
          behavior: SnackBarBehavior.fixed,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: onRetry,
                  textColor: Colors.white,
                )
              : null,
        ),
      );
    }
  }

  static ErrorInfo _parseError(dynamic error) {
    if (error is String) {
      return ErrorInfo(
        message: error,
        type: ErrorType.general,
      );
    }

    // Parse different error types
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorInfo(
        message: 'Network connection error',
        type: ErrorType.network,
      );
    }

    if (errorString.contains('auth') || errorString.contains('unauthorized')) {
      return ErrorInfo(
        message: 'Authentication required',
        type: ErrorType.auth,
      );
    }

    if (errorString.contains('payment') || errorString.contains('card')) {
      return ErrorInfo(
        message: 'Payment processing error',
        type: ErrorType.payment,
      );
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return ErrorInfo(
        message: 'Invalid input provided',
        type: ErrorType.validation,
      );
    }

    if (errorString.contains('timeout')) {
      return ErrorInfo(
        message: 'Request timeout',
        type: ErrorType.timeout,
      );
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return ErrorInfo(
        message: 'Resource not found',
        type: ErrorType.notFound,
      );
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return ErrorInfo(
        message: 'Server error occurred',
        type: ErrorType.server,
      );
    }

    return ErrorInfo(
      message: 'An unexpected error occurred',
      type: ErrorType.general,
    );
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.auth:
        return Colors.red;
      case ErrorType.payment:
        return Colors.purple;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.general:
        return Colors.red;
    }
  }
}

class ErrorInfo {
  final String message;
  final ErrorType type;

  ErrorInfo({
    required this.message,
    required this.type,
  });
}
