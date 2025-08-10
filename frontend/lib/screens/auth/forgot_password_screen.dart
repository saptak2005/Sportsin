import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/custom_toast.dart';
import '../../config/routes/route_names.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_exceptions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      // Add a small delay to ensure build cycle completes
      await Future.delayed(Duration.zero);

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        await _authService.sendPasswordResetEmail(
          toEmail: _emailController.text.trim(),
        );

        if (mounted) {
          CustomToast.showSuccess(
            message:
                'Password reset code sent to your email. Please check your inbox.',
          );

          // Navigate to password reset screen with email
          Future.microtask(() {
            if (mounted) {
              context.goNamed(
                RouteNames.passwordReset,
                queryParameters: {'email': _emailController.text.trim()},
              );
            }
          });
        }
      } on UserNotFoundAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'No account found with this email address.',
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
            message: 'Failed to send password reset email. Please try again.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                      const SizedBox(height: 100),
                      // Logo or App Icon
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/variant_1.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Forgot Password?',
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
                        'Enter your email address and we\'ll send you a code to reset your password.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Send Reset Code',
                        onPressed: _handleSendResetEmail,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.goNamed(RouteNames.login),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
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
