import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/custom_toast.dart';
import '../../config/routes/route_names.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_exceptions.dart';

class PasswordResetScreen extends StatefulWidget {
  final String email;

  const PasswordResetScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService.customProvider();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomToast.showValidationError(
          message: 'Passwords do not match.',
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _authService.resetPassword(
          email: widget.email,
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );

        if (mounted) {
          CustomToast.showSportsSuccess(
            message:
                'Password reset successful! Please login with your new password.',
          );

          // Navigate back to login screen
          context.goNamed(RouteNames.login);
        }
      } on InvalidCredentialsException {
        if (mounted) {
          CustomToast.showError(
            message: 'Invalid reset code. Please check the code and try again.',
          );
        }
      } on UserNotFoundAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'User not found. Please try again.',
          );
        }
      } on NetworkException {
        if (mounted) {
          CustomToast.showError(
            message:
                'Network error. Please check your internet connection and try again.',
          );
        }
      } on ServerException catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: 'Server error: ${e.message}',
          );
        }
      } on GenericAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'Password reset failed. Please try again.',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: 'An unexpected error occurred. Please try again.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _handleResendCode() async {
    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(toEmail: widget.email);

      if (mounted) {
        CustomToast.showInfo(
          message: 'Reset code sent again to ${widget.email}',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Failed to resend code. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Reset Password',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the reset code sent to ${widget.email} and your new password.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 40),

                      CustomTextField(
                        controller: _codeController,
                        labelText: 'Reset Code',
                        keyboardType: TextInputType.text,
                        prefixIcon: Icon(
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Reset code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'New Password',
                        isPasswordField: true,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.passwordRequiredMessage;
                          }
                          if (value.length < 6) {
                            return AppConstants.passwordLengthMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm New Password',
                        isPasswordField: true,
                        obscureText: true,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      CustomButton(
                        text: 'Reset Password',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Resend code option
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Didn't receive the code?",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _handleResendCode,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
