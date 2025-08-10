import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/services/notification/fcm_service.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/custom_toast.dart';
import '../../config/routes/route_names.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_exceptions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.customProvider();
  String? _selectedUserType;
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
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          if (user.isEmailVerified) {
            await FcmService.instance.sendTokenToServer();

            if (mounted) {
              context.go('/');
            }
          } else {
            CustomToast.showInfo(
              message: 'Please verify your email to continue.',
            );
            context.goNamed(
              RouteNames.emailVerification,
              queryParameters: {'email': _emailController.text.trim()},
            );
          }
        }
      } on InvalidCredentialsException {
        if (mounted) {
          CustomToast.showError(
            message: 'Invalid email or password. Please try again.',
          );
        }
      } on EmailNotVerifiedException {
        if (mounted) {
          CustomToast.showInfo(
            message: 'Please verify your email to continue.',
          );

          if (mounted) {
            context.goNamed(
              RouteNames.emailVerification,
              queryParameters: {'email': _emailController.text.trim()},
            );
          }
        }
      } on AccountDisabledException {
        if (mounted) {
          CustomToast.showError(
            message: 'Your account has been disabled. Please contact support.',
          );
        }
      } on UserNotFoundAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'No account found with this email. Please register first.',
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
            message: 'Login failed. Please try again.',
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

  void _handleGoogleSignIn() {
    // Validate user type selection
    if (_selectedUserType == null) {
      CustomToast.showValidationError(
        message: AppConstants.userTypeRequiredMessage,
      );
      return;
    }

    // TODO: Implement Google Sign In
    setState(() => _isLoading = true);

    CustomToast.showInfo(
      message:
          'Signing in with Google as ${_selectedUserType == AppConstants.userTypePlayer ? 'Player' : 'Recruiter'}...',
    );

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomToast.showSportsSuccess(
          message: 'Welcome back to SportsIN! 🎉',
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/');
          }
        });
      }
    });
  }

  void _handleForgotPassword() async {
    context.pushNamed(RouteNames.forgotPassword);
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
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
                        'Welcome Back!',
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
                        'Please sign in to your account',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 30),

                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.emailRequiredMessage;
                          }
                          if (!value.contains('@')) {
                            return AppConstants.emailInvalidMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: _selectedUserType == AppConstants.userTypePlayer
                            ? AppConstants.loginAsPlayer
                            : _selectedUserType ==
                                    AppConstants.userTypeRecruiter
                                ? AppConstants.loginAsRecruiter
                                : AppConstants.login,
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 15),
                      // Social Login Options
                      Center(
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: Image.network(
                            'https://img.icons8.com/?size=100&id=17949&format=png&color=000000',
                            height: 24,
                          ),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.goNamed(RouteNames.register),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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
