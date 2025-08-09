import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/custom_toast.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_exceptions.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService.customProvider();
  bool _isLoading = false;
  bool _isResending = false;
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
    _animationController.dispose();
    super.dispose();
  }

  void _handleVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.verifyEmail(
          email: widget.email,
          code: _codeController.text.trim(),
        );

        if (mounted) {
          CustomToast.showSuccess(
            message: 'Email verified successfully! Welcome to SportsIN.',
          );
          context.go('/');
        }
      } on ServerException catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: e.message,
          );
        }
      } on NetworkException {
        if (mounted) {
          CustomToast.showError(
            message:
                'Network error. Please check your internet connection and try again.',
          );
        }
      } on GenericAuthException {
        if (mounted) {
          CustomToast.showError(
            message:
                'Verification failed. Please check your code and try again.',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: 'Verification failed. Please try again.',
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
    setState(() => _isResending = true);

    try {
      await _authService.resendVerificationCode(email: widget.email);

      if (mounted) {
        CustomToast.showSuccess(
          message: 'Verification code resent to ${widget.email}',
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: e.message,
        );
      }
    } on NetworkException {
      if (mounted) {
        CustomToast.showError(
          message:
              'Network error. Please check your internet connection and try again.',
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
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 30),

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
                            Icons.mark_email_read_outlined,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Verify Your Email',
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
                        'We\'ve sent a verification code to ${widget.email}. Please enter the code below to verify your account.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _codeController,
                        labelText: 'Verification Code',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icon(
                          Icons.security_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the verification code';
                          }
                          if (value.length != 6) {
                            return 'Verification code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Verify Email',
                        onPressed: _handleVerification,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Resend Code
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Didn\'t receive the code?',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _isResending ? null : _handleResendCode,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Resend Code'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
