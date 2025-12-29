import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'login_screen.dart';

// ignore: unused_import kept for navigation

class ResetPasswordScreen extends StatefulWidget {
  final String emailOrPhone;
  final String? debugToken; // For development only

  const ResetPasswordScreen({
    super.key,
    required this.emailOrPhone,
    this.debugToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isOtpVerified = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // For development: show debug token if available
    if (widget.debugToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug OTP: ${widget.debugToken}'),
            duration: const Duration(seconds: 10),
            backgroundColor: AppColors.info,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.verifyResetToken(
      widget.emailOrPhone,
      _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _isOtpVerified = true;
        _successMessage = 'Code verified! Enter your new password.';
      });
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.resetPassword(
      emailOrPhone: widget.emailOrPhone,
      token: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
      newPasswordConfirm: _confirmPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Show success and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Password reset successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translate('reset_password') ?? 'Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isOtpVerified
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isOtpVerified ? Icons.check_circle : Icons.pin,
                      size: 50,
                      color: _isOtpVerified
                          ? AppColors.success
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  _isOtpVerified
                      ? (l10n?.translate('create_new_password') ?? 'Create New Password')
                      : (l10n?.translate('enter_verification_code') ?? 'Enter Verification Code'),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  _isOtpVerified
                      ? (l10n?.translate('new_password_description') ??
                          'Enter your new password below.')
                      : (l10n?.translate('verification_code_sent') ??
                          'We sent a 6-digit code to ${widget.emailOrPhone}'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Success message
                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // OTP Input (always visible but disabled after verification)
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  enabled: !_isOtpVerified,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n?.translate('verification_code') ?? 'Verification Code',
                    prefixIcon: const Icon(Icons.pin),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.translate('field_required') ?? 'This field is required';
                    }
                    if (value.length != 6) {
                      return l10n?.translate('invalid_code') ?? 'Please enter a 6-digit code';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Verify OTP button (only if not verified)
                if (!_isOtpVerified) ...[
                  CustomButton(
                    text: l10n?.translate('verify_code') ?? 'Verify Code',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                    icon: Icons.verified,
                  ),
                ],

                // Password fields (only after OTP verified)
                if (_isOtpVerified) ...[
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _newPasswordController,
                    label: l10n?.translate('new_password') ?? 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.translate('field_required') ?? 'This field is required';
                      }
                      if (value.length < 6) {
                        return l10n?.translate('password_too_short') ??
                            'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: l10n?.translate('confirm_password') ?? 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.translate('field_required') ?? 'This field is required';
                      }
                      if (value != _newPasswordController.text) {
                        return l10n?.translate('password_mismatch') ?? 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: l10n?.translate('reset_password') ?? 'Reset Password',
                    isLoading: _isLoading,
                    onPressed: _resetPassword,
                    icon: Icons.lock_reset,
                  ),
                ],

                const SizedBox(height: 16),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n?.translate('back_to_login') ?? 'Back to Login',
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
